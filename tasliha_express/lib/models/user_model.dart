import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role; // client, tech, manager, admin
  final String wilaya;
  final String commune;
  final String? profileImageUrl;
  final List<String> specialties; // for tech only
  final int totalPoints;
  final int freePoints;
  final DateTime? freePointsExpiry;
  final double rating;
  final int ratingCount;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.wilaya,
    required this.commune,
    this.profileImageUrl,
    this.specialties = const [],
    this.totalPoints = 0,
    this.freePoints = 0,
    this.freePointsExpiry,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.lastSeen,
  });

  String get fullName => '$firstName $lastName';

  String get techLevel {
    if (rating >= 4.5) return 'خبير';
    if (rating >= 4.0) return 'ممتاز';
    if (rating >= 3.0) return 'جيد';
    if (rating >= 2.0) return 'متوسط';
    return 'ضعيف';
  }

  int get availablePoints {
    final now = DateTime.now();
    int points = totalPoints;
    if (freePointsExpiry != null && now.isBefore(freePointsExpiry!)) {
      points += freePoints;
    }
    return points;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'client',
      wilaya: map['wilaya'] ?? '',
      commune: map['commune'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      specialties: List<String>.from(map['specialties'] ?? []),
      totalPoints: map['totalPoints'] ?? 0,
      freePoints: map['freePoints'] ?? 0,
      freePointsExpiry: map['freePointsExpiry'] != null
          ? (map['freePointsExpiry'] as Timestamp).toDate()
          : null,
      rating: (map['rating'] ?? 5.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'wilaya': wilaya,
      'commune': commune,
      'profileImageUrl': profileImageUrl,
      'specialties': specialties,
      'totalPoints': totalPoints,
      'freePoints': freePoints,
      'freePointsExpiry': freePointsExpiry != null
          ? Timestamp.fromDate(freePointsExpiry!)
          : null,
      'rating': rating,
      'ratingCount': ratingCount,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? wilaya,
    String? commune,
    String? profileImageUrl,
    List<String>? specialties,
    int? totalPoints,
    int? freePoints,
    DateTime? freePointsExpiry,
    double? rating,
    int? ratingCount,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      wilaya: wilaya ?? this.wilaya,
      commune: commune ?? this.commune,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      specialties: specialties ?? this.specialties,
      totalPoints: totalPoints ?? this.totalPoints,
      freePoints: freePoints ?? this.freePoints,
      freePointsExpiry: freePointsExpiry ?? this.freePointsExpiry,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
