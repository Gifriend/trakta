import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/attendance/data/repositories/attendance_repository.dart';
import '../models/attendance.dart';
import '../utils/app_error.dart';
import '../utils/wib.dart';
import 'location_service.dart';

final attendanceServiceProvider = Provider<AttendanceService>(
  (ref) => AttendanceService(ref.watch(attendanceRepositoryProvider)),
);

class AttendanceService {
  const AttendanceService(this._repository);
  final AttendanceRepository _repository;
  static void validate({
    required String key,
    required WorkMode mode,
    required String note,
    required CapturedPhoto? photo,
    DateTime? now,
  }) {
    if (key != Wib.key(now)) {
      throw const AppException(
        'Tanggal WIB sudah berubah. Buka kembali form presensi.',
      );
    }
    if (note.trim().runes.length > 300) {
      throw const AppException('Catatan maksimal 300 karakter.');
    }
    if (photo == null || photo.bytes.isEmpty || photo.bytes.length > 100000) {
      throw const AppException('Foto harus berukuran maksimal 100 KB.');
    }
    if (photo.location == null) {
      throw const AppException(
        'Ambil ulang foto untuk mencatat lokasi perangkat.',
      );
    }
    final issue = LocationService.issue(photo.location!, mode);
    if (issue != null) throw AppException(issue);
  }

  Future<void> submit({
    required String uid,
    required String key,
    required AttendanceKind kind,
    required WorkMode mode,
    required String note,
    required CapturedPhoto? photo,
  }) {
    validate(key: key, mode: mode, note: note, photo: photo);
    return _repository.submit(
      uid: uid,
      key: key,
      kind: kind,
      mode: mode,
      note: note,
      photo: photo!,
    );
  }
}
