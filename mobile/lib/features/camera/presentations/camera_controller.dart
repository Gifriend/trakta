import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/attendance.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/photo_service.dart';
import '../../../core/utils/app_error.dart';
import '../data/repositories/camera_repository.dart';
import 'camera_state.dart';

typedef CameraRequest = ({WorkMode? mode, int timer});
final cameraControllerProvider = StateNotifierProvider.autoDispose
    .family<CaptureController, CameraState, CameraRequest>(
      (ref, request) => CaptureController(
        CameraRepository(),
        ref.watch(locationServiceProvider),
        const PhotoService(),
        request,
      ),
    );

class CaptureController extends StateNotifier<CameraState> {
  CaptureController(
    this._repository,
    this._location,
    this._photos,
    this.request,
  ) : super(const CameraState());
  final CameraRepository _repository;
  final LocationService _location;
  final PhotoService _photos;
  final CameraRequest request;
  Future<void> _queue = Future.value();
  int _generation = 0;
  CameraController? get preview => _repository.controller;
  Future<void> open({bool clearError = true}) {
    final generation = ++_generation;
    if (mounted)
      state = state.copyWith(
        ready: false,
        error: clearError ? null : state.error,
      );
    _queue = _queue.then((_) async {
      await _repository.close();
      if (!mounted || generation != _generation) return;
      try {
        await _repository.open(front: state.front);
        if (mounted && generation == _generation) {
          state = state.copyWith(ready: true);
        }
      } catch (_) {
        if (mounted && generation == _generation) {
          state = state.copyWith(
            error:
                'Kamera belum dapat dibuka. Izinkan akses kamera melalui pengaturan aplikasi.',
          );
        }
      }
    });
    return _queue;
  }

  Future<void> pause() {
    ++_generation;
    if (mounted) state = state.copyWith(ready: false, countdown: 0);
    return _queue = _queue.then((_) => _repository.close());
  }

  Future<void> flip() async {
    if (state.busy) return;
    state = state.copyWith(front: !state.front);
    await open();
  }

  Future<CapturedPhoto?> take({
    required String effect,
    required bool correctMirroring,
    bool gallery = false,
  }) async {
    if (state.busy || (!gallery && !state.ready)) return null;
    if (gallery && request.mode == WorkMode.office) return null;
    state = state.copyWith(busy: true, error: null);
    try {
      Uint8List? bytes;
      PhotoLocation? location;
      if (gallery) {
        await pause();
        bytes = await _repository.gallery();
        if (bytes == null) return null;
        if (request.mode != null) {
          location = await _location.capture(PhotoSource.gallery);
        }
      } else {
        final generation = _generation;
        for (var remaining = request.timer; remaining > 0; remaining--) {
          if (!mounted || generation != _generation) return null;
          state = state.copyWith(countdown: remaining);
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        if (!mounted || generation != _generation) return null;
        state = state.copyWith(countdown: 0);
        // Shutter and location request start together; location is never recaptured on submit.
        final photoFuture = _repository.capture();
        if (request.mode != null) {
          final results = await Future.wait<Object>([
            photoFuture,
            _location.capture(PhotoSource.camera),
          ]);
          bytes = results[0] as Uint8List;
          location = results[1] as PhotoLocation;
        } else {
          bytes = await photoFuture;
        }
      }
      if (request.mode != null && location != null) {
        final issue = LocationService.issue(location, request.mode!);
        if (issue != null) throw AppException(issue);
      }
      final result = await _photos.prepare(
        bytes,
        effect: gallery ? 'natural' : effect,
        mirror: !gallery && state.front && !correctMirroring,
      );
      await pause();
      return CapturedPhoto(result, location: location);
    } catch (error) {
      if (mounted) state = state.copyWith(error: friendlyError(error));
      return null;
    } finally {
      if (mounted) state = state.copyWith(busy: false, countdown: 0);
    }
  }

  @override
  void dispose() {
    ++_generation;
    unawaited(_queue.then((_) => _repository.close()));
    super.dispose();
  }
}
