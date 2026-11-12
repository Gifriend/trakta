import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

abstract final class FileShareService {
  static Future<void> share(
    Uint8List bytes, {
    required String name,
    required String mimeType,
    required Rect origin,
  }) async {
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: mimeType, name: name)],
      fileNameOverrides: [name],
      sharePositionOrigin: origin,
    );
  }

  static Rect origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
  }
}
