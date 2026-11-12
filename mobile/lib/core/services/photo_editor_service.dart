import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/photo_edits.dart';
import 'photo_service.dart';

class PhotoEditorService {
  const PhotoEditorService();
  Future<Uint8List> render(
    Uint8List original, {
    int turns = 0,
    bool square = false,
    String frame = 'none',
    String caption = '',
    List<PhotoSticker> stickers = const [],
  }) async {
    final transformed = await const PhotoService().prepare(
      original,
      turns: turns,
      square: square,
    );
    final codec = await ui.instantiateImageCodec(transformed);
    final photo = (await codec.getNextFrame()).image;
    codec.dispose();
    final size = Size(photo.width.toDouble(), photo.height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(photo, Offset.zero, Paint());
    final unit = math.min(size.width, size.height);
    if (frame == 'retro') {
      final paint = Paint()
        ..color = const Color(0xfffff1d8)
        ..strokeWidth = unit * .05
        ..style = PaintingStyle.stroke;
      canvas.drawRect(Offset.zero & size, paint);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - unit * .12, size.width, unit * .12),
        Paint()..color = const Color(0xfffff1d8),
      );
      _text(
        canvas,
        'TRAKTA',
        Offset(size.width / 2, size.height - unit * .06),
        unit * .035,
        const Color(0xff70462f),
        size.width,
      );
    } else if (frame == 'love' || frame == 'stars') {
      for (final point in [
        Offset(unit * .1, unit * .1),
        Offset(size.width - unit * .1, size.height - unit * .1),
      ]) {
        _text(
          canvas,
          frame == 'love' ? '♥' : '✦',
          point,
          unit * .15,
          Color(frame == 'love' ? 0xffff7699 : 0xffffdc82),
          unit * .3,
        );
      }
    }
    for (final sticker in stickers) {
      canvas.save();
      canvas.translate(size.width * sticker.x, size.height * sticker.y);
      canvas.rotate(sticker.rotation * math.pi / 180);
      _text(
        canvas,
        sticker.text,
        Offset.zero,
        unit * sticker.size,
        Colors.white,
        size.width * .9,
      );
      canvas.restore();
    }
    if (caption.trim().isNotEmpty) {
      final painter = TextPainter(
        text: TextSpan(
          text: caption.trim(),
          style: TextStyle(
            fontSize: unit * .045,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.width * .85);
      final y = size.height - painter.height - unit * .08;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            unit * .04,
            y - unit * .025,
            size.width - unit * .08,
            painter.height + unit * .05,
          ),
          Radius.circular(unit * .025),
        ),
        Paint()..color = const Color(0xb3000000),
      );
      painter.paint(canvas, Offset((size.width - painter.width) / 2, y));
      painter.dispose();
    }
    final picture = recorder.endRecording();
    final output = await picture.toImage(photo.width, photo.height);
    final png = (await output.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    photo.dispose();
    output.dispose();
    picture.dispose();
    return const PhotoService().compress(png);
  }

  static void _text(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  Future<Uint8List> compose(
    List<Uint8List> photos, {
    required bool grid,
    required Color color,
  }) async {
    final images = <ui.Image>[];
    try {
      for (final bytes in photos) {
        final codec = await ui.instantiateImageCodec(bytes);
        images.add((await codec.getNextFrame()).image);
        codec.dispose();
      }
      final columns = grid ? 2 : 1;
      final rows = (images.length / columns).ceil();
      final width = columns * 480 + (columns + 1) * 24;
      final height = rows * 360 + (rows + 1) * 24 + 52;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..drawColor(color, BlendMode.src);
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final input = Size(image.width.toDouble(), image.height.toDouble());
        final fitting = applyBoxFit(BoxFit.cover, input, const Size(480, 360));
        final source = Alignment.center.inscribe(
          fitting.source,
          Offset.zero & input,
        );
        canvas.drawImageRect(
          image,
          source,
          Rect.fromLTWH(
            (24 + (i % columns) * 504).toDouble(),
            (24 + (i ~/ columns) * 384).toDouble(),
            480,
            360,
          ),
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
      _text(
        canvas,
        'TRAKTA',
        Offset(width / 2, height - 26),
        22,
        const Color(0xff124e43),
        width.toDouble(),
      );
      final picture = recorder.endRecording();
      final output = await picture.toImage(width, height);
      final bytes = (await output.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      output.dispose();
      picture.dispose();
      return const PhotoService().compress(bytes);
    } finally {
      for (final image in images) {
        image.dispose();
      }
    }
  }
}
