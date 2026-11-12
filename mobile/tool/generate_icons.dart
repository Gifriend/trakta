import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final source = img.decodePng(
    File('../static/icons/icon-512.png').readAsBytesSync(),
  )!;
  void save(String path, int size) {
    final image = img.copyResize(
      source,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );
    final background = img.Image(width: size, height: size, numChannels: 3);
    img.fill(background, color: img.ColorRgb8(18, 78, 67));
    img.compositeImage(background, image);
    File(path).writeAsBytesSync(img.encodePng(background));
  }

  for (final density in {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  }.entries) {
    save(
      'android/app/src/main/res/mipmap-${density.key}/ic_launcher.png',
      density.value,
    );
  }
  const directory = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final images =
      (jsonDecode(File('$directory/Contents.json').readAsStringSync())
              as Map)['images']
          as List;
  for (final entry in images.cast<Map>()) {
    final size =
        double.parse((entry['size'] as String).split('x').first) *
        double.parse((entry['scale'] as String).replaceAll('x', ''));
    save('$directory/${entry['filename']}', size.round());
  }
}
