import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/kost_model.dart';

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

      // Create kost document first to get the ID
      final kostRef = await _firestore.collection('kosts').add(kost.toMap());
      final kostId = kostRef.id;

      // Upload floor plans
      Map<int, FloorPlan> floors = {};
      for (var entry in floorPlanFiles.entries) {
        if (entry.value != null) {
          try {
            // Create a specific path for this kost's floor plans
            final floorRef = _storage
                .ref()
                .child('kosts')
                .child(kostId)
                .child('floor_plans')
                .child('floor_${entry.key}');
            
            // Upload with metadata
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'kostId': kostId,
                'floor': entry.key.toString(),
              },
            );
            await floorRef.putFile(entry.value!, metadata);
            final floorPlanUrl = await floorRef.getDownloadURL();
            
            floors[entry.key] = FloorPlan(
              imageUrl: floorPlanUrl,
              name: 'Floor ${entry.key}',
              rooms: [],
            );
          } catch (e) {
            print('Error uploading floor plan ${entry.key}: $e');
            // Continue with other uploads even if one fails
          }
        }
      }

      // Upload images
      List<String> imageUrls = [];
      for (var imageFile in imageFiles) {
        try {
          // Create a specific path for this kost's images
          final imageRef = _storage
              .ref()
              .child('kosts')
              .child(kostId)
              .child('images')
              .child('image_${DateTime.now().millisecondsSinceEpoch}');
          
          // Upload with metadata
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'kostId': kostId,
            },
          );
          await imageRef.putFile(imageFile, metadata);
          final imageUrl = await imageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image: $e');
          // Continue with other uploads even if one fails
        }
      }

      // Update kost document with the uploaded files
      final kostData = {
        ...kost.toMap(),
        'floors': floors.map((key, value) => MapEntry(key.toString(), value.toMap())),
        'images': imageUrls,
      };

      await kostRef.update(kostData);

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
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current kost data
      final kostDoc = await _firestore.collection('kosts').doc(kostId).get();
      final kostData = kostDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> floors = Map<String, dynamic>.from(kostData['floors'] ?? {});

      // Upload new floor plans
      for (var entry in newFloorPlanFiles.entries) {
        if (entry.value != null) {
          try {
            // Delete old floor plan if exists
            final oldFloorPlan = floors[entry.key.toString()];
            if (oldFloorPlan != null) {
              final oldUrl = oldFloorPlan['imageUrl'];
              if (oldUrl != null) {
                try {
                  await _storage.refFromURL(oldUrl).delete();
                } catch (e) {
                  print('Error deleting old floor plan: $e');
                }
              }
            }

            // Upload new floor plan
            final floorRef = _storage
                .ref()
                .child('kosts')
                .child(kostId)
                .child('floor_plans')
                .child('floor_${entry.key}_${DateTime.now().millisecondsSinceEpoch}');
            
            // Upload with metadata
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'kostId': kostId,
                'floor': entry.key.toString(),
              },
            );
            await floorRef.putFile(entry.value!, metadata);
            final floorPlanUrl = await floorRef.getDownloadURL();
            
            floors[entry.key.toString()] = {
              'imageUrl': floorPlanUrl,
              'name': 'Floor ${entry.key}',
              'rooms': oldFloorPlan?['rooms'] ?? [],
            };
          } catch (e) {
            print('Error updating floor plan ${entry.key}: $e');
            // Continue with other updates even if one fails
          }
        }
      }

      // Update kost document
      updates['floors'] = floors;
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