import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/services/auth_service.dart';
part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthMode.login) AuthMode mode,
    @Default(false) bool busy,
    String? error,
    String? message,
  }) = _AuthState;
}
