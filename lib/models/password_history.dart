import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordHistory {
  final String id;
  final String userId;
  final String changedBy;
  final String oldPassword; // Hashed
  final String newPassword; // Hashed
  final DateTime timestamp;
  final String reason;

  PasswordHistory({
    required this.id,
    required this.userId,
    required this.changedBy,
    required this.oldPassword,
    required this.newPassword,
    required this.timestamp,
    required this.reason,
  });

  factory PasswordHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PasswordHistory(
      id: doc.id,
      userId: data['userId'] ?? '',
      changedBy: data['changedBy'] ?? '',
      oldPassword: data['oldPassword'] ?? '',
      newPassword: data['newPassword'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'changedBy': changedBy,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'timestamp': Timestamp.fromDate(timestamp),
      'reason': reason,
    };
  }
} 