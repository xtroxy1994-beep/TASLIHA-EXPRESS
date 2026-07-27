import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profileImagesPath)
          .child('$userId.jpg');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadRechargeReceipt(File imageFile, String userId) async {
    try {
      final fileName = '${userId}_${_uuid.v4()}.jpg';
      final ref = _storage
          .ref()
          .child(AppConstants.rechargeReceiptsPath)
          .child(fileName);
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadRequestImage(File imageFile, String requestId, int index) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.requestImagesPath)
          .child(requestId)
          .child('image_$index.jpg');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> images, String requestId) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final url = await uploadRequestImage(images[i], requestId, i);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {}
  }
}
