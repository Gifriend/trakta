import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../utils/app_error.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authRepositoryProvider)),
);

enum AuthMode { login, register, reset }

class AuthService {
  const AuthService(this._repository);
  final AuthRepository _repository;
  Future<void> submit({
    required AuthMode mode,
    required String name,
    required String email,
    required String password,
    required String locale,
  }) async {
    final address = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      throw const AppException('Masukkan alamat email yang valid.');
    }
    if (mode == AuthMode.reset) {
      return _repository.resetPassword(address, locale);
    }
    if (mode == AuthMode.register) {
      if (name.trim().length < 2 || name.trim().length > 80) {
        throw const AppException('Nama harus terdiri dari 2–80 karakter.');
      }
      if (password.length < 8) {
        throw const AppException('Gunakan kata sandi minimal 8 karakter.');
      }
      return _repository.register(name.trim(), address, password);
    }
    if (password.isEmpty) throw const AppException('Masukkan kata sandi.');
    await _repository.signIn(address, password);
  }

  Future<void> signOut() => _repository.signOut();
}
