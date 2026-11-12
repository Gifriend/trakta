import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/photo_edits.dart';
part 'photo_editor_state.freezed.dart';

@freezed
abstract class PhotoEditorState with _$PhotoEditorState {
  const factory PhotoEditorState({
    @Default(0) int turns,
    @Default(false) bool square,
    @Default('none') String frame,
    @Default('') String caption,
    @Default(<PhotoSticker>[]) List<PhotoSticker> stickers,
    int? selectedSticker,
    Uint8List? preview,
    @Default(false) bool busy,
    String? error,
  }) = _PhotoEditorState;
}
