// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryState {

 List<AttendanceDay> get days; bool get busy; bool get hasNext; bool get exporting; bool get includePhotos; List<String?> get cursors; int get page; String? get from; String? get to; String? get error;
/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateCopyWith<HistoryState> get copyWith => _$HistoryStateCopyWithImpl<HistoryState>(this as HistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryState&&const DeepCollectionEquality().equals(other.days, days)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.exporting, exporting) || other.exporting == exporting)&&(identical(other.includePhotos, includePhotos) || other.includePhotos == includePhotos)&&const DeepCollectionEquality().equals(other.cursors, cursors)&&(identical(other.page, page) || other.page == page)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(days),busy,hasNext,exporting,includePhotos,const DeepCollectionEquality().hash(cursors),page,from,to,error);

@override
String toString() {
  return 'HistoryState(days: $days, busy: $busy, hasNext: $hasNext, exporting: $exporting, includePhotos: $includePhotos, cursors: $cursors, page: $page, from: $from, to: $to, error: $error)';
}


}

/// @nodoc
abstract mixin class $HistoryStateCopyWith<$Res>  {
  factory $HistoryStateCopyWith(HistoryState value, $Res Function(HistoryState) _then) = _$HistoryStateCopyWithImpl;
@useResult
$Res call({
 List<AttendanceDay> days, bool busy, bool hasNext, bool exporting, bool includePhotos, List<String?> cursors, int page, String? from, String? to, String? error
});




}
/// @nodoc
class _$HistoryStateCopyWithImpl<$Res>
    implements $HistoryStateCopyWith<$Res> {
  _$HistoryStateCopyWithImpl(this._self, this._then);

  final HistoryState _self;
  final $Res Function(HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? busy = null,Object? hasNext = null,Object? exporting = null,Object? includePhotos = null,Object? cursors = null,Object? page = null,Object? from = freezed,Object? to = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<AttendanceDay>,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,exporting: null == exporting ? _self.exporting : exporting // ignore: cast_nullable_to_non_nullable
as bool,includePhotos: null == includePhotos ? _self.includePhotos : includePhotos // ignore: cast_nullable_to_non_nullable
as bool,cursors: null == cursors ? _self.cursors : cursors // ignore: cast_nullable_to_non_nullable
as List<String?>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryState].
extension HistoryStatePatterns on HistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryState value)  $default,){
final _that = this;
switch (_that) {
case _HistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AttendanceDay> days,  bool busy,  bool hasNext,  bool exporting,  bool includePhotos,  List<String?> cursors,  int page,  String? from,  String? to,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.days,_that.busy,_that.hasNext,_that.exporting,_that.includePhotos,_that.cursors,_that.page,_that.from,_that.to,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AttendanceDay> days,  bool busy,  bool hasNext,  bool exporting,  bool includePhotos,  List<String?> cursors,  int page,  String? from,  String? to,  String? error)  $default,) {final _that = this;
switch (_that) {
case _HistoryState():
return $default(_that.days,_that.busy,_that.hasNext,_that.exporting,_that.includePhotos,_that.cursors,_that.page,_that.from,_that.to,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AttendanceDay> days,  bool busy,  bool hasNext,  bool exporting,  bool includePhotos,  List<String?> cursors,  int page,  String? from,  String? to,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.days,_that.busy,_that.hasNext,_that.exporting,_that.includePhotos,_that.cursors,_that.page,_that.from,_that.to,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryState implements HistoryState {
  const _HistoryState({final  List<AttendanceDay> days = const <AttendanceDay>[], this.busy = false, this.hasNext = false, this.exporting = false, this.includePhotos = false, final  List<String?> cursors = const <String?>[null], this.page = 0, this.from, this.to, this.error}): _days = days,_cursors = cursors;
  

 final  List<AttendanceDay> _days;
@override@JsonKey() List<AttendanceDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

@override@JsonKey() final  bool busy;
@override@JsonKey() final  bool hasNext;
@override@JsonKey() final  bool exporting;
@override@JsonKey() final  bool includePhotos;
 final  List<String?> _cursors;
@override@JsonKey() List<String?> get cursors {
  if (_cursors is EqualUnmodifiableListView) return _cursors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cursors);
}

@override@JsonKey() final  int page;
@override final  String? from;
@override final  String? to;
@override final  String? error;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryStateCopyWith<_HistoryState> get copyWith => __$HistoryStateCopyWithImpl<_HistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryState&&const DeepCollectionEquality().equals(other._days, _days)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.exporting, exporting) || other.exporting == exporting)&&(identical(other.includePhotos, includePhotos) || other.includePhotos == includePhotos)&&const DeepCollectionEquality().equals(other._cursors, _cursors)&&(identical(other.page, page) || other.page == page)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_days),busy,hasNext,exporting,includePhotos,const DeepCollectionEquality().hash(_cursors),page,from,to,error);

@override
String toString() {
  return 'HistoryState(days: $days, busy: $busy, hasNext: $hasNext, exporting: $exporting, includePhotos: $includePhotos, cursors: $cursors, page: $page, from: $from, to: $to, error: $error)';
}


}

/// @nodoc
abstract mixin class _$HistoryStateCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory _$HistoryStateCopyWith(_HistoryState value, $Res Function(_HistoryState) _then) = __$HistoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<AttendanceDay> days, bool busy, bool hasNext, bool exporting, bool includePhotos, List<String?> cursors, int page, String? from, String? to, String? error
});




}
/// @nodoc
class __$HistoryStateCopyWithImpl<$Res>
    implements _$HistoryStateCopyWith<$Res> {
  __$HistoryStateCopyWithImpl(this._self, this._then);

  final _HistoryState _self;
  final $Res Function(_HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? busy = null,Object? hasNext = null,Object? exporting = null,Object? includePhotos = null,Object? cursors = null,Object? page = null,Object? from = freezed,Object? to = freezed,Object? error = freezed,}) {
  return _then(_HistoryState(
days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<AttendanceDay>,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,exporting: null == exporting ? _self.exporting : exporting // ignore: cast_nullable_to_non_nullable
as bool,includePhotos: null == includePhotos ? _self.includePhotos : includePhotos // ignore: cast_nullable_to_non_nullable
as bool,cursors: null == cursors ? _self._cursors : cursors // ignore: cast_nullable_to_non_nullable
as List<String?>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
