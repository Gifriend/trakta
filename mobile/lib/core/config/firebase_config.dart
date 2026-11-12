import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public client configuration; never put service-account credentials here.
abstract final class FirebaseConfig {
  static const useEmulators = bool.fromEnvironment('FIREBASE_USE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST', defaultValue: '10.0.2.2',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static bool get isIos => defaultTargetPlatform == TargetPlatform.iOS;
  static String get apiKey => isIos
      ? const String.fromEnvironment('FIREBASE_API_KEY_IOS')
      : const String.fromEnvironment('FIREBASE_API_KEY_ANDROID');
  static String get appId => isIos
      ? const String.fromEnvironment('FIREBASE_APP_ID_IOS')
      : const String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
  static bool get configured => useEmulators ||
      [projectId, senderId, apiKey, appId].every((value) => value.isNotEmpty);

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: useEmulators ? 'demo-api-key' : apiKey,
    appId: useEmulators ? (isIos ? '1:123456789:ios:abcdef' : '1:123456789:android:abcdef') : appId,
    messagingSenderId: useEmulators ? '123456789' : senderId,
    projectId: useEmulators ? 'demo-presensi' : projectId,
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.trakta.traktaMobile'),
  );
}
