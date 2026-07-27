import 'package:cloud_firestore/cloud_firestore.dart';

class PointTransactionModel {
  final String id;
  final String userId;
  final int amount;
  final TransactionType type;
  final String description;
  final String? requestId;
  final DateTime createdAt;

  PointTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    this.requestId,
    required this.createdAt,
  });

  factory PointTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return PointTransactionModel(
      id: docId,
      userId: map['userId'] ?? '',
      amount: map['amount'] ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'debit'),
        orElse: () => TransactionType.debit,
      ),
      description: map['description'] ?? '',
      requestId: map['requestId'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'requestId': requestId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

enum TransactionType { credit, debit, free, bonus }

class RechargeRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final int pointsRequested;
  final int amountDZD;
  final String receiptImageUrl;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final String? adminNote;
  final DateTime? reviewedAt;

  RechargeRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.pointsRequested,
    required this.amountDZD,
    required this.receiptImageUrl,
    required this.status,
    required this.createdAt,
    this.adminNote,
    this.reviewedAt,
  });

  factory RechargeRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return RechargeRequestModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      pointsRequested: map['pointsRequested'] ?? 0,
      amountDZD: map['amountDZD'] ?? 0,
      receiptImageUrl: map['receiptImageUrl'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      adminNote: map['adminNote'],
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'pointsRequested': pointsRequested,
      'amountDZD': amountDZD,
      'receiptImageUrl': receiptImageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminNote': adminNote,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}
