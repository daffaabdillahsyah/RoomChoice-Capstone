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

      // Check if room is available for the selected dates
      final isAvailable = await _checkRoomAvailability(
        booking.kostId,
        booking.roomId,
        booking.startDate,
        booking.endDate,
      );

      if (!isAvailable) {
        throw Exception('Room is not available for selected dates');
      }

      // Create booking document
      await _firestore.collection('bookings').add(booking.toMap());

      // Update room status
      await _updateRoomStatus(booking.kostId, booking.roomId, 'booked');

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

      // Check if room is marked as occupied
      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kost = Kost.fromFirestore(kostDoc);
      final room = kost.rooms.firstWhere((r) => r.id == roomId);
      
      return room.status == 'available';
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Update room status
  Future<void> _updateRoomStatus(String kostId, String roomId, String status) async {
    final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
    final kostData = kostDoc.data() as Map<String, dynamic>;
    final rooms = List<Map<String, dynamic>>.from(kostData['rooms'] ?? []);
    
    final roomIndex = rooms.indexWhere((room) => room['id'] == roomId);
    if (roomIndex != -1) {
      rooms[roomIndex]['status'] = status;
      
      await _firestore.collection('kosts').doc(kostId).update({
        'rooms': rooms,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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