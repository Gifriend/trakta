// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PhotoEditorState {

 int get turns; bool get square; String get frame; String get caption; List<PhotoSticker> get stickers; int? get selectedSticker; Uint8List? get preview; bool get busy; String? get error;
/// Create a copy of PhotoEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoEditorStateCopyWith<PhotoEditorState> get copyWith => _$PhotoEditorStateCopyWithImpl<PhotoEditorState>(this as PhotoEditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoEditorState&&(identical(other.turns, turns) || other.turns == turns)&&(identical(other.square, square) || other.square == square)&&(identical(other.frame, frame) || other.frame == frame)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.stickers, stickers)&&(identical(other.selectedSticker, selectedSticker) || other.selectedSticker == selectedSticker)&&const DeepCollectionEquality().equals(other.preview, preview)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,turns,square,frame,caption,const DeepCollectionEquality().hash(stickers),selectedSticker,const DeepCollectionEquality().hash(preview),busy,error);

@override
String toString() {
  return 'PhotoEditorState(turns: $turns, square: $square, frame: $frame, caption: $caption, stickers: $stickers, selectedSticker: $selectedSticker, preview: $preview, busy: $busy, error: $error)';
}


}

/// @nodoc
abstract mixin class $PhotoEditorStateCopyWith<$Res>  {
  factory $PhotoEditorStateCopyWith(PhotoEditorState value, $Res Function(PhotoEditorState) _then) = _$PhotoEditorStateCopyWithImpl;
@useResult
$Res call({
 int turns, bool square, String frame, String caption, List<PhotoSticker> stickers, int? selectedSticker, Uint8List? preview, bool busy, String? error
});




}
/// @nodoc
class _$PhotoEditorStateCopyWithImpl<$Res>
    implements $PhotoEditorStateCopyWith<$Res> {
  _$PhotoEditorStateCopyWithImpl(this._self, this._then);

  final PhotoEditorState _self;
  final $Res Function(PhotoEditorState) _then;

/// Create a copy of PhotoEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? turns = null,Object? square = null,Object? frame = null,Object? caption = null,Object? stickers = null,Object? selectedSticker = freezed,Object? preview = freezed,Object? busy = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
turns: null == turns ? _self.turns : turns // ignore: cast_nullable_to_non_nullable
as int,square: null == square ? _self.square : square // ignore: cast_nullable_to_non_nullable
as bool,frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,stickers: null == stickers ? _self.stickers : stickers // ignore: cast_nullable_to_non_nullable
as List<PhotoSticker>,selectedSticker: freezed == selectedSticker ? _self.selectedSticker : selectedSticker // ignore: cast_nullable_to_non_nullable
as int?,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as Uint8List?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PhotoEditorState].
extension PhotoEditorStatePatterns on PhotoEditorState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhotoEditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhotoEditorState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhotoEditorState value)  $default,){
final _that = this;
switch (_that) {
case _PhotoEditorState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhotoEditorState value)?  $default,){
final _that = this;
switch (_that) {
case _PhotoEditorState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int turns,  bool square,  String frame,  String caption,  List<PhotoSticker> stickers,  int? selectedSticker,  Uint8List? preview,  bool busy,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhotoEditorState() when $default != null:
return $default(_that.turns,_that.square,_that.frame,_that.caption,_that.stickers,_that.selectedSticker,_that.preview,_that.busy,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int turns,  bool square,  String frame,  String caption,  List<PhotoSticker> stickers,  int? selectedSticker,  Uint8List? preview,  bool busy,  String? error)  $default,) {final _that = this;
switch (_that) {
case _PhotoEditorState():
return $default(_that.turns,_that.square,_that.frame,_that.caption,_that.stickers,_that.selectedSticker,_that.preview,_that.busy,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int turns,  bool square,  String frame,  String caption,  List<PhotoSticker> stickers,  int? selectedSticker,  Uint8List? preview,  bool busy,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _PhotoEditorState() when $default != null:
return $default(_that.turns,_that.square,_that.frame,_that.caption,_that.stickers,_that.selectedSticker,_that.preview,_that.busy,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _PhotoEditorState implements PhotoEditorState {
  const _PhotoEditorState({this.turns = 0, this.square = false, this.frame = 'none', this.caption = '', final  List<PhotoSticker> stickers = const <PhotoSticker>[], this.selectedSticker, this.preview, this.busy = false, this.error}): _stickers = stickers;
  

@override@JsonKey() final  int turns;
@override@JsonKey() final  bool square;
@override@JsonKey() final  String frame;
@override@JsonKey() final  String caption;
 final  List<PhotoSticker> _stickers;
@override@JsonKey() List<PhotoSticker> get stickers {
  if (_stickers is EqualUnmodifiableListView) return _stickers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stickers);
}

@override final  int? selectedSticker;
@override final  Uint8List? preview;
@override@JsonKey() final  bool busy;
@override final  String? error;

/// Create a copy of PhotoEditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoEditorStateCopyWith<_PhotoEditorState> get copyWith => __$PhotoEditorStateCopyWithImpl<_PhotoEditorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoEditorState&&(identical(other.turns, turns) || other.turns == turns)&&(identical(other.square, square) || other.square == square)&&(identical(other.frame, frame) || other.frame == frame)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other._stickers, _stickers)&&(identical(other.selectedSticker, selectedSticker) || other.selectedSticker == selectedSticker)&&const DeepCollectionEquality().equals(other.preview, preview)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,turns,square,frame,caption,const DeepCollectionEquality().hash(_stickers),selectedSticker,const DeepCollectionEquality().hash(preview),busy,error);

@override
String toString() {
  return 'PhotoEditorState(turns: $turns, square: $square, frame: $frame, caption: $caption, stickers: $stickers, selectedSticker: $selectedSticker, preview: $preview, busy: $busy, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PhotoEditorStateCopyWith<$Res> implements $PhotoEditorStateCopyWith<$Res> {
  factory _$PhotoEditorStateCopyWith(_PhotoEditorState value, $Res Function(_PhotoEditorState) _then) = __$PhotoEditorStateCopyWithImpl;
@override @useResult
$Res call({
 int turns, bool square, String frame, String caption, List<PhotoSticker> stickers, int? selectedSticker, Uint8List? preview, bool busy, String? error
});




}
/// @nodoc
class __$PhotoEditorStateCopyWithImpl<$Res>
    implements _$PhotoEditorStateCopyWith<$Res> {
  __$PhotoEditorStateCopyWithImpl(this._self, this._then);

  final _PhotoEditorState _self;
  final $Res Function(_PhotoEditorState) _then;

/// Create a copy of PhotoEditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? turns = null,Object? square = null,Object? frame = null,Object? caption = null,Object? stickers = null,Object? selectedSticker = freezed,Object? preview = freezed,Object? busy = null,Object? error = freezed,}) {
  return _then(_PhotoEditorState(
turns: null == turns ? _self.turns : turns // ignore: cast_nullable_to_non_nullable
as int,square: null == square ? _self.square : square // ignore: cast_nullable_to_non_nullable
as bool,frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,stickers: null == stickers ? _self._stickers : stickers // ignore: cast_nullable_to_non_nullable
as List<PhotoSticker>,selectedSticker: freezed == selectedSticker ? _self.selectedSticker : selectedSticker // ignore: cast_nullable_to_non_nullable
as int?,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as Uint8List?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
