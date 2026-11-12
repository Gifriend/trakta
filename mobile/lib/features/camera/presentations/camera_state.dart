import 'package:freezed_annotation/freezed_annotation.dart';
part 'camera_state.freezed.dart';

@freezed
abstract class CameraState with _$CameraState {
  const factory CameraState({
    @Default(false) bool ready,
    @Default(false) bool busy,
    @Default(true) bool front,
    @Default(0) int countdown,
    String? error,
  }) = _CameraState;
}
