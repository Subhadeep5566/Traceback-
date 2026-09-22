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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB60uHkKP7cY1l69QNj8nU8CXL8IBX2sR4',
    appId: '1:36819587571:web:2467c2be720fad189f8286',
    messagingSenderId: '36819587571',
    projectId: 'traceback-bgu-app',
    authDomain: 'traceback-bgu-app.firebaseapp.com',
    storageBucket: 'traceback-bgu-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDabba7C1RIRCJ_bLQxZC4CiedFjaJerAU',
    appId: '1:36819587571:android:141956bc5bf27fb19f8286',
    messagingSenderId: '36819587571',
    projectId: 'traceback-bgu-app',
    storageBucket: 'traceback-bgu-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDabba7C1RIRCJ_bLQxZC4CiedFjaJerAU',
    appId: '1:36819587571:ios:141956bc5bf27fb19f8286',
    messagingSenderId: '36819587571',
    projectId: 'traceback-bgu-app',
    storageBucket: 'traceback-bgu-app.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB60uHkKP7cY1l69QNj8nU8CXL8IBX2sR4',
    appId: '1:36819587571:web:2467c2be720fad189f8286',
    messagingSenderId: '36819587571',
    projectId: 'traceback-bgu-app',
    storageBucket: 'traceback-bgu-app.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB60uHkKP7cY1l69QNj8nU8CXL8IBX2sR4',
    appId: '1:36819587571:web:2467c2be720fad189f8286',
    messagingSenderId: '36819587571',
    projectId: 'traceback-bgu-app',
    storageBucket: 'traceback-bgu-app.firebasestorage.app',
  );
}
