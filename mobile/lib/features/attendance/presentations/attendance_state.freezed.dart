// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AttendanceState {

 WorkMode get mode; String get note; CapturedPhoto? get photo; bool get busy; bool get saved; String? get error;
/// Create a copy of AttendanceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceStateCopyWith<AttendanceState> get copyWith => _$AttendanceStateCopyWithImpl<AttendanceState>(this as AttendanceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceState&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.note, note) || other.note == note)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,mode,note,photo,busy,saved,error);

@override
String toString() {
  return 'AttendanceState(mode: $mode, note: $note, photo: $photo, busy: $busy, saved: $saved, error: $error)';
}


}

/// @nodoc
abstract mixin class $AttendanceStateCopyWith<$Res>  {
  factory $AttendanceStateCopyWith(AttendanceState value, $Res Function(AttendanceState) _then) = _$AttendanceStateCopyWithImpl;
@useResult
$Res call({
 WorkMode mode, String note, CapturedPhoto? photo, bool busy, bool saved, String? error
});




}
/// @nodoc
class _$AttendanceStateCopyWithImpl<$Res>
    implements $AttendanceStateCopyWith<$Res> {
  _$AttendanceStateCopyWithImpl(this._self, this._then);

  final AttendanceState _self;
  final $Res Function(AttendanceState) _then;

/// Create a copy of AttendanceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? note = null,Object? photo = freezed,Object? busy = null,Object? saved = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as WorkMode,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as CapturedPhoto?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceState].
extension AttendanceStatePatterns on AttendanceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceState value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceState value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkMode mode,  String note,  CapturedPhoto? photo,  bool busy,  bool saved,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceState() when $default != null:
return $default(_that.mode,_that.note,_that.photo,_that.busy,_that.saved,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkMode mode,  String note,  CapturedPhoto? photo,  bool busy,  bool saved,  String? error)  $default,) {final _that = this;
switch (_that) {
case _AttendanceState():
return $default(_that.mode,_that.note,_that.photo,_that.busy,_that.saved,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkMode mode,  String note,  CapturedPhoto? photo,  bool busy,  bool saved,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceState() when $default != null:
return $default(_that.mode,_that.note,_that.photo,_that.busy,_that.saved,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _AttendanceState implements AttendanceState {
  const _AttendanceState({this.mode = WorkMode.office, this.note = '', this.photo, this.busy = false, this.saved = false, this.error});
  

@override@JsonKey() final  WorkMode mode;
@override@JsonKey() final  String note;
@override final  CapturedPhoto? photo;
@override@JsonKey() final  bool busy;
@override@JsonKey() final  bool saved;
@override final  String? error;

/// Create a copy of AttendanceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceStateCopyWith<_AttendanceState> get copyWith => __$AttendanceStateCopyWithImpl<_AttendanceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceState&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.note, note) || other.note == note)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,mode,note,photo,busy,saved,error);

@override
String toString() {
  return 'AttendanceState(mode: $mode, note: $note, photo: $photo, busy: $busy, saved: $saved, error: $error)';
}


}

/// @nodoc
abstract mixin class _$AttendanceStateCopyWith<$Res> implements $AttendanceStateCopyWith<$Res> {
  factory _$AttendanceStateCopyWith(_AttendanceState value, $Res Function(_AttendanceState) _then) = __$AttendanceStateCopyWithImpl;
@override @useResult
$Res call({
 WorkMode mode, String note, CapturedPhoto? photo, bool busy, bool saved, String? error
});




}
/// @nodoc
class __$AttendanceStateCopyWithImpl<$Res>
    implements _$AttendanceStateCopyWith<$Res> {
  __$AttendanceStateCopyWithImpl(this._self, this._then);

  final _AttendanceState _self;
  final $Res Function(_AttendanceState) _then;

/// Create a copy of AttendanceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? note = null,Object? photo = freezed,Object? busy = null,Object? saved = null,Object? error = freezed,}) {
  return _then(_AttendanceState(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as WorkMode,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as CapturedPhoto?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
