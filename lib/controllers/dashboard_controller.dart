import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _userCount = 0;
  int _kostCount = 0;
  int _pendingCount = 0;
  int _reportCount = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentActivities = [];

  int get userCount => _userCount;
  int get kostCount => _kostCount;
  int get pendingCount => _pendingCount;
  int get reportCount => _reportCount;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  DashboardController() {
    _initializeListeners();
  }

  void _initializeListeners() {
    // Listen to users count
    _firestore.collection('users').snapshots().listen((snapshot) {
      _userCount = snapshot.docs.length;
      notifyListeners();
    });

    // Listen to kosts count
    _firestore.collection('kosts').snapshots().listen((snapshot) {
      _kostCount = snapshot.docs.length;
      notifyListeners();
    });

    // Listen to pending verifications
    _firestore.collection('kosts')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _pendingCount = snapshot.docs.length;
      notifyListeners();
    });

    // Listen to reports count
    _firestore.collection('reports').snapshots().listen((snapshot) {
      _reportCount = snapshot.docs.length;
      notifyListeners();
    });

    // Listen to recent activities
    _firestore.collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      _recentActivities = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
          'type': data['type'] ?? 'notification',
        };
      }).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  String getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return timestamp.toDate().toString().substring(0, 10);
    }
  }
} 