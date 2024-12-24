import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../models/password_history.dart';
import 'dart:convert';
import 'dart:math';

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

  Future<User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return User(
      id: user.uid,
      username: data['username'] as String? ?? '',
      email: user.email ?? '',
      role: data['role'] as String? ?? 'user',
    );
  }

  void _logError(String message, [Object? error]) {
    debugPrint('Error: $message${error != null ? ' - $error' : ''}');
  }

  void _logInfo(String message) {
    debugPrint('Info: $message');
  }

  Future<void> createDefaultAdmin() async {
    try {
      final adminDoc = await _firestore.collection('users').where('username', isEqualTo: 'admin').limit(1).get();
      
      if (adminDoc.docs.isEmpty) {
        final adminCredential = await _auth.createUserWithEmailAndPassword(
          email: 'admin@roomchoice.com',
          password: 'admin123',
        );

        await _firestore.collection('users').doc(adminCredential.user!.uid).set({
          'username': 'admin',
          'email': 'admin@roomchoice.com',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _logInfo('Default admin account created successfully');
      }
    } catch (e) {
      _logError('Error creating default admin', e);
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _setLoading(true);
    _setError(null);

    try {
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user == null) {
        throw Exception('Failed to create user');
      }

      final user = authResult.user!;
      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _currentUser = User(
        id: user.uid,
        username: username,
        email: email,
        role: 'user',
      );

      _setLoading(false);
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _logError('Firebase Auth error: ${e.code}', e.message);
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
      _logError('Unexpected error during registration', e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      // Handle admin login
      if (email.toLowerCase() == 'admin' && password == 'admin123') {
        email = 'admin@roomchoice.com';
      }

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
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      final data = doc.data()!;
      
      // Step 3: Update local state
      _currentUser = User(
        id: user.uid,
        username: data['username'] as String? ?? '',
        email: user.email ?? '',
        role: data['role'] as String? ?? 'user',
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? reason,
  }) async {
    try {
      // Re-authenticate user
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'User not logged in';
      }

      final credential = auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Get current password hash
      final oldPasswordHash = await _hashPassword(currentPassword);
      final newPasswordHash = await _hashPassword(newPassword);

      // Change password
      await user.updatePassword(newPassword);

      // Save to password history if admin
      final currentUser = await getCurrentUser();
      if (currentUser?.role == 'admin') {
        await _firestore.collection('password_history').add({
          'userId': user.uid,
          'changedBy': user.uid,
          'oldPassword': oldPasswordHash,
          'newPassword': newPasswordHash,
          'timestamp': FieldValue.serverTimestamp(),
          'reason': reason ?? 'Regular password update',
        });
      }

      notifyListeners();
    } on auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw 'Current password is incorrect';
        case 'requires-recent-login':
          throw 'Please log in again to change your password';
        default:
          throw 'Failed to change password: ${e.message}';
      }
    } catch (e) {
      throw 'Failed to change password: $e';
    }
  }

  Future<String> _hashPassword(String password) async {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Stream<List<PasswordHistory>> getPasswordHistory(String userId) {
    return _firestore
        .collection('password_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PasswordHistory.fromFirestore(doc))
          .toList();
    });
  }
} 