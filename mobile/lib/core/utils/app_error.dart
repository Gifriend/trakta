import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

String friendlyError(Object error) {
  if (error is AppException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email atau kata sandi tidak sesuai.',
      'email-already-in-use' => 'Email sudah terdaftar. Silakan masuk.',
      'invalid-email' => 'Masukkan alamat email yang valid.',
      'weak-password' => 'Gunakan kata sandi minimal 8 karakter.',
      'too-many-requests' =>
        'Terlalu banyak percobaan. Coba beberapa saat lagi.',
      'network-request-failed' ||
      'unavailable' => 'Hubungkan internet lalu coba lagi.',
      'permission-denied' =>
        'Presensi ditolak. Periksa lokasi, tanggal perangkat, dan izin akses Firebase.',
      'unauthenticated' => 'Sesi berakhir. Silakan masuk kembali.',
      _ => 'Permintaan belum berhasil. Silakan coba lagi.',
    };
  }
  return 'Permintaan belum berhasil. Silakan coba lagi.';
}
