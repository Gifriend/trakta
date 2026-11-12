import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trakta_mobile/core/models/photo_edits.dart';
import 'package:trakta_mobile/core/services/photo_editor_service.dart';

void main() {
  testWidgets(
    'editor and booth render real bounded JPEG results without changing source',
    (tester) async {
      await tester.runAsync(() async {
        await (FontLoader(
          'Inter',
        )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
        final original = img.encodeJpg(
          img.fill(
            img.Image(width: 320, height: 240),
            color: img.ColorRgb8(30, 90, 70),
          ),
        );
        final copy = Uint8List.fromList(original);
        const service = PhotoEditorService();
        final edited = await service.render(
          original,
          turns: 1,
          square: true,
          frame: 'retro',
          caption: 'Trakta',
          stickers: const [
            PhotoSticker(id: 1, text: 'OK', x: .3, y: .3, rotation: 30),
          ],
        );
        expect(edited.length, lessThanOrEqualTo(100000));
        final photo = img.decodeJpg(edited)!;
        expect(photo.width, photo.height);
        expect(photo.getPixel(5, 5).r, greaterThan(150));
        expect(original, copy);
        final strip = await service.compose(
          [original, edited, original],
          grid: false,
          color: const Color(0xfffff1d8),
        );
        final grid = await service.compose(
          [original, edited, original],
          grid: true,
          color: const Color(0xffd5f3e8),
        );
        expect(strip.length, lessThanOrEqualTo(100000));
        expect(grid.length, lessThanOrEqualTo(100000));
        final stripPhoto = img.decodeJpg(strip)!,
            gridPhoto = img.decodeJpg(grid)!;
        expect(stripPhoto.height, greaterThan(stripPhoto.width * 2));
        expect(gridPhoto.width, greaterThan(gridPhoto.height));
      });
    },
  );
}
