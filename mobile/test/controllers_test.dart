import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trakta_mobile/core/models/attendance.dart';
import 'package:trakta_mobile/core/services/auth_service.dart';
import 'package:trakta_mobile/core/services/export_service.dart';
import 'package:trakta_mobile/core/utils/app_error.dart';
import 'package:trakta_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:trakta_mobile/features/auth/presentations/auth_controller.dart';
import 'package:trakta_mobile/features/attendance/data/repositories/attendance_repository.dart';
import 'package:trakta_mobile/features/history/presentations/history_controller.dart';

class _AuthRepository extends Fake implements AuthRepository {
  int requests = 0;
  final pending = Completer<void>();
  @override
  Future<void> signIn(String email, String password) {
    requests++;
    return pending.future;
  }
}

class _HistoryRepository extends Fake implements AttendanceRepository {
  final calls = <({AttendanceRange range, Completer<AttendancePage> result})>[];
  @override
  Future<AttendancePage> page(
    String uid,
    AttendanceRange range, {
    String? after,
  }) {
    final result = Completer<AttendancePage>();
    calls.add((range: range, result: result));
    return result.future;
  }
}

class _Export extends Fake implements ExportService {}

void main() {
  test(
    'auth validates registration and prevents duplicate in-flight requests',
    () async {
      final repository = _AuthRepository(),
          service = AuthService(_AuthRepository());
      await expectLater(
        service.submit(
          mode: AuthMode.register,
          name: 'N',
          email: 'nadia@example.test',
          password: '12345678',
          locale: 'id',
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        service.submit(
          mode: AuthMode.register,
          name: 'Nadia',
          email: 'nadia@example.test',
          password: '1234567',
          locale: 'id',
        ),
        throwsA(isA<AppException>()),
      );
      final controller = AuthController(AuthService(repository));
      final request = controller.submit(
        name: '',
        email: 'nadia@example.test',
        password: 'password',
        locale: 'id',
      );
      await controller.submit(
        name: '',
        email: 'nadia@example.test',
        password: 'password',
        locale: 'id',
      );
      expect(repository.requests, 1);
      repository.pending.completeError(
        const AppException('Hubungkan internet lalu coba lagi.'),
      );
      await request;
      expect(controller.state.busy, isFalse);
      expect(controller.state.error, isNotNull);
      controller.changeMode(AuthMode.reset);
      expect(controller.state.error, isNull);
      controller.dispose();
    },
  );
  test(
    'history discards outdated filter responses and rejects reversed ranges',
    () async {
      final repository = _HistoryRepository();
      final controller = HistoryController(repository, _Export(), 'uid');
      final initial = controller.load();
      final next = controller.filter(from: '20261101', to: '20261130');
      final day = AttendanceDay(
        dateKey: '20261112',
        checkIn: AttendanceEvent(
          timestamp: DateTime.utc(2026, 11, 12, 1),
          mode: WorkMode.remote,
          note: '',
        ),
      );
      repository.calls[1].result.complete(AttendancePage([day], false));
      await next;
      repository.calls[0].result.complete(const AttendancePage([], false));
      await initial;
      expect(controller.state.days.single.dateKey, '20261112');
      await controller.filter(from: '20261201', to: '20261101');
      expect(repository.calls.length, 2);
      expect(controller.state.error, isNotNull);
      expect(controller.state.from, '20261101');
      controller.dispose();
    },
  );
}
