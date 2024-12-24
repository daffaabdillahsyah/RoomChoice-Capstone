import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final _auth = auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> register(String email, String password, String username) async {
    _setLoading(true);
    _setError(null);

    try {
      // Step 1: Create auth user
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user == null) {
        throw Exception('Failed to create user');
      }

      // Step 2: Create user document
      final user = authResult.user!;
      final userData = {
        'username': username,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData);

      // Step 3: Update local state
      _currentUser = User(
        id: user.uid,
        username: username,
        email: email,
        role: 'user',
      );

      _setLoading(false);
      return true;
    } on auth.FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      _setError(switch (e.code) {
        'email-already-in-use' => 'Email is already registered',
        'invalid-email' => 'Invalid email format',
        'operation-not-allowed' => 'Email/password accounts are not enabled',
        'weak-password' => 'Password is too weak',
        _ => 'Registration failed: ${e.message}',
      });
      _setLoading(false);
      return false;
    } catch (e) {
      print('Unexpected error during registration: $e');
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      // Step 1: Sign in
      final authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user == null) {
        throw Exception('Failed to login');
      }

      // Step 2: Get user data
      final user = authResult.user!;
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      // Step 3: Update local state
      _currentUser = User(
        id: user.uid,
        username: doc.data()?['username'] ?? '',
        email: user.email ?? '',
        role: doc.data()?['role'] ?? 'user',
      );

      _setLoading(false);
      return true;
    } on auth.FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      _setError(switch (e.code) {
        'user-not-found' => 'No user found with this email',
        'wrong-password' => 'Wrong password',
        'invalid-email' => 'Invalid email format',
        'user-disabled' => 'This account has been disabled',
        _ => 'Authentication failed: ${e.message}',
      });
      _setLoading(false);
      return false;
    } catch (e) {
      print('Unexpected error during login: $e');
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _setError(null);
    } catch (e) {
      print('Error during logout: $e');
      _setError('Failed to logout');
    }
  }
} 