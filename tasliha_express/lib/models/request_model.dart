import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientWilaya;
  final String clientCommune;
  final String title;
  final String description;
  final String category;
  final List<String> imageUrls;
  final String status;
  final int pointsRequired;
  final String? acceptedTechId;
  final String? acceptedTechName;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final bool isRated;
  final double? clientRating;

  RequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientWilaya,
    required this.clientCommune,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrls = const [],
    required this.status,
    this.pointsRequired = 0,
    this.acceptedTechId,
    this.acceptedTechName,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.isRated = false,
    this.clientRating,
  });

  bool get isAvailable => status == 'available';
  bool get isAccepted => status == 'accepted' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending' || status == 'reviewed';

  factory RequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return RequestModel(
      id: docId,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientWilaya: map['clientWilaya'] ?? '',
      clientCommune: map['clientCommune'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: map['status'] ?? 'pending',
      pointsRequired: map['pointsRequired'] ?? 0,
      acceptedTechId: map['acceptedTechId'],
      acceptedTechName: map['acceptedTechName'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      isRated: map['isRated'] ?? false,
      clientRating: map['clientRating']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientWilaya': clientWilaya,
      'clientCommune': clientCommune,
      'title': title,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'status': status,
      'pointsRequired': pointsRequired,
      'acceptedTechId': acceptedTechId,
      'acceptedTechName': acceptedTechName,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isRated': isRated,
      'clientRating': clientRating,
    };
  }

  RequestModel copyWith({
    String? status,
    int? pointsRequired,
    String? acceptedTechId,
    String? acceptedTechName,
    DateTime? acceptedAt,
    DateTime? completedAt,
    bool? isRated,
    double? clientRating,
  }) {
    return RequestModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientWilaya: clientWilaya,
      clientCommune: clientCommune,
      title: title,
      description: description,
      category: category,
      imageUrls: imageUrls,
      status: status ?? this.status,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      acceptedTechId: acceptedTechId ?? this.acceptedTechId,
      acceptedTechName: acceptedTechName ?? this.acceptedTechName,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      isRated: isRated ?? this.isRated,
      clientRating: clientRating ?? this.clientRating,
    );
  }
}
