import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trakta_mobile/core/models/attendance.dart';
import 'package:trakta_mobile/core/services/export_service.dart';
import 'package:trakta_mobile/core/services/photo_service.dart';
import 'package:trakta_mobile/core/utils/app_error.dart';
import 'package:trakta_mobile/core/utils/strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'photo processing applies rotation, crops and encodes valid bounded JPEG',
    () async {
      final input = img.Image(width: 800, height: 600);
      for (final pixel in input) {
        pixel.setRgb(pixel.x % 255, pixel.y % 255, (pixel.x * pixel.y) % 255);
      }
      final original = img.encodePng(input);
      final photo = await const PhotoService().prepare(
        original,
        effect: 'mono',
        turns: 1,
      );
      final decoded = img.decodeJpg(photo)!;
      expect(photo.length, lessThanOrEqualTo(100000));
      expect(decoded.width, lessThan(decoded.height));
      final pixel = decoded.getPixel(40, 40);
      expect((pixel.r - pixel.g).abs(), lessThan(4));
      final square = img.decodeJpg(
        await const PhotoService().prepare(original, square: true),
      )!;
      expect(square.width, square.height);
      await expectLater(
        const PhotoService().prepare(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<AppException>()),
      );
    },
  );
  test(
    'workbook uses numeric WIB times, safe inline notes and embedded photo relationships',
    () {
      final photo = img.encodeJpg(img.Image(width: 20, height: 10));
      final day = AttendanceDay(
        dateKey: '20261112',
        checkIn: AttendanceEvent(
          timestamp: DateTime.utc(2026, 11, 12, 1),
          mode: WorkMode.office,
          note: '=HYPERLINK("bad") & <note>',
        ),
        checkOut: AttendanceEvent(
          timestamp: DateTime.utc(2026, 11, 12, 10),
          mode: WorkMode.remote,
          note: 'Done',
        ),
      );
      final bytes = AttendanceWorkbook.encode(
        [day],
        const AppStrings('id', {}),
        includePhotos: true,
        photos: {'20261112/checkIn': photo, '20261112/checkOut': photo},
      );
      final zip = ZipDecoder().decodeBytes(bytes);
      String part(String name) =>
          utf8.decode(zip.findFile(name)!.content as List<int>);
      final sheet = part('xl/worksheets/sheet1.xml');
      expect(sheet, contains('t="inlineStr"'));
      expect(sheet, contains('=HYPERLINK(&quot;bad&quot;) &amp; &lt;note&gt;'));
      expect(sheet, contains('<v>0.3333333333333333</v>'));
      expect(sheet, contains('<v>0.375</v>'));
      expect(sheet, contains('state="frozen"'));
      expect(zip.findFile('xl/media/image1.jpg'), isNotNull);
      expect(zip.findFile('xl/media/image2.jpg'), isNotNull);
      final drawing = part('xl/drawings/drawing1.xml');
      expect(drawing, contains('<xdr:col>1</xdr:col>'));
      expect(drawing, contains('<xdr:col>2</xdr:col>'));
      expect(drawing, contains('r:embed="rId2"'));
      expect(
        part('xl/drawings/_rels/drawing1.xml.rels'),
        contains('../media/image2.jpg'),
      );
      expect(sheet, isNot(contains('<f>')));
    },
  );
}
