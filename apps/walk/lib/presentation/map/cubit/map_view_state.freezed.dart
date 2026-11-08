// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_view_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapViewState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapViewState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapViewState()';
}


}

/// @nodoc
class $MapViewStateCopyWith<$Res>  {
$MapViewStateCopyWith(MapViewState _, $Res Function(MapViewState) __);
}


/// Adds pattern-matching-related methods to [MapViewState].
extension MapViewStatePatterns on MapViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MapViewLoading value)?  loading,TResult Function( MapViewReady value)?  ready,TResult Function( MapViewEmpty value)?  empty,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MapViewLoading() when loading != null:
return loading(_that);case MapViewReady() when ready != null:
return ready(_that);case MapViewEmpty() when empty != null:
return empty(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MapViewLoading value)  loading,required TResult Function( MapViewReady value)  ready,required TResult Function( MapViewEmpty value)  empty,}){
final _that = this;
switch (_that) {
case MapViewLoading():
return loading(_that);case MapViewReady():
return ready(_that);case MapViewEmpty():
return empty(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MapViewLoading value)?  loading,TResult? Function( MapViewReady value)?  ready,TResult? Function( MapViewEmpty value)?  empty,}){
final _that = this;
switch (_that) {
case MapViewLoading() when loading != null:
return loading(_that);case MapViewReady() when ready != null:
return ready(_that);case MapViewEmpty() when empty != null:
return empty(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( MapPeriod period)?  loading,TResult Function( MapViewData data)?  ready,TResult Function( MapPeriod period)?  empty,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MapViewLoading() when loading != null:
return loading(_that.period);case MapViewReady() when ready != null:
return ready(_that.data);case MapViewEmpty() when empty != null:
return empty(_that.period);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( MapPeriod period)  loading,required TResult Function( MapViewData data)  ready,required TResult Function( MapPeriod period)  empty,}) {final _that = this;
switch (_that) {
case MapViewLoading():
return loading(_that.period);case MapViewReady():
return ready(_that.data);case MapViewEmpty():
return empty(_that.period);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( MapPeriod period)?  loading,TResult? Function( MapViewData data)?  ready,TResult? Function( MapPeriod period)?  empty,}) {final _that = this;
switch (_that) {
case MapViewLoading() when loading != null:
return loading(_that.period);case MapViewReady() when ready != null:
return ready(_that.data);case MapViewEmpty() when empty != null:
return empty(_that.period);case _:
  return null;

}
}

}

/// @nodoc


class MapViewLoading implements MapViewState {
  const MapViewLoading(this.period);
  

 final  MapPeriod period;

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapViewLoadingCopyWith<MapViewLoading> get copyWith => _$MapViewLoadingCopyWithImpl<MapViewLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapViewLoading&&(identical(other.period, period) || other.period == period));
}


@override
int get hashCode => Object.hash(runtimeType,period);

@override
String toString() {
  return 'MapViewState.loading(period: $period)';
}


}

/// @nodoc
abstract mixin class $MapViewLoadingCopyWith<$Res> implements $MapViewStateCopyWith<$Res> {
  factory $MapViewLoadingCopyWith(MapViewLoading value, $Res Function(MapViewLoading) _then) = _$MapViewLoadingCopyWithImpl;
@useResult
$Res call({
 MapPeriod period
});


$MapPeriodCopyWith<$Res> get period;

}
/// @nodoc
class _$MapViewLoadingCopyWithImpl<$Res>
    implements $MapViewLoadingCopyWith<$Res> {
  _$MapViewLoadingCopyWithImpl(this._self, this._then);

  final MapViewLoading _self;
  final $Res Function(MapViewLoading) _then;

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,}) {
  return _then(MapViewLoading(
null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as MapPeriod,
  ));
}

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapPeriodCopyWith<$Res> get period {
  
  return $MapPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}

/// @nodoc


class MapViewReady implements MapViewState {
  const MapViewReady(this.data);
  

 final  MapViewData data;

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapViewReadyCopyWith<MapViewReady> get copyWith => _$MapViewReadyCopyWithImpl<MapViewReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapViewReady&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'MapViewState.ready(data: $data)';
}


}

