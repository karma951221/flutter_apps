// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'origin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Origin {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Origin);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Origin()';
}


}

/// @nodoc
class $OriginCopyWith<$Res>  {
$OriginCopyWith(Origin _, $Res Function(Origin) __);
}


/// Adds pattern-matching-related methods to [Origin].
extension OriginPatterns on Origin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CurrentLocationOrigin value)?  currentLocation,TResult Function( FallbackStationOrigin value)?  fallbackStation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CurrentLocationOrigin() when currentLocation != null:
return currentLocation(_that);case FallbackStationOrigin() when fallbackStation != null:
return fallbackStation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CurrentLocationOrigin value)  currentLocation,required TResult Function( FallbackStationOrigin value)  fallbackStation,}){
final _that = this;
switch (_that) {
case CurrentLocationOrigin():
return currentLocation(_that);case FallbackStationOrigin():
return fallbackStation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CurrentLocationOrigin value)?  currentLocation,TResult? Function( FallbackStationOrigin value)?  fallbackStation,}){
final _that = this;
switch (_that) {
case CurrentLocationOrigin() when currentLocation != null:
return currentLocation(_that);case FallbackStationOrigin() when fallbackStation != null:
return fallbackStation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( GeoPoint point)?  currentLocation,TResult Function( Station station)?  fallbackStation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CurrentLocationOrigin() when currentLocation != null:
return currentLocation(_that.point);case FallbackStationOrigin() when fallbackStation != null:
return fallbackStation(_that.station);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( GeoPoint point)  currentLocation,required TResult Function( Station station)  fallbackStation,}) {final _that = this;
switch (_that) {
case CurrentLocationOrigin():
return currentLocation(_that.point);case FallbackStationOrigin():
return fallbackStation(_that.station);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( GeoPoint point)?  currentLocation,TResult? Function( Station station)?  fallbackStation,}) {final _that = this;
switch (_that) {
case CurrentLocationOrigin() when currentLocation != null:
return currentLocation(_that.point);case FallbackStationOrigin() when fallbackStation != null:
return fallbackStation(_that.station);case _:
  return null;

}
}

}

/// @nodoc


class CurrentLocationOrigin implements Origin {
  const CurrentLocationOrigin(this.point);
  

 final  GeoPoint point;

/// Create a copy of Origin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrentLocationOriginCopyWith<CurrentLocationOrigin> get copyWith => _$CurrentLocationOriginCopyWithImpl<CurrentLocationOrigin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrentLocationOrigin&&(identical(other.point, point) || other.point == point));
}


@override
int get hashCode => Object.hash(runtimeType,point);

@override
String toString() {
  return 'Origin.currentLocation(point: $point)';
}


}

/// @nodoc
abstract mixin class $CurrentLocationOriginCopyWith<$Res> implements $OriginCopyWith<$Res> {
  factory $CurrentLocationOriginCopyWith(CurrentLocationOrigin value, $Res Function(CurrentLocationOrigin) _then) = _$CurrentLocationOriginCopyWithImpl;
@useResult
$Res call({
 GeoPoint point
});


$GeoPointCopyWith<$Res> get point;

}
/// @nodoc
class _$CurrentLocationOriginCopyWithImpl<$Res>
    implements $CurrentLocationOriginCopyWith<$Res> {
  _$CurrentLocationOriginCopyWithImpl(this._self, this._then);

  final CurrentLocationOrigin _self;
  final $Res Function(CurrentLocationOrigin) _then;

/// Create a copy of Origin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? point = null,}) {
  return _then(CurrentLocationOrigin(
null == point ? _self.point : point // ignore: cast_nullable_to_non_nullable
as GeoPoint,
  ));
}

/// Create a copy of Origin
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get point {
  
  return $GeoPointCopyWith<$Res>(_self.point, (value) {
    return _then(_self.copyWith(point: value));
  });
}
}

/// @nodoc


class FallbackStationOrigin implements Origin {
  const FallbackStationOrigin(this.station);
  

 final  Station station;

/// Create a copy of Origin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FallbackStationOriginCopyWith<FallbackStationOrigin> get copyWith => _$FallbackStationOriginCopyWithImpl<FallbackStationOrigin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FallbackStationOrigin&&(identical(other.station, station) || other.station == station));
}


@override
int get hashCode => Object.hash(runtimeType,station);

@override
String toString() {
  return 'Origin.fallbackStation(station: $station)';
}


}

/// @nodoc
abstract mixin class $FallbackStationOriginCopyWith<$Res> implements $OriginCopyWith<$Res> {
  factory $FallbackStationOriginCopyWith(FallbackStationOrigin value, $Res Function(FallbackStationOrigin) _then) = _$FallbackStationOriginCopyWithImpl;
@useResult
$Res call({
 Station station
});


$StationCopyWith<$Res> get station;

}
/// @nodoc
class _$FallbackStationOriginCopyWithImpl<$Res>
    implements $FallbackStationOriginCopyWith<$Res> {
  _$FallbackStationOriginCopyWithImpl(this._self, this._then);

  final FallbackStationOrigin _self;
  final $Res Function(FallbackStationOrigin) _then;

/// Create a copy of Origin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? station = null,}) {
  return _then(FallbackStationOrigin(
null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as Station,
  ));
}

/// Create a copy of Origin
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StationCopyWith<$Res> get station {
  
  return $StationCopyWith<$Res>(_self.station, (value) {
    return _then(_self.copyWith(station: value));
  });
}
}

// dart format on
