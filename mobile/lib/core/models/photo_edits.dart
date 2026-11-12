class PhotoSticker {
  const PhotoSticker({
    required this.id,
    required this.text,
    this.x = .5,
    this.y = .5,
    this.size = .15,
    this.rotation = 0,
  });
  final int id;
  final String text;
  final double x, y, size, rotation;
  PhotoSticker copyWith({
    double? x,
    double? y,
    double? size,
    double? rotation,
  }) => PhotoSticker(
    id: id,
    text: text,
    x: x ?? this.x,
    y: y ?? this.y,
    size: size ?? this.size,
    rotation: rotation ?? this.rotation,
  );
}

const photoFrames = {
  'none': 'Tanpa bingkai',
  'love': 'Love',
  'stars': 'Bintang',
  'retro': 'Retro Fotobox',
};
