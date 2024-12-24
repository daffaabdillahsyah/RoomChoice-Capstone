import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get additional user data from Firestore
        final userData = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userData.exists) {
          _currentUser = User(
            id: userCredential.user!.uid,
            username: userData['username'] ?? '',
            email: userCredential.user!.email ?? '',
            role: userData['role'] ?? 'user',
            token: await userCredential.user!.getIdToken() ?? '',
          );
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _currentUser = User(
          id: userCredential.user!.uid,
          username: username,
          email: email,
          role: 'user',
          token: await userCredential.user!.getIdToken() ?? '',
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Check if user is already logged in
  Future<void> checkCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        _currentUser = User(
          id: user.uid,
          username: userData['username'] ?? '',
          email: user.email ?? '',
          role: userData['role'] ?? 'user',
          token: await user.getIdToken() ?? '',
        );
        notifyListeners();
      }
    }
  }
} 