import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/photo_edits.dart';
import '../../../core/services/photo_editor_service.dart';
import '../../../core/utils/app_error.dart';
import 'photo_editor_state.dart';

final photoEditorControllerProvider = StateNotifierProvider.autoDispose
    .family<PhotoEditorController, PhotoEditorState, Uint8List>(
      (ref, original) => PhotoEditorController(original),
    );

class PhotoEditorController extends StateNotifier<PhotoEditorState> {
  PhotoEditorController(this.original)
    : super(PhotoEditorState(preview: original));
  final Uint8List original;
  Timer? _debounce;
  int _revision = 0;
  int _nextId = 0;
  bool _rendering = false;
  void update(PhotoEditorState value) {
    state = value.copyWith(error: null, busy: true);
    _revision++;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), render);
  }

  void selectSticker(int? id) => state = state.copyWith(selectedSticker: id);
  void addSticker(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty ||
        trimmed.runes.length > 12 ||
        state.stickers.length >= 20) {
      return;
    }
    final id = _nextId++;
    update(
      state.copyWith(
        stickers: [
          ...state.stickers,
          PhotoSticker(id: id, text: trimmed),
        ],
        selectedSticker: id,
      ),
    );
  }

  void changeSticker(PhotoSticker sticker) => update(
    state.copyWith(
      stickers: state.stickers
          .map((value) => value.id == sticker.id ? sticker : value)
          .toList(),
    ),
  );
  void removeSticker() => update(
    state.copyWith(
      stickers: state.stickers
          .where((value) => value.id != state.selectedSticker)
          .toList(),
      selectedSticker: null,
    ),
  );
  Future<void> render() async {
    if (_rendering || !mounted) return;
    _rendering = true;
    final revision = _revision;
    final edits = state;
    try {
      final result = await const PhotoEditorService().render(
        original,
        turns: edits.turns,
        square: edits.square,
        frame: edits.frame,
        caption: edits.caption,
        stickers: edits.stickers,
      );
      if (mounted && revision == _revision) {
        state = state.copyWith(preview: result, busy: false);
      }
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copyWith(error: friendlyError(error), busy: false);
      }
    } finally {
      _rendering = false;
      if (mounted && revision != _revision) unawaited(render());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
