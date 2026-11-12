import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/attendance.dart';
part 'attendance_state.freezed.dart';

@freezed
abstract class AttendanceState with _$AttendanceState {
  const factory AttendanceState({
    @Default(WorkMode.office) WorkMode mode,
    @Default('') String note,
    CapturedPhoto? photo,
    @Default(false) bool busy,
    @Default(false) bool saved,
    String? error,
  }) = _AttendanceState;
}
