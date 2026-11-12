import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_error.dart';
import 'auth_state.dart';
export '../../../core/services/auth_service.dart' show AuthMode;

final authControllerProvider =
    StateNotifierProvider.autoDispose<AuthController, AuthState>(
      (ref) => AuthController(ref.watch(authServiceProvider)),
    );

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service) : super(const AuthState());
  final AuthService _service;
  void changeMode(AuthMode mode) {
    if (!state.busy) state = AuthState(mode: mode);
  }

  Future<void> submit({
    required String name,
    required String email,
    required String password,
    required String locale,
  }) async {
    if (state.busy) return;
    final mode = state.mode;
    state = state.copyWith(busy: true, error: null, message: null);
    try {
      await _service.submit(
        mode: mode,
        name: name,
        email: email,
        password: password,
        locale: locale,
      );
      if (mounted) {
        state = state.copyWith(
          busy: false,
          message: mode == AuthMode.reset
              ? 'Jika email terdaftar, tautan reset akan dikirim. Periksa kotak masuk dan spam.'
              : null,
        );
      }
    } catch (error) {
      if (mounted) {
        state = state.copyWith(busy: false, error: friendlyError(error));
      }
    }
  }
}
