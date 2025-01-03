import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/kost_model.dart';
import 'dart:convert';

class KostController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<Kost> _kosts = [];
  bool _isLoading = false;
  String? _error;

  List<Kost> get kosts => _kosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize listeners
  KostController() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _firestore.collection('kosts').snapshots().listen((snapshot) {
      _kosts = snapshot.docs.map((doc) => Kost.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  // CRUD Operations
  Future<bool> createKost(Kost kost, File floorPlanFile, List<File> imageFiles) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Upload floor plan
      final floorPlanRef = _storage.ref('floor_plans/${DateTime.now().millisecondsSinceEpoch}');
      await floorPlanRef.putFile(floorPlanFile);
      final floorPlanUrl = await floorPlanRef.getDownloadURL();

      // Upload images
      List<String> imageUrls = [];
      for (var imageFile in imageFiles) {
        final imageRef = _storage.ref('kost_images/${DateTime.now().millisecondsSinceEpoch}');
        await imageRef.putFile(imageFile);
        final imageUrl = await imageRef.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Create kost document
      final kostData = kost.toMap();
      kostData['floorPlanImage'] = floorPlanUrl;
      kostData['images'] = imageUrls;

      await _firestore.collection('kosts').add(kostData);

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

  Future<bool> updateKost(String kostId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if document exists first
      final docSnapshot = await _firestore.collection('kosts').doc(kostId).get();
      if (!docSnapshot.exists) {
        throw Exception('Kost document not found');
      }

      await _firestore.collection('kosts').doc(kostId).update(updates);

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

  Future<bool> deleteKost(String kostId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get kost data
      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kostData = kostDoc.data();

      // Delete images from storage
      if (kostData != null) {
        final List<String> images = List<String>.from(kostData['images'] ?? []);
        for (var imageUrl in images) {
          await _storage.refFromURL(imageUrl).delete();
        }
        
        // Delete floor plan
        if (kostData['floorPlanImage'] != null) {
          await _storage.refFromURL(kostData['floorPlanImage']).delete();
        }
      }

      // Delete kost document
      await _firestore.collection('kosts').doc(kostId).delete();

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

  // Room Management
  Future<bool> addRoom(String kostId, Room room) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kostData = kostDoc.data() as Map<String, dynamic>;
      
      // Get floors data
      Map<String, dynamic> floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Get or create floor
      final floorKey = room.floor.toString();
      if (!floors.containsKey(floorKey)) {
        throw Exception('Floor ${room.floor} does not exist');
      }
      
      // Add room to floor
      List<Map<String, dynamic>> rooms = List<Map<String, dynamic>>.from(
        floors[floorKey]['rooms'] ?? []
      );
      rooms.add(room.toMap());
      
      // Update floor's rooms
      floors[floorKey]['rooms'] = rooms;
      
      // Update kost document
      await _firestore.collection('kosts').doc(kostId).update({
        'floors': floors,
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

  Future<bool> updateRoom(String kostId, String roomId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kostData = kostDoc.data() as Map<String, dynamic>;
      
      // Get floors data
      Map<String, dynamic> floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Find room in floors
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
      
      // Get rooms of target floor
      List<Map<String, dynamic>> rooms = List<Map<String, dynamic>>.from(
        floors[targetFloorKey]['rooms'] ?? []
      );
      
      // Update room
      rooms[roomIndex] = {
        ...rooms[roomIndex],
        ...updates,
      };
      
      // If floor changed, move room to new floor
      if (updates.containsKey('floor')) {
        final newFloorKey = updates['floor'].toString();
        if (newFloorKey != targetFloorKey) {
          // Remove from old floor
          rooms.removeAt(roomIndex);
          floors[targetFloorKey]['rooms'] = rooms;
          
          // Add to new floor
          if (!floors.containsKey(newFloorKey)) {
            throw Exception('Target floor does not exist');
          }
          List<Map<String, dynamic>> newFloorRooms = List<Map<String, dynamic>>.from(
            floors[newFloorKey]['rooms'] ?? []
          );
          newFloorRooms.add(rooms[roomIndex]);
          floors[newFloorKey]['rooms'] = newFloorRooms;
        } else {
          // Update rooms in current floor
          floors[targetFloorKey]['rooms'] = rooms;
        }
      } else {
        // Update rooms in current floor
        floors[targetFloorKey]['rooms'] = rooms;
      }
      
      // Update kost document
      await _firestore.collection('kosts').doc(kostId).update({
        'floors': floors,
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

  Future<bool> deleteRoom(String kostId, String roomId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kostData = kostDoc.data() as Map<String, dynamic>;
      
      // Get floors data
      Map<String, dynamic> floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Find and delete room from its floor
      for (var entry in floors.entries) {
        List<Map<String, dynamic>> rooms = List<Map<String, dynamic>>.from(
          entry.value['rooms'] ?? []
        );
        final index = rooms.indexWhere((room) => room['id'] == roomId);
        if (index != -1) {
          rooms.removeAt(index);
          floors[entry.key]['rooms'] = rooms;
          break;
        }
      }
      
      // Update kost document
      await _firestore.collection('kosts').doc(kostId).update({
        'floors': floors,
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

  Future<bool> updateRoomStatus(String kostId, String roomId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kostData = kostDoc.data() as Map<String, dynamic>;
      
      // Get floors data
      Map<String, dynamic> floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Find room in floors
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
      
      // Get rooms of target floor
      List<Map<String, dynamic>> rooms = List<Map<String, dynamic>>.from(
        floors[targetFloorKey]['rooms'] ?? []
      );
      
      // Update room status
      rooms[roomIndex] = {
        ...rooms[roomIndex],
        'status': status,
      };
      
      // Update rooms in floor
      floors[targetFloorKey]['rooms'] = rooms;
      
      // Update kost document
      await _firestore.collection('kosts').doc(kostId).update({
        'floors': floors,
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

  Future<Room?> getRoomById(String kostId, String roomId) async {
    try {
      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kostData = kostDoc.data() as Map<String, dynamic>;
      
      // Get floors data
      Map<String, dynamic> floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
      
      // Find room in floors
      for (var entry in floors.entries) {
        final rooms = List<Map<String, dynamic>>.from(entry.value['rooms'] ?? []);
        final roomData = rooms.firstWhere(
          (room) => room['id'] == roomId,
          orElse: () => <String, dynamic>{},
        );
        
        if (roomData.isNotEmpty) {
          return Room(
            id: roomData['id'],
            name: roomData['name'],
            status: roomData['status'],
            price: roomData['price'].toDouble(),
            facilities: Map<String, bool>.from(roomData['facilities']),
            position: Position.fromMap(roomData['position']),
            size: Size.fromMap(roomData['size']),
            floor: int.parse(entry.key),
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting room: $e');
      return null;
    }
  }

  Stream<List<Room>> getAvailableRooms(String kostId) {
    return _firestore
        .collection('kosts')
        .doc(kostId)
        .snapshots()
        .map((doc) {
          final kostData = doc.data() as Map<String, dynamic>;
          final floors = Map<String, dynamic>.from(kostData['floors'] ?? {});
          
          List<Room> availableRooms = [];
          
          for (var entry in floors.entries) {
            final rooms = List<Map<String, dynamic>>.from(entry.value['rooms'] ?? []);
            final floorRooms = rooms
                .where((room) => room['status'] == 'available')
                .map((room) => Room(
                      id: room['id'],
                      name: room['name'],
                      status: room['status'],
                      price: room['price'].toDouble(),
                      facilities: Map<String, bool>.from(room['facilities']),
                      position: Position.fromMap(room['position']),
                      size: Size.fromMap(room['size']),
                      floor: int.parse(entry.key),
                    ))
                .toList();
            
            availableRooms.addAll(floorRooms);
          }
          
          return availableRooms;
        });
  }

  // Verification Methods
  Future<bool> verifyKost(String kostId) async {
    return updateKost(kostId, {
      'status': 'verified',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> rejectKost(String kostId, String reason) async {
    return updateKost(kostId, {
      'status': 'rejected',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Query Methods
  Stream<List<Kost>> getKostsByOwner(String ownerId) {
    return _firestore
        .collection('kosts')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Kost.fromFirestore(doc)).toList());
  }

  Stream<List<Kost>> getPendingKosts() {
    return _firestore
        .collection('kosts')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Kost.fromFirestore(doc)).toList());
  }

  Stream<List<Kost>> searchKosts(String query) {
    return _firestore
        .collection('kosts')
        .where('status', isEqualTo: 'verified')
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Kost.fromFirestore(doc)).toList());
  }

  Future<bool> createKostWithFloors(
    Kost kost,
    Map<int, File?> floorPlanFiles,
    List<File> imageFiles,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Convert floor plan files to base64
      Map<int, FloorPlan> floors = {};
      for (var entry in floorPlanFiles.entries) {
        if (entry.value != null) {
          try {
            // Read file as bytes and convert to base64
            final bytes = await entry.value!.readAsBytes();
            final base64String = base64Encode(bytes);
            
            floors[entry.key] = FloorPlan(
              imageUrl: 'data:image/jpeg;base64,$base64String',
              name: 'Floor ${entry.key}',
              rooms: [],
            );
          } catch (e) {
            print('Error converting floor plan ${entry.key}: $e');
          }
        }
      }

      // Convert images to base64
      List<String> imageUrls = [];
      for (var imageFile in imageFiles) {
        try {
          // Read file as bytes and convert to base64
          final bytes = await imageFile.readAsBytes();
          final base64String = base64Encode(bytes);
          imageUrls.add('data:image/jpeg;base64,$base64String');
        } catch (e) {
          print('Error converting image: $e');
        }
      }

      // Create kost document with base64 images
      final kostRef = await _firestore.collection('kosts').add({
        ...kost.toMap(),
        'floors': floors.map((key, value) => MapEntry(key.toString(), value.toMap())),
        'images': imageUrls,
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

  Future<bool> updateKostWithFloors(
    String kostId,
    Map<String, dynamic> updates,
    Map<int, File?> newFloorPlanFiles,
    List<File> newImageFiles,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if document exists first
      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      if (!kostDoc.exists) {
        throw Exception('Kost document not found');
      }

      final kostData = kostDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> floors = Map<String, dynamic>.from(kostData['floors'] ?? {});

      // Convert new floor plans to base64
      for (var entry in newFloorPlanFiles.entries) {
        if (entry.value != null) {
          try {
            // Read file as bytes and convert to base64
            final bytes = await entry.value!.readAsBytes();
            final base64String = base64Encode(bytes);
            
            floors[entry.key.toString()] = {
              'imageUrl': 'data:image/jpeg;base64,$base64String',
              'name': 'Floor ${entry.key}',
              'rooms': floors[entry.key.toString()]?['rooms'] ?? [],
            };
          } catch (e) {
            print('Error converting floor plan ${entry.key}: $e');
          }
        }
      }

      // Convert new images to base64 if any
      if (newImageFiles.isNotEmpty) {
        List<String> existingImages = List<String>.from(kostData['images'] ?? []);
        List<String> newImageUrls = [];

        for (var imageFile in newImageFiles) {
          try {
            // Read file as bytes and convert to base64
            final bytes = await imageFile.readAsBytes();
            final base64String = base64Encode(bytes);
            newImageUrls.add('data:image/jpeg;base64,$base64String');
          } catch (e) {
            print('Error converting new image: $e');
          }
        }

        // Combine existing and new images
        if (newImageUrls.isNotEmpty) {
          updates['images'] = [...existingImages, ...newImageUrls];
        }
      }

      // Update kost document
      updates['floors'] = floors;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('kosts').doc(kostId).update(updates);

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
} 