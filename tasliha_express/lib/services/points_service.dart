import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class PointsService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> hasEnoughPoints(String techId, int required) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(techId).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    final totalPoints = data['totalPoints'] ?? 0;
    final freePoints = data['freePoints'] ?? 0;
    final freeExpiry = data['freePointsExpiry'] as Timestamp?;
    int available = totalPoints;
    if (freeExpiry != null && freeExpiry.toDate().isAfter(DateTime.now())) {
      available += freePoints;
    }
    return available >= required;
  }

  /// Deducts points from tech: free points first (if valid), then paid points.
  Future<String?> deductPoints({
    required String techId,
    required int amount,
    required String requestId,
    required String description,
  }) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(techId).get();
      if (!doc.exists) return 'المستخدم غير موجود';
      final data = doc.data()!;
      final totalPoints = (data['totalPoints'] ?? 0) as int;
      int freePoints = (data['freePoints'] ?? 0) as int;
      final freeExpiry = data['freePointsExpiry'] as Timestamp?;
      final bool freeValid = freeExpiry != null && freeExpiry.toDate().isAfter(DateTime.now());

      int available = totalPoints + (freeValid ? freePoints : 0);
      if (available < amount) return 'نقاطك غير كافية لقبول هذا الطلب';

      int deductFromFree = 0;
      int deductFromPaid = 0;

      if (freeValid && freePoints > 0) {
        deductFromFree = amount <= freePoints ? amount : freePoints;
        deductFromPaid = amount - deductFromFree;
      } else {
        deductFromPaid = amount;
      }

      final batch = _db.batch();
      final userRef = _db.collection(AppConstants.usersCollection).doc(techId);
      final updateData = <String, dynamic>{};
      if (deductFromFree > 0) {
        updateData['freePoints'] = FieldValue.increment(-deductFromFree);
      }
      if (deductFromPaid > 0) {
        updateData['totalPoints'] = FieldValue.increment(-deductFromPaid);
      }
      batch.update(userRef, updateData);

      final txRef = _db.collection(AppConstants.transactionsCollection).doc();
      batch.set(txRef, {
        'userId': techId,
        'amount': -amount,
        'type': 'debit',
        'description': description,
        'requestId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return null; // success
    } catch (e) {
      return 'حدث خطأ: $e';
    }
  }

  Future<int> getUserAvailablePoints(String userId) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(userId).get();
    if (!doc.exists) return 0;
    final data = doc.data()!;
    final totalPoints = (data['totalPoints'] ?? 0) as int;
    final freePoints = (data['freePoints'] ?? 0) as int;
    final freeExpiry = data['freePointsExpiry'] as Timestamp?;
    final bool freeValid = freeExpiry != null && freeExpiry.toDate().isAfter(DateTime.now());
    return totalPoints + (freeValid ? freePoints : 0);
  }
}
