import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_error.dart';

class CameraRepository {
  CameraController? controller;
  Future<void> open({bool front = true}) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw const AppException('Kamera tidak tersedia.');
    final selected =
        cameras
            .where(
              (camera) =>
                  camera.lensDirection ==
                  (front
                      ? CameraLensDirection.front
                      : CameraLensDirection.back),
            )
            .firstOrNull ??
        cameras.first;
    final next = CameraController(
      selected,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await next.initialize();
      controller = next;
    } catch (_) {
      await next.dispose();
      rethrow;
    }
  }

  Future<Uint8List> capture() async {
    final camera = controller;
    if (camera == null || !camera.value.isInitialized) {
      throw const AppException('Kamera belum siap.');
    }
    return (await camera.takePicture()).readAsBytes();
  }

  Future<Uint8List?> gallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    if (await file.length() > 20 * 1024 * 1024) {
      throw const AppException('Pilih foto maksimal 20 MB.');
    }
    return file.readAsBytes();
  }

  Future<void> close() async {
    final old = controller;
    controller = null;
    await old?.dispose();
  }
}
