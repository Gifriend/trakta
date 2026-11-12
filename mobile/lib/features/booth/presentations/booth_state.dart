import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'booth_state.freezed.dart';

@freezed
abstract class BoothState with _$BoothState {
  const factory BoothState({
    @Default(3) int count,
    @Default(false) bool grid,
    @Default(3) int timer,
    @Default(0xfffff1d8) int color,
    @Default(<Uint8List>[]) List<Uint8List> photos,
    Uint8List? collage,
    @Default(false) bool busy,
    String? error,
  }) = _BoothState;
}