/// @nodoc
abstract mixin class $MapViewReadyCopyWith<$Res> implements $MapViewStateCopyWith<$Res> {
  factory $MapViewReadyCopyWith(MapViewReady value, $Res Function(MapViewReady) _then) = _$MapViewReadyCopyWithImpl;
@useResult
$Res call({
 MapViewData data
});


$MapViewDataCopyWith<$Res> get data;

}
/// @nodoc
class _$MapViewReadyCopyWithImpl<$Res>
    implements $MapViewReadyCopyWith<$Res> {
  _$MapViewReadyCopyWithImpl(this._self, this._then);

  final MapViewReady _self;
  final $Res Function(MapViewReady) _then;

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(MapViewReady(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as MapViewData,
  ));
}

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapViewDataCopyWith<$Res> get data {
  
  return $MapViewDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc


class MapViewEmpty implements MapViewState {
  const MapViewEmpty(this.period);
  

 final  MapPeriod period;

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapViewEmptyCopyWith<MapViewEmpty> get copyWith => _$MapViewEmptyCopyWithImpl<MapViewEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapViewEmpty&&(identical(other.period, period) || other.period == period));
}


@override
int get hashCode => Object.hash(runtimeType,period);

@override
String toString() {
  return 'MapViewState.empty(period: $period)';
}


}

/// @nodoc
abstract mixin class $MapViewEmptyCopyWith<$Res> implements $MapViewStateCopyWith<$Res> {
  factory $MapViewEmptyCopyWith(MapViewEmpty value, $Res Function(MapViewEmpty) _then) = _$MapViewEmptyCopyWithImpl;
@useResult
$Res call({
 MapPeriod period
});


$MapPeriodCopyWith<$Res> get period;

}
/// @nodoc
class _$MapViewEmptyCopyWithImpl<$Res>
    implements $MapViewEmptyCopyWith<$Res> {
  _$MapViewEmptyCopyWithImpl(this._self, this._then);

  final MapViewEmpty _self;
  final $Res Function(MapViewEmpty) _then;

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? period = null,}) {
  return _then(MapViewEmpty(
null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as MapPeriod,
  ));
}

/// Create a copy of MapViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapPeriodCopyWith<$Res> get period {
  
  return $MapPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}

/// @nodoc
mixin _$MapViewData {

 MapPeriod get period; DayTrack get track; List<FrequentPlace> get frequent; List<DiaryEntry> get entries; Map<String, String> get stayNames;
/// Create a copy of MapViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapViewDataCopyWith<MapViewData> get copyWith => _$MapViewDataCopyWithImpl<MapViewData>(this as MapViewData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapViewData&&(identical(other.period, period) || other.period == period)&&(identical(other.track, track) || other.track == track)&&const DeepCollectionEquality().equals(other.frequent, frequent)&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.stayNames, stayNames));
}


@override
int get hashCode => Object.hash(runtimeType,period,track,const DeepCollectionEquality().hash(frequent),const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(stayNames));

@override
String toString() {
  return 'MapViewData(period: $period, track: $track, frequent: $frequent, entries: $entries, stayNames: $stayNames)';
}


}

/// @nodoc
abstract mixin class $MapViewDataCopyWith<$Res>  {
  factory $MapViewDataCopyWith(MapViewData value, $Res Function(MapViewData) _then) = _$MapViewDataCopyWithImpl;
@useResult
$Res call({
 MapPeriod period, DayTrack track, List<FrequentPlace> frequent, List<DiaryEntry> entries, Map<String, String> stayNames
});




}
/// @nodoc
class _$MapViewDataCopyWithImpl<$Res>
    implements $MapViewDataCopyWith<$Res> {
  _$MapViewDataCopyWithImpl(this._self, this._then);

  final MapViewData _self;
  final $Res Function(MapViewData) _then;

/// Create a copy of MapViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? track = null,Object? frequent = null,Object? entries = null,Object? stayNames = null,}) {
  return _then(MapViewData(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as MapPeriod,track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as DayTrack,frequent: null == frequent ? _self.frequent : frequent // ignore: cast_nullable_to_non_nullable
as List<FrequentPlace>,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<DiaryEntry>,stayNames: null == stayNames ? _self.stayNames : stayNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MapViewData].
extension MapViewDataPatterns on MapViewData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
