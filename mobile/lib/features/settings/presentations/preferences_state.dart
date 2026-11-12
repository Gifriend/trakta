import 'package:freezed_annotation/freezed_annotation.dart';
part 'preferences_state.freezed.dart';

enum AppTheme { classic, neo, glass, clay, swiss, deco, studio, lagoon, liquid }

@freezed
abstract class PreferencesState with _$PreferencesState {
  const factory PreferencesState({
    @Default(AppTheme.classic) AppTheme theme,
    @Default(false) bool dark,
    @Default('id') String locale,
    @Default('natural') String cameraEffect,
    @Default(true) bool correctMirroring,
    @Default(false) bool reduceTransparency,
  }) = _PreferencesState;
}
