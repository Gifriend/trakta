import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/attendance.dart';
part 'history_state.freezed.dart';

@freezed
abstract class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default(<AttendanceDay>[]) List<AttendanceDay> days,
    @Default(false) bool busy,
    @Default(false) bool hasNext,
    @Default(false) bool exporting,
    @Default(false) bool includePhotos,
    @Default(<String?>[null]) List<String?> cursors,
    @Default(0) int page,
    String? from,
    String? to,
    String? error,
  }) = _HistoryState;
}
