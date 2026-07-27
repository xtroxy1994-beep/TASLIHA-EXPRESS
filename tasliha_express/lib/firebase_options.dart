import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCxHmrh9mdFdZ5z2cFfcpS3g6ETSAHt6vU',
    appId: '1:375029920196:android:e9a128c7f2c134d8f83491',
    messagingSenderId: '375029920196',
    projectId: 'tasliha-express',
    storageBucket: 'tasliha-express.firebasestorage.app',
  );
}
