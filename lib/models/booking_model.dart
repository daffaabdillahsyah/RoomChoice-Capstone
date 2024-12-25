import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String kostId;
  final String roomId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? paymentDetails;

  Booking({
    required this.id,
    required this.kostId,
    required this.roomId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.updatedAt,
    this.paymentDetails,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      kostId: data['kostId'] ?? '',
      roomId: data['roomId'] ?? '',
      userId: data['userId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      paymentDetails: data['paymentDetails'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kostId': kostId,
      'roomId': roomId,
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paymentDetails': paymentDetails,
    };
  }

  Booking copyWith({
    String? id,
    String? kostId,
    String? roomId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? paymentDetails,
  }) {
    return Booking(
      id: id ?? this.id,
      kostId: kostId ?? this.kostId,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }
} 