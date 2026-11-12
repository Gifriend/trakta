import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../utils/app_error.dart';

const cameraEffects = <String, String>{
  'natural': 'Natural',
  'bright': 'Terang',
  'mono': 'Hitam putih',
  'sepia': 'Sepia',
  'vivid': 'Warna hidup',
  'contrast': 'Kontras tinggi',
  'soft': 'Lembut',
  'lowLight': 'Cahaya rendah',
  'muted': 'Warna redup',
  'negative': 'Negatif',
};
List<double> effectMatrix(String effect) {
  final amount = switch (effect) {
    'bright' => 1.18,
    'lowLight' => 1.4,
    'contrast' => 1.3,
    'soft' => .8,
    'negative' => -1.0,
    _ => 1.0,
  };
  final offset = effect == 'negative'
      ? 255.0
      : ['contrast', 'soft'].contains(effect)
      ? 127.5 * (1 - amount)
      : 0.0;
  if (effect == 'mono') {
    return [
      .2126,
      .7152,
      .0722,
      0,
      0,
      .2126,
      .7152,
      .0722,
      0,
      0,
      .2126,
      .7152,
      .0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
  if (effect == 'sepia') {
    return [
      .393,
      .769,
      .189,
      0,
      0,
      .349,
      .686,
      .168,
      0,
      0,
      .272,
      .534,
      .131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
  if (effect == 'vivid' || effect == 'muted') {
    final saturation = effect == 'vivid' ? 1.45 : .55;
    final r = .213 * (1 - saturation),
        g = .715 * (1 - saturation),
        b = .072 * (1 - saturation);
    return [
      r + saturation,
      g,
      b,
      0,
      0,
      r,
      g + saturation,
      b,
      0,
      0,
      r,
      g,
      b + saturation,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
  return [
    amount,
    0,
    0,
    0,
    offset,
    0,
    amount,
    0,
    0,
    offset,
    0,
    0,
    amount,
    0,
    offset,
    0,
    0,
    0,
    1,
    0,
  ];
}

class PhotoService {
  const PhotoService();
  Future<Uint8List> prepare(
    Uint8List bytes, {
    String effect = 'natural',
    bool mirror = false,
    int turns = 0,
    bool square = false,
  }) => compute(_prepare, (
    bytes: bytes,
    effect: effect,
    mirror: mirror,
    turns: turns,
    square: square,
  ));
  Future<Uint8List> compress(Uint8List bytes) => prepare(bytes);
}

typedef PhotoJob = ({
  Uint8List bytes,
  String effect,
  bool mirror,
  int turns,
  bool square,
});
Uint8List _prepare(PhotoJob job) {
  if (job.bytes.isEmpty || job.bytes.length > 20 * 1024 * 1024) {
    throw const AppException('Pilih foto maksimal 20 MB.');
  }
  final decoder = img.findDecoderForData(job.bytes);
  if (decoder is! img.JpegDecoder &&
      decoder is! img.PngDecoder &&
      decoder is! img.WebPDecoder) {
    throw const AppException('Gunakan foto JPG, PNG, atau WebP.');
  }
  final info = decoder!.startDecode(job.bytes);
  if (info == null || info.width * info.height > 60000000) {
    throw const AppException(
      'Resolusi foto terlalu besar. Pilih foto yang lebih kecil.',
    );
  }
  final decoded = decoder.decodeFrame(0);
  if (decoded == null) {
    throw const AppException('Foto gagal diproses. Coba foto lain.');
  }
  var image = img.bakeOrientation(decoded);
  if (image.width > 1600 || image.height > 1600) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 1600 : null,
      height: image.height > image.width ? 1600 : null,
    );
  }
  if (job.mirror) image = img.flipHorizontal(image);
  if (job.square) {
    final edge = image.width < image.height ? image.width : image.height;
    image = img.copyCrop(
      image,
      x: (image.width - edge) ~/ 2,
      y: (image.height - edge) ~/ 2,
      width: edge,
      height: edge,
    );
  }
  if (job.turns % 4 != 0) {
    image = img.copyRotate(image, angle: 90 * (job.turns % 4));
  }
  if (job.effect != 'natural') {
    final matrix = effectMatrix(job.effect);
    for (final pixel in image) {
      final r = pixel.r, g = pixel.g, b = pixel.b;
      pixel.r = (r * matrix[0] + g * matrix[1] + b * matrix[2] + matrix[4])
          .clamp(0, 255);
      pixel.g = (r * matrix[5] + g * matrix[6] + b * matrix[7] + matrix[9])
          .clamp(0, 255);
      pixel.b = (r * matrix[10] + g * matrix[11] + b * matrix[12] + matrix[14])
          .clamp(0, 255);
    }
  }
  // Flatten transparency and strip EXIF (including embedded GPS).
  final flattened = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 3,
  );
  img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
  image = img.compositeImage(flattened, image);
  for (var edge = 1600; edge >= 160; edge = (edge * .78).floor()) {
    if (image.width > edge || image.height > edge) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? edge : null,
        height: image.height > image.width ? edge : null,
      );
    }
    for (final quality in [88, 75, 60, 45, 30]) {
      final encoded = img.encodeJpg(image, quality: quality);
      if (encoded.length <= 100000) return encoded;
    }
  }
  throw const AppException(
    'Foto belum dapat dikompresi menjadi 100 KB. Coba foto lain.',
  );
}
