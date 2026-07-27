import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String requestId;
  final String clientId;
  final String clientName;
  final String techId;
  final double stars;
  final String comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.clientName,
    required this.techId,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map, String docId) {
    return RatingModel(
      id: docId,
      requestId: map['requestId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      techId: map['techId'] ?? '',
      stars: (map['stars'] ?? 5.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'clientId': clientId,
      'clientName': clientName,
      'techId': techId,
      'stars': stars,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
