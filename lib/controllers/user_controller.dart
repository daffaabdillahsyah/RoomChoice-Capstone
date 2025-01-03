import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize listeners
  UserController() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      _users = snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          id: doc.id,
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'user',
        );
      }).toList();
      notifyListeners();
    });
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
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

  Future<bool> deleteUser(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('users').doc(userId).delete();

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

  Stream<List<User>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .orderBy('username')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return User(
                id: doc.id,
                username: data['username'] ?? '',
                email: data['email'] ?? '',
                role: data['role'] ?? 'user',
              );
            }).toList());
  }
} 