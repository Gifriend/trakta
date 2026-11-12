import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../../core/utils/wib.dart';
import '../data/repositories/attendance_repository.dart';

final currentDateProvider = StreamProvider<String>((ref) async* {
  yield Wib.key();
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => Wib.key(),
  ).distinct();
});
final attendanceFeedProvider = StreamProvider.autoDispose<AttendanceFeed>((
  ref,
) {
  final uid = ref.watch(authSessionProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(attendanceRepositoryProvider).watch(uid);
});
