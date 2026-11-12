import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_config.dart';

final bootstrapProvider = Provider<BootstrapResult>((ref) => const BootstrapResult());
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

class BootstrapResult {
  const BootstrapResult({this.ready = false, this.error});
  final bool ready;
  final String? error;
}

Future<BootstrapResult> bootstrapFirebase() async {
  if (!FirebaseConfig.configured) return const BootstrapResult();
  if (kReleaseMode && FirebaseConfig.useEmulators) {
    return const BootstrapResult(error: 'Mode emulator hanya tersedia pada build pengembangan.');
  }
  try {
    await Firebase.initializeApp(options: FirebaseConfig.options);
    // Match the web: do not persist attendance photos on shared devices.
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    if (FirebaseConfig.useEmulators) {
      await FirebaseAuth.instance.useAuthEmulator(FirebaseConfig.emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(FirebaseConfig.emulatorHost, 8085);
    }
    return const BootstrapResult(ready: true);
  } catch (_) {
    return const BootstrapResult(error: 'Firebase belum dapat dihubungkan. Periksa konfigurasi aplikasi lalu buka kembali.');
  }
}
