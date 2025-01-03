import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/kost_model.dart';

class BookingController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize listeners for current user's bookings
  void initializeUserBookings(String userId) {
    _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  // Create a new booking
  Future<bool> createBooking(Booking booking) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Start a batch operation
      final batch = _firestore.batch();

      // Check if room is available for the selected dates
      final isAvailable = await _checkRoomAvailability(
        booking.kostId,
        booking.roomId,
        booking.startDate,
        booking.endDate,
      );

      if (!isAvailable) {
        _error = 'Room is not available for selected dates';
        throw Exception(_error);
      }

      // Create booking document reference
      final bookingRef = _firestore.collection('bookings').doc();
      batch.set(bookingRef, booking.toMap());

      // Get kost document and update room status
      final kostDoc = await _firestore.collection('kosts').doc(booking.kostId).get();
      if (!kostDoc.exists) {
        throw Exception('Kost not found');
      }

      final kostData = kostDoc.data() as Map<String, dynamic>;
      final floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Find the floor containing the room
      String? targetFloorKey;
      int? roomIndex;
      
      for (var entry in floors.entries) {
        final rooms = List<Map<String, dynamic>>.from(entry.value['rooms'] ?? []);
        final index = rooms.indexWhere((room) => room['id'] == booking.roomId);
        if (index != -1) {
          targetFloorKey = entry.key;
          roomIndex = index;
          break;
        }
      }
      
      if (targetFloorKey == null || roomIndex == null) {
        throw Exception('Room not found');
      }
      
      // Update room status in the floor
      final rooms = List<Map<String, dynamic>>.from(floors[targetFloorKey]['rooms'] ?? []);
      rooms[roomIndex]['status'] = 'booked';
      floors[targetFloorKey]['rooms'] = rooms;

      // Add kost update to batch
      batch.update(_firestore.collection('kosts').doc(booking.kostId), {
        'floors': floors,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch operation
      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If booking is cancelled, update room status back to available
      if (status == 'cancelled') {
        final booking = _bookings.firstWhere((b) => b.id == bookingId);
        await _updateRoomStatus(booking.kostId, booking.roomId, 'available');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update payment details
  Future<bool> updatePaymentDetails(String bookingId, Map<String, dynamic> paymentDetails) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentDetails': paymentDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check room availability
  Future<bool> _checkRoomAvailability(
    String kostId,
    String roomId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get the room's current status first
      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      if (!kostDoc.exists) {
        throw Exception('Kost not found');
      }

      final kostData = kostDoc.data() as Map<String, dynamic>;
      final floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Find the room in floors
      String? roomStatus;
      for (var entry in floors.entries) {
        final rooms = List<Map<String, dynamic>>.from(entry.value['rooms'] ?? []);
        final room = rooms.firstWhere(
          (room) => room['id'] == roomId,
          orElse: () => <String, dynamic>{},
        );
        if (room.isNotEmpty) {
          roomStatus = room['status'] as String?;
          break;
        }
      }

      if (roomStatus == null) {
        throw Exception('Room not found');
      }

      if (roomStatus != 'available') {
        return false;
      }

      // Check if there are any overlapping bookings
      final overlappingBookings = await _firestore
          .collection('bookings')
          .where('kostId', isEqualTo: kostId)
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      for (var doc in overlappingBookings.docs) {
        final booking = Booking.fromFirestore(doc);
        
        // Check for date overlap
        if (startDate.isBefore(booking.endDate) && 
            endDate.isAfter(booking.startDate)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  // Update room status
  Future<void> _updateRoomStatus(String kostId, String roomId, String status) async {
    try {
      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      if (!kostDoc.exists) {
        throw Exception('Kost not found');
      }

      final kostData = kostDoc.data() as Map<String, dynamic>;
      final floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Find the floor containing the room
      String? targetFloorKey;
      int? roomIndex;
      
      for (var entry in floors.entries) {
        final rooms = List<Map<String, dynamic>>.from(entry.value['rooms'] ?? []);
        final index = rooms.indexWhere((room) => room['id'] == roomId);
        if (index != -1) {
          targetFloorKey = entry.key;
          roomIndex = index;
          break;
        }
      }
      
      if (targetFloorKey == null || roomIndex == null) {
        throw Exception('Room not found');
      }
      
      // Update room status in the floor
      final rooms = List<Map<String, dynamic>>.from(floors[targetFloorKey]['rooms'] ?? []);
      rooms[roomIndex]['status'] = status;
      floors[targetFloorKey]['rooms'] = rooms;
      
      // Update kost document
      await _firestore.collection('kosts').doc(kostId).update({
        'floors': floors,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = e.toString();
      print('Error updating room status: $e');
      rethrow; // Rethrow to handle in createBooking
    }
  }

  // Get user's booking history
  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Get kost's bookings
  Stream<List<Booking>> getKostBookings(String kostId) {
    return _firestore
        .collection('bookings')
        .where('kostId', isEqualTo: kostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Get room's booking schedule
  Stream<List<Booking>> getRoomBookings(String kostId, String roomId) {
    return _firestore
        .collection('bookings')
        .where('kostId', isEqualTo: kostId)
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }
} 