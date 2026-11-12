import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/photo_editor_service.dart';
import '../../../core/utils/app_error.dart';
import 'booth_state.dart';

final boothControllerProvider =
    StateNotifierProvider.autoDispose<BoothController, BoothState>(
      (ref) => BoothController(),
    );

class BoothController extends StateNotifier<BoothState> {
  BoothController() : super(const BoothState());
  void configure(BoothState next) {
    if (!state.busy) state = next.copyWith(collage: null, error: null);
  }

  void addPhoto(Uint8List photo, {int? index}) {
    final photos = [...state.photos];
    if (index != null) {
      photos[index] = photo;
    } else if (photos.length < state.count) {
      photos.add(photo);
    }
    configure(state.copyWith(photos: photos));
  }

  void edited(Uint8List photo) => state = state.copyWith(collage: photo);
  void reset() => state = BoothState(
    count: state.count,
    grid: state.grid,
    timer: state.timer,
    color: state.color,
  );
  Future<void> compose() async {
    if (state.busy || state.photos.length != state.count) return;
    state = state.copyWith(busy: true, error: null);
    try {
      final bytes = await const PhotoEditorService().compose(
        state.photos,
        grid: state.grid,
        color: Color(state.color),
      );
      if (mounted) state = state.copyWith(collage: bytes, busy: false);
    } catch (error) {
      if (mounted) {
        state = state.copyWith(busy: false, error: friendlyError(error));
      }
    }
  }
}
