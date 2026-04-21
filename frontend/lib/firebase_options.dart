// ignore_for_file: lines_longer_than_80_chars
//
// Remplacez ce fichier en exécutant dans le dossier `frontend` :
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Ou copiez les valeurs depuis la console Firebase : Paramètres du projet
// > Vos applications > SDK (apiKey, appId, messagingSenderId, projectId, etc.).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options Firebase par plateforme.
///
/// Tant que les valeurs `TODO_*` ne sont pas remplacées, l’initialisation peut échouer.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne gère pas cette plateforme.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBns_XYur1lixtL1vuQXc1cqwfkgmABSLk',
    appId: '1:418666244200:web:1f5cd64416edd42ed8b3dd',
    messagingSenderId: '418666244200',
    projectId: 'smart-incident-reporter-5f55e',
    authDomain: 'smart-incident-reporter-5f55e.firebaseapp.com',
    storageBucket: 'smart-incident-reporter-5f55e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCkG--J5dXwOTWyzB4hklZAoPkL2ID7MYI',
    appId: '1:418666244200:android:543be148e685bf6cd8b3dd',
    messagingSenderId: '418666244200',
    projectId: 'smart-incident-reporter-5f55e',
    storageBucket: 'smart-incident-reporter-5f55e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBSOOi-dxAIpnGLSyVWr7XrzLFmoWQNwt8',
    appId: '1:418666244200:ios:45ce37e95141e690d8b3dd',
    messagingSenderId: '418666244200',
    projectId: 'smart-incident-reporter-5f55e',
    storageBucket: 'smart-incident-reporter-5f55e.firebasestorage.app',
    iosBundleId: 'com.example.frontend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBSOOi-dxAIpnGLSyVWr7XrzLFmoWQNwt8',
    appId: '1:418666244200:ios:45ce37e95141e690d8b3dd',
    messagingSenderId: '418666244200',
    projectId: 'smart-incident-reporter-5f55e',
    storageBucket: 'smart-incident-reporter-5f55e.firebasestorage.app',
    iosBundleId: 'com.example.frontend',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBns_XYur1lixtL1vuQXc1cqwfkgmABSLk',
    appId: '1:418666244200:web:ab7b519f8c43d70cd8b3dd',
    messagingSenderId: '418666244200',
    projectId: 'smart-incident-reporter-5f55e',
    authDomain: 'smart-incident-reporter-5f55e.firebaseapp.com',
    storageBucket: 'smart-incident-reporter-5f55e.firebasestorage.app',
  );
}
