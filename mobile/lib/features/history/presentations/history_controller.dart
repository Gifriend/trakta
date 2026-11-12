import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/attendance.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/strings.dart';
import '../../attendance/data/repositories/attendance_repository.dart';
import '../../auth/data/repositories/auth_repository.dart';
import 'history_state.dart';

final historyControllerProvider =
    StateNotifierProvider.autoDispose<HistoryController, HistoryState>((ref) {
      final uid = ref.watch(authSessionProvider).valueOrNull?.uid ?? '';
      return HistoryController(
        ref.watch(attendanceRepositoryProvider),
        ref.watch(exportServiceProvider),
        uid,
      )..load();
    });

class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._repository, this._export, this._uid)
    : super(const HistoryState());
  final AttendanceRepository _repository;
  final ExportService _export;
  final String _uid;
  int _request = 0;
  AttendanceRange get range => AttendanceRange(from: state.from, to: state.to);
  Future<void> load({int? page}) async {
    final generation = ++_request;
    final target = page ?? state.page;
    state = state.copyWith(busy: true, error: null);
    try {
      final result = await _repository.page(
        _uid,
        range,
        after: state.cursors[target],
      );
      if (!mounted || generation != _request) return;
      final cursors = state.cursors.take(target + 1).toList();
      if (result.hasNext) cursors.add(result.days.last.dateKey);
      state = state.copyWith(
        days: result.days,
        hasNext: result.hasNext,
        page: target,
        cursors: cursors,
        busy: false,
      );
    } catch (error) {
      if (mounted && generation == _request) {
        state = state.copyWith(busy: false, error: friendlyError(error));
      }
    }
  }

  Future<void> filter({String? from, String? to}) async {
    if (state.exporting) return;
    if (from != null && to != null && from.compareTo(to) > 0) {
      state = state.copyWith(
        error: 'Tanggal mulai tidak boleh setelah tanggal akhir.',
      );
      return;
    }
    state = state.copyWith(
      from: from,
      to: to,
      cursors: [null],
      page: 0,
      days: [],
      hasNext: false,
    );
    await load();
  }

  void includePhotos(bool value) {
    if (!state.exporting) state = state.copyWith(includePhotos: value);
  }

  Future<Uint8List?> export(AppStrings strings) async {
    if (state.exporting) return null;
    state = state.copyWith(exporting: true, error: null);
    try {
      final bytes = await _export.create(
        _uid,
        range,
        strings,
        includePhotos: state.includePhotos,
      );
      if (!mounted) return null;
      state = state.copyWith(exporting: false);
      return bytes;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(exporting: false, error: friendlyError(error));
      }
      return null;
    }
  }
}
