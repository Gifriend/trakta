import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:trakta_mobile/core/models/attendance.dart';
import 'package:trakta_mobile/core/services/attendance_service.dart';
import 'package:trakta_mobile/core/services/location_service.dart';
import 'package:trakta_mobile/core/utils/app_error.dart';
import 'package:trakta_mobile/core/utils/wib.dart';

void main() {
  final now = DateTime.utc(2026, 11, 12, 6);
  PhotoLocation location({
    double latitude = LocationService.officeLatitude,
    double longitude = LocationService.officeLongitude,
    double accuracy = 10,
    PhotoSource source = PhotoSource.camera,
  }) => PhotoLocation(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    source: source,
  );
  test(
    'WIB uses UTC+7 across month and year boundaries, independent of device zone',
    () {
      expect(Wib.key(DateTime.parse('2026-12-31T17:00:00Z')), '20270101');
      expect(Wib.key(DateTime.parse('2026-12-31T16:59:59Z')), '20261231');
      expect(Wib.key(DateTime.parse('2026-11-12T01:30:00+09:00')), '20261111');
      expect(Wib.time(DateTime.parse('2026-11-11T17:00:00Z')), '00:00');
    },
  );
  test(
    'office uses the same source, accuracy and distance rules as the web',
    () {
      expect(LocationService.issue(location(), WorkMode.office), isNull);
      expect(
        LocationService.issue(location(accuracy: 100), WorkMode.office),
        isNull,
      );
      expect(
        LocationService.issue(location(accuracy: 100.01), WorkMode.office),
        isNotNull,
      );
      expect(
        LocationService.issue(
          location(source: PhotoSource.gallery),
          WorkMode.office,
        ),
        isNotNull,
      );
      expect(
        LocationService.issue(
          location(latitude: LocationService.officeLatitude + 149 / 110600),
          WorkMode.office,
        ),
        isNull,
      );
      expect(
        LocationService.issue(
          location(latitude: LocationService.officeLatitude + 151 / 110600),
          WorkMode.office,
        ),
        isNotNull,
      );
      expect(
        LocationService.issue(
          location(latitude: 0, source: PhotoSource.gallery),
          WorkMode.remote,
        ),
        isNull,
      );
      expect(
        LocationService.issue(location(latitude: double.nan), WorkMode.field),
        isNotNull,
      );
    },
  );
  test(
    'submission requires fresh WIB day, location, note limit and <= 100 KB photo',
    () {
      final photo = CapturedPhoto(Uint8List(100000), location: location());
      void validate({
        String key = '20261112',
        String note = '',
        CapturedPhoto? input,
      }) => AttendanceService.validate(
        key: key,
        mode: WorkMode.office,
        note: note,
        photo: input ?? photo,
        now: now,
      );
      expect(validate, returnsNormally);
      expect(() => validate(key: '20261111'), throwsA(isA<AppException>()));
      expect(() => validate(note: 'a' * 301), throwsA(isA<AppException>()));
      expect(() => validate(note: 'a' * 300), returnsNormally);
      expect(
        () => validate(
          input: CapturedPhoto(Uint8List(100001), location: location()),
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => validate(input: CapturedPhoto(Uint8List(10))),
        throwsA(isA<AppException>()),
      );
    },
  );
}
