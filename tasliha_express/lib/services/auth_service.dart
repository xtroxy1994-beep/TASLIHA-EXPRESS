import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _fetchCurrentUser();
      } else {
        _currentUserModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_auth.currentUser!.uid)
          .get();
      if (doc.exists) {
        _currentUserModel = UserModel.fromMap(doc.data()!);
        // Update last seen
        await doc.reference.update({'lastSeen': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<UserModel?> refreshCurrentUser() async {
    await _fetchCurrentUser();
    notifyListeners();
    return _currentUserModel;
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _fetchCurrentUser();
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> registerClient({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String wilaya,
    required String commune,
    String? profileImageUrl,
  }) async {
    try {
      _setLoading(true);
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        role: AppConstants.roleClient,
        wilaya: wilaya,
        commune: commune,
        profileImageUrl: profileImageUrl,
        totalPoints: 0,
        freePoints: 0,
        isActive: true,
        isVerified: true,
        createdAt: now,
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toMap());
      _currentUserModel = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> registerTech({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String wilaya,
    required String commune,
    required List<String> specialties,
    required String profileImageUrl,
  }) async {
    try {
      _setLoading(true);
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final now = DateTime.now();
      final freeExpiry = now.add(const Duration(days: AppConstants.freePointsValidityDays));
      final user = UserModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        role: AppConstants.roleTech,
        wilaya: wilaya,
        commune: commune,
        profileImageUrl: profileImageUrl,
        specialties: specialties,
        totalPoints: 0,
        freePoints: AppConstants.freePointsOnRegister,
        freePointsExpiry: freeExpiry,
        rating: 5.0,
        ratingCount: 0,
        isActive: true,
        isVerified: false,
        createdAt: now,
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toMap());
      // Log free points transaction
      await _firestore.collection(AppConstants.transactionsCollection).add({
        'userId': uid,
        'amount': AppConstants.freePointsOnRegister,
        'type': 'free',
        'description': 'نقاط مجانية عند التسجيل (صالحة لـ 30 يوماً)',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _currentUserModel = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUserModel = null;
    notifyListeners();
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات، يرجى المحاولة لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      default:
        return 'حدث خطأ غير متوقع: ${e.message}';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
