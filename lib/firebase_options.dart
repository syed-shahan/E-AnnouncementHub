// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      // For now we just reuse the Android config for other non-web platforms.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return android;
      default:
        return android;
    }
  }

  /// Config for your *web app*: eannouncementhub_web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAIQ49v5-0X9Tu249Quw0Y6OeA9Lb-nA2Q',
    appId: '1:608095749005:web:f8aa5723a666d42bd0f3c4',
    messagingSenderId: '608095749005',
    projectId: 'eannouncementhub',
    authDomain: 'eannouncementhub.firebaseapp.com',
    storageBucket: 'eannouncementhub.firebasestorage.app',
    measurementId: 'G-726EDJ6ESV',
  );

  /// Config for your *Android app*: com.example.eannouncementhubb
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIQ49v5-0X9Tu249Quw0Y6OeA9Lb-nA2Q',
    appId: '1:608095749005:android:6044fcb14604c1f8d0f3c4',
    messagingSenderId: '608095749005',
    projectId: 'eannouncementhub',
    storageBucket: 'eannouncementhub.firebasestorage.app',
  );
}