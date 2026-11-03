import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';

class ShahlingoFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    return web;
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCn3gM5kZMp2V5tr1jN22hBJ39WdvG9rI0',
    appId: '1:246943496514:android:3f209857265dad9826f0db',
    messagingSenderId: '246943496514',
    projectId: 'shahlingo',
    databaseURL:
        'https://shahlingo-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'shahlingo.firebasestorage.app',
  );

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyC9vJ9ZSjeF9zteDNhxfzcK83eY5KRPfMc',
    appId: '1:246943496514:web:b2e0e3cba867d59326f0db',
    messagingSenderId: '246943496514',
    projectId: 'shahlingo',
    authDomain: 'shahlingo.firebaseapp.com',
    databaseURL:
        'https://shahlingo-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'shahlingo.firebasestorage.app',
  );
}
