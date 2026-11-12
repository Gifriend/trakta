import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/attendance.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/utils/app_error.dart';
import '../../auth/data/repositories/auth_repository.dart';
import 'attendance_state.dart';

typedef AttendanceRequest = ({String key, AttendanceKind kind});
final attendanceControllerProvider = StateNotifierProvider.autoDispose
    .family<AttendanceController, AttendanceState, AttendanceRequest>(
      (ref, request) => AttendanceController(
        ref.watch(attendanceServiceProvider),
        ref.watch(authSessionProvider).valueOrNull?.uid ?? '',
        request,
      ),
    );

class AttendanceController extends StateNotifier<AttendanceState> {
  AttendanceController(this._service, this._uid, this.request)
    : super(const AttendanceState());
  final AttendanceService _service;
  final String _uid;
  final AttendanceRequest request;
  void setMode(WorkMode mode) {
    if (!state.busy) {
      state = state.copyWith(mode: mode, photo: null, error: null);
    }
  }

  void setNote(String note) {
    if (!state.busy) state = state.copyWith(note: note);
  }

  void setPhoto(CapturedPhoto? photo) {
    if (!state.busy) state = state.copyWith(photo: photo, error: null);
  }

  void setError(Object error) {
    if (mounted) state = state.copyWith(error: friendlyError(error));
  }

  Future<void> submit() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      await _service.submit(
        uid: _uid,
        key: request.key,
        kind: request.kind,
        mode: state.mode,
        note: state.note,
        photo: state.photo,
      );
      if (mounted) {
        state = state.copyWith(busy: false, saved: true, photo: null);
      }
    } catch (error) {
      if (mounted) {
        state = state.copyWith(busy: false, error: friendlyError(error));
      }
    }
  }
}
