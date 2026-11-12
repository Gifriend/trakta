import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image/image.dart' as img;
import 'package:trakta_mobile/core/config/bootstrap.dart';
import 'package:trakta_mobile/core/config/firebase_config.dart';
import 'package:trakta_mobile/core/models/attendance.dart';
import 'package:trakta_mobile/core/services/attendance_service.dart';
import 'package:trakta_mobile/core/services/location_service.dart';
import 'package:trakta_mobile/core/utils/wib.dart';
import 'package:trakta_mobile/features/attendance/data/repositories/attendance_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native FlutterFire auth and atomic attendance match deployed emulator rules',
    (tester) async {
      expect(
        FirebaseConfig.useEmulators,
        isTrue,
        reason: 'This test must never write to production.',
      );
      if (!FirebaseConfig.useEmulators) return;
      final boot = await bootstrapFirebase();
      expect(boot.ready, isTrue);
      final auth = FirebaseAuth.instance, db = FirebaseFirestore.instance;
      final account = await auth.createUserWithEmailAndPassword(
        email: 'mobile-${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: 'test-password-2026',
      );
      final uid = account.user!.uid;
      final repository = AttendanceRepository(db, auth),
          service = AttendanceService(AttendanceRepository(db, auth));
      final photo = CapturedPhoto(
        img.encodeJpg(img.Image(width: 32, height: 32)),
        location: const PhotoLocation(
          latitude: LocationService.officeLatitude,
          longitude: LocationService.officeLongitude,
          accuracy: 10,
          source: PhotoSource.camera,
        ),
      );
      Future<void> submit(AttendanceKind kind) => service.submit(
        uid: uid,
        key: Wib.key(),
        kind: kind,
        mode: WorkMode.office,
        note: 'Flutter integration',
        photo: photo,
      );
      await expectLater(submit(AttendanceKind.checkOut), throwsException);
      await submit(AttendanceKind.checkIn);
      await expectLater(submit(AttendanceKind.checkIn), throwsException);
      await submit(AttendanceKind.checkOut);
      final page = await repository.page(uid, const AttendanceRange());
      expect(page.days.single.checkOut, isNotNull);
      expect(
        await repository.photo(uid, Wib.key(), AttendanceKind.checkIn),
        photo.bytes,
      );
      await auth.signOut();
      await expectLater(
        repository.page(uid, const AttendanceRange()),
        throwsException,
      );
    },
  );
}
