// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BoothState {

 int get count; bool get grid; int get timer; int get color; List<Uint8List> get photos; Uint8List? get collage; bool get busy; String? get error;
/// Create a copy of BoothState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoothStateCopyWith<BoothState> get copyWith => _$BoothStateCopyWithImpl<BoothState>(this as BoothState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoothState&&(identical(other.count, count) || other.count == count)&&(identical(other.grid, grid) || other.grid == grid)&&(identical(other.timer, timer) || other.timer == timer)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.photos, photos)&&const DeepCollectionEquality().equals(other.collage, collage)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,count,grid,timer,color,const DeepCollectionEquality().hash(photos),const DeepCollectionEquality().hash(collage),busy,error);

@override
String toString() {
  return 'BoothState(count: $count, grid: $grid, timer: $timer, color: $color, photos: $photos, collage: $collage, busy: $busy, error: $error)';
}


}

/// @nodoc
abstract mixin class $BoothStateCopyWith<$Res>  {
  factory $BoothStateCopyWith(BoothState value, $Res Function(BoothState) _then) = _$BoothStateCopyWithImpl;
@useResult
$Res call({
 int count, bool grid, int timer, int color, List<Uint8List> photos, Uint8List? collage, bool busy, String? error
});




}
/// @nodoc
class _$BoothStateCopyWithImpl<$Res>
    implements $BoothStateCopyWith<$Res> {
  _$BoothStateCopyWithImpl(this._self, this._then);

  final BoothState _self;
  final $Res Function(BoothState) _then;

/// Create a copy of BoothState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? grid = null,Object? timer = null,Object? color = null,Object? photos = null,Object? collage = freezed,Object? busy = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,grid: null == grid ? _self.grid : grid // ignore: cast_nullable_to_non_nullable
as bool,timer: null == timer ? _self.timer : timer // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<Uint8List>,collage: freezed == collage ? _self.collage : collage // ignore: cast_nullable_to_non_nullable
as Uint8List?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BoothState].
extension BoothStatePatterns on BoothState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoothState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoothState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoothState value)  $default,){
final _that = this;
switch (_that) {
case _BoothState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoothState value)?  $default,){
final _that = this;
switch (_that) {
case _BoothState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  bool grid,  int timer,  int color,  List<Uint8List> photos,  Uint8List? collage,  bool busy,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoothState() when $default != null:
return $default(_that.count,_that.grid,_that.timer,_that.color,_that.photos,_that.collage,_that.busy,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  bool grid,  int timer,  int color,  List<Uint8List> photos,  Uint8List? collage,  bool busy,  String? error)  $default,) {final _that = this;
switch (_that) {
case _BoothState():
return $default(_that.count,_that.grid,_that.timer,_that.color,_that.photos,_that.collage,_that.busy,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  bool grid,  int timer,  int color,  List<Uint8List> photos,  Uint8List? collage,  bool busy,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _BoothState() when $default != null:
return $default(_that.count,_that.grid,_that.timer,_that.color,_that.photos,_that.collage,_that.busy,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _BoothState implements BoothState {
  const _BoothState({this.count = 3, this.grid = false, this.timer = 3, this.color = 0xfffff1d8, final  List<Uint8List> photos = const <Uint8List>[], this.collage, this.busy = false, this.error}): _photos = photos;
  

@override@JsonKey() final  int count;
@override@JsonKey() final  bool grid;
@override@JsonKey() final  int timer;
@override@JsonKey() final  int color;
 final  List<Uint8List> _photos;
@override@JsonKey() List<Uint8List> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  Uint8List? collage;
@override@JsonKey() final  bool busy;
@override final  String? error;

/// Create a copy of BoothState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoothStateCopyWith<_BoothState> get copyWith => __$BoothStateCopyWithImpl<_BoothState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoothState&&(identical(other.count, count) || other.count == count)&&(identical(other.grid, grid) || other.grid == grid)&&(identical(other.timer, timer) || other.timer == timer)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other._photos, _photos)&&const DeepCollectionEquality().equals(other.collage, collage)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,count,grid,timer,color,const DeepCollectionEquality().hash(_photos),const DeepCollectionEquality().hash(collage),busy,error);

@override
String toString() {
  return 'BoothState(count: $count, grid: $grid, timer: $timer, color: $color, photos: $photos, collage: $collage, busy: $busy, error: $error)';
}


}

/// @nodoc
abstract mixin class _$BoothStateCopyWith<$Res> implements $BoothStateCopyWith<$Res> {
  factory _$BoothStateCopyWith(_BoothState value, $Res Function(_BoothState) _then) = __$BoothStateCopyWithImpl;
@override @useResult
$Res call({
 int count, bool grid, int timer, int color, List<Uint8List> photos, Uint8List? collage, bool busy, String? error
});




}
/// @nodoc
class __$BoothStateCopyWithImpl<$Res>
    implements _$BoothStateCopyWith<$Res> {
  __$BoothStateCopyWithImpl(this._self, this._then);

  final _BoothState _self;
  final $Res Function(_BoothState) _then;

/// Create a copy of BoothState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? grid = null,Object? timer = null,Object? color = null,Object? photos = null,Object? collage = freezed,Object? busy = null,Object? error = freezed,}) {
  return _then(_BoothState(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,grid: null == grid ? _self.grid : grid // ignore: cast_nullable_to_non_nullable
as bool,timer: null == timer ? _self.timer : timer // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<Uint8List>,collage: freezed == collage ? _self.collage : collage // ignore: cast_nullable_to_non_nullable
as Uint8List?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
