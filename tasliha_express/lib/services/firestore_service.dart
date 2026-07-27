import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../models/rating_model.dart';
import '../models/point_transaction_model.dart';
import '../constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── USERS ──────────────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  Stream<List<UserModel>> watchTechs({String? specialty, String? wilaya}) {
    Query query = _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleTech)
        .where('isActive', isEqualTo: true);
    if (wilaya != null) query = query.where('wilaya', isEqualTo: wilaya);
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>)).toList());
  }

  Future<List<UserModel>> getAllTechs() async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleTech)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection(AppConstants.usersCollection).get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  // ── REQUESTS ───────────────────────────────────────────────────────────────
  Future<String> createRequest(RequestModel request) async {
    final ref = await _db
        .collection(AppConstants.requestsCollection)
        .add(request.toMap());
    return ref.id;
  }

  Stream<List<RequestModel>> watchClientRequests(String clientId) {
    return _db
        .collection(AppConstants.requestsCollection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<RequestModel>> watchAvailableRequests() {
    return _db
        .collection(AppConstants.requestsCollection)
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<RequestModel>> watchTechJobs(String techId) {
    return _db
        .collection(AppConstants.requestsCollection)
        .where('acceptedTechId', isEqualTo: techId)
        .orderBy('acceptedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<RequestModel>> watchAllRequests() {
    return _db
        .collection(AppConstants.requestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<RequestModel>> watchPendingRequests() {
    return _db
        .collection(AppConstants.requestsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> updateRequest(String requestId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.requestsCollection)
        .doc(requestId)
        .update(data);
  }

  Future<void> acceptRequest({
    required String requestId,
    required String techId,
    required String techName,
    required int pointsToDeduct,
    required String clientPhone,
  }) async {
    final batch = _db.batch();
    final requestRef = _db.collection(AppConstants.requestsCollection).doc(requestId);
    final techRef = _db.collection(AppConstants.usersCollection).doc(techId);

    batch.update(requestRef, {
      'status': 'accepted',
      'acceptedTechId': techId,
      'acceptedTechName': techName,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // Deduct points from tech (free first, then paid)
    batch.update(techRef, {
      'freePoints': FieldValue.increment(-pointsToDeduct),
    });

    // Log transaction
    final txRef = _db.collection(AppConstants.transactionsCollection).doc();
    batch.set(txRef, {
      'userId': techId,
      'amount': -pointsToDeduct,
      'type': 'debit',
      'description': 'قبول طلب - $requestId',
      'requestId': requestId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> completeRequest(String requestId) async {
    await _db.collection(AppConstants.requestsCollection).doc(requestId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── RATINGS ────────────────────────────────────────────────────────────────
  Future<void> submitRating({
    required String requestId,
    required String clientId,
    required String clientName,
    required String techId,
    required double stars,
    required String comment,
  }) async {
    final batch = _db.batch();

    // Add rating document
    final ratingRef = _db.collection(AppConstants.ratingsCollection).doc();
    batch.set(ratingRef, {
      'requestId': requestId,
      'clientId': clientId,
      'clientName': clientName,
      'techId': techId,
      'stars': stars,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Mark request as rated
    final requestRef = _db.collection(AppConstants.requestsCollection).doc(requestId);
    batch.update(requestRef, {'isRated': true, 'clientRating': stars});

    await batch.commit();

    // Update tech rating average
    await _updateTechRating(techId);
  }

  Future<void> _updateTechRating(String techId) async {
    final snap = await _db
        .collection(AppConstants.ratingsCollection)
        .where('techId', isEqualTo: techId)
        .get();
    if (snap.docs.isEmpty) return;
    double total = 0;
    for (var doc in snap.docs) {
      total += (doc.data()['stars'] ?? 5.0).toDouble();
    }
    final avg = total / snap.docs.length;
    await _db.collection(AppConstants.usersCollection).doc(techId).update({
      'rating': avg,
      'ratingCount': snap.docs.length,
    });
  }

  Stream<List<RatingModel>> watchTechRatings(String techId) {
    return _db
        .collection(AppConstants.ratingsCollection)
        .where('techId', isEqualTo: techId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RatingModel.fromMap(d.data(), d.id)).toList());
  }

  // ── RECHARGE REQUESTS ──────────────────────────────────────────────────────
  Future<String> createRechargeRequest(Map<String, dynamic> data) async {
    final ref = await _db.collection(AppConstants.rechargeRequestsCollection).add(data);
    return ref.id;
  }

  Stream<List<RechargeRequestModel>> watchPendingRechargeRequests() {
    return _db
        .collection(AppConstants.rechargeRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RechargeRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<RechargeRequestModel>> watchUserRechargeRequests(String userId) {
    return _db
        .collection(AppConstants.rechargeRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RechargeRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> approveRechargeRequest({
    required String rechargeId,
    required String userId,
    required int pointsToAdd,
    String? adminNote,
  }) async {
    final batch = _db.batch();

    final rechargeRef = _db.collection(AppConstants.rechargeRequestsCollection).doc(rechargeId);
    batch.update(rechargeRef, {
      'status': 'approved',
      'adminNote': adminNote,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    final userRef = _db.collection(AppConstants.usersCollection).doc(userId);
    batch.update(userRef, {'totalPoints': FieldValue.increment(pointsToAdd)});

    final txRef = _db.collection(AppConstants.transactionsCollection).doc();
    batch.set(txRef, {
      'userId': userId,
      'amount': pointsToAdd,
      'type': 'credit',
      'description': 'شحن نقاط - طلب رقم $rechargeId',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectRechargeRequest(String rechargeId, String? adminNote) async {
    await _db.collection(AppConstants.rechargeRequestsCollection).doc(rechargeId).update({
      'status': 'rejected',
      'adminNote': adminNote,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── POINT TRANSACTIONS ─────────────────────────────────────────────────────
  Stream<List<PointTransactionModel>> watchUserTransactions(String userId) {
    return _db
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PointTransactionModel.fromMap(d.data(), d.id))
            .toList());
  }
}
