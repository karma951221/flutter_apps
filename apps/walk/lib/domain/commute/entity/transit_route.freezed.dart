// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteLeg {

 int get minutes;
/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteLegCopyWith<RouteLeg> get copyWith => _$RouteLegCopyWithImpl<RouteLeg>(this as RouteLeg, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteLeg&&(identical(other.minutes, minutes) || other.minutes == minutes));
}


@override
int get hashCode => Object.hash(runtimeType,minutes);

@override
String toString() {
  return 'RouteLeg(minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class $RouteLegCopyWith<$Res>  {
  factory $RouteLegCopyWith(RouteLeg value, $Res Function(RouteLeg) _then) = _$RouteLegCopyWithImpl;
@useResult
$Res call({
 int minutes
});




}
/// @nodoc
class _$RouteLegCopyWithImpl<$Res>
    implements $RouteLegCopyWith<$Res> {
  _$RouteLegCopyWithImpl(this._self, this._then);

  final RouteLeg _self;
  final $Res Function(RouteLeg) _then;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minutes = null,}) {
  return _then(_self.copyWith(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteLeg].
extension RouteLegPatterns on RouteLeg {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WalkLeg value)?  walk,TResult Function( SubwayLeg value)?  subway,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WalkLeg() when walk != null:
return walk(_that);case SubwayLeg() when subway != null:
return subway(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WalkLeg value)  walk,required TResult Function( SubwayLeg value)  subway,}){
final _that = this;
switch (_that) {
case WalkLeg():
return walk(_that);case SubwayLeg():
return subway(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WalkLeg value)?  walk,TResult? Function( SubwayLeg value)?  subway,}){
final _that = this;
switch (_that) {
case WalkLeg() when walk != null:
return walk(_that);case SubwayLeg() when subway != null:
return subway(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int minutes)?  walk,TResult Function( int minutes,  String lineName,  int odsayLaneCode,  String startStation,  String endStation,  int wayCode,  String wayName,  int stationCount)?  subway,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WalkLeg() when walk != null:
return walk(_that.minutes);case SubwayLeg() when subway != null:
return subway(_that.minutes,_that.lineName,_that.odsayLaneCode,_that.startStation,_that.endStation,_that.wayCode,_that.wayName,_that.stationCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int minutes)  walk,required TResult Function( int minutes,  String lineName,  int odsayLaneCode,  String startStation,  String endStation,  int wayCode,  String wayName,  int stationCount)  subway,}) {final _that = this;
switch (_that) {
case WalkLeg():
return walk(_that.minutes);case SubwayLeg():
return subway(_that.minutes,_that.lineName,_that.odsayLaneCode,_that.startStation,_that.endStation,_that.wayCode,_that.wayName,_that.stationCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int minutes)?  walk,TResult? Function( int minutes,  String lineName,  int odsayLaneCode,  String startStation,  String endStation,  int wayCode,  String wayName,  int stationCount)?  subway,}) {final _that = this;
switch (_that) {
case WalkLeg() when walk != null:
return walk(_that.minutes);case SubwayLeg() when subway != null:
return subway(_that.minutes,_that.lineName,_that.odsayLaneCode,_that.startStation,_that.endStation,_that.wayCode,_that.wayName,_that.stationCount);case _:
  return null;

}
}

}

/// @nodoc


class WalkLeg implements RouteLeg {
  const WalkLeg({required this.minutes});
  

@override final  int minutes;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkLegCopyWith<WalkLeg> get copyWith => _$WalkLegCopyWithImpl<WalkLeg>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkLeg&&(identical(other.minutes, minutes) || other.minutes == minutes));
}


@override
int get hashCode => Object.hash(runtimeType,minutes);

@override
String toString() {
  return 'RouteLeg.walk(minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class $WalkLegCopyWith<$Res> implements $RouteLegCopyWith<$Res> {
  factory $WalkLegCopyWith(WalkLeg value, $Res Function(WalkLeg) _then) = _$WalkLegCopyWithImpl;
@override @useResult
$Res call({
 int minutes
});




}
/// @nodoc
class _$WalkLegCopyWithImpl<$Res>
    implements $WalkLegCopyWith<$Res> {
  _$WalkLegCopyWithImpl(this._self, this._then);

  final WalkLeg _self;
  final $Res Function(WalkLeg) _then;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minutes = null,}) {
  return _then(WalkLeg(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SubwayLeg implements RouteLeg {
  const SubwayLeg({required this.minutes, required this.lineName, required this.odsayLaneCode, required this.startStation, required this.endStation, required this.wayCode, required this.wayName, required this.stationCount});
  

@override final  int minutes;
 final  String lineName;
 final  int odsayLaneCode;
 final  String startStation;
 final  String endStation;
 final  int wayCode;
 final  String wayName;
 final  int stationCount;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubwayLegCopyWith<SubwayLeg> get copyWith => _$SubwayLegCopyWithImpl<SubwayLeg>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubwayLeg&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.lineName, lineName) || other.lineName == lineName)&&(identical(other.odsayLaneCode, odsayLaneCode) || other.odsayLaneCode == odsayLaneCode)&&(identical(other.startStation, startStation) || other.startStation == startStation)&&(identical(other.endStation, endStation) || other.endStation == endStation)&&(identical(other.wayCode, wayCode) || other.wayCode == wayCode)&&(identical(other.wayName, wayName) || other.wayName == wayName)&&(identical(other.stationCount, stationCount) || other.stationCount == stationCount));
}


@override
int get hashCode => Object.hash(runtimeType,minutes,lineName,odsayLaneCode,startStation,endStation,wayCode,wayName,stationCount);

@override
String toString() {
  return 'RouteLeg.subway(minutes: $minutes, lineName: $lineName, odsayLaneCode: $odsayLaneCode, startStation: $startStation, endStation: $endStation, wayCode: $wayCode, wayName: $wayName, stationCount: $stationCount)';
}


}

/// @nodoc
abstract mixin class $SubwayLegCopyWith<$Res> implements $RouteLegCopyWith<$Res> {
  factory $SubwayLegCopyWith(SubwayLeg value, $Res Function(SubwayLeg) _then) = _$SubwayLegCopyWithImpl;
@override @useResult
$Res call({
 int minutes, String lineName, int odsayLaneCode, String startStation, String endStation, int wayCode, String wayName, int stationCount
});




}
/// @nodoc
class _$SubwayLegCopyWithImpl<$Res>
    implements $SubwayLegCopyWith<$Res> {
  _$SubwayLegCopyWithImpl(this._self, this._then);

  final SubwayLeg _self;
  final $Res Function(SubwayLeg) _then;

/// Create a copy of RouteLeg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minutes = null,Object? lineName = null,Object? odsayLaneCode = null,Object? startStation = null,Object? endStation = null,Object? wayCode = null,Object? wayName = null,Object? stationCount = null,}) {
  return _then(SubwayLeg(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,lineName: null == lineName ? _self.lineName : lineName // ignore: cast_nullable_to_non_nullable
as String,odsayLaneCode: null == odsayLaneCode ? _self.odsayLaneCode : odsayLaneCode // ignore: cast_nullable_to_non_nullable
as int,startStation: null == startStation ? _self.startStation : startStation // ignore: cast_nullable_to_non_nullable
as String,endStation: null == endStation ? _self.endStation : endStation // ignore: cast_nullable_to_non_nullable
as String,wayCode: null == wayCode ? _self.wayCode : wayCode // ignore: cast_nullable_to_non_nullable
as int,wayName: null == wayName ? _self.wayName : wayName // ignore: cast_nullable_to_non_nullable
as String,stationCount: null == stationCount ? _self.stationCount : stationCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TransitRoute {

 int get totalMinutes; int get transferCount; List<RouteLeg> get legs;
/// Create a copy of TransitRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitRouteCopyWith<TransitRoute> get copyWith => _$TransitRouteCopyWithImpl<TransitRoute>(this as TransitRoute, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitRoute&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.transferCount, transferCount) || other.transferCount == transferCount)&&const DeepCollectionEquality().equals(other.legs, legs));
}


@override
int get hashCode => Object.hash(runtimeType,totalMinutes,transferCount,const DeepCollectionEquality().hash(legs));

@override
String toString() {
  return 'TransitRoute(totalMinutes: $totalMinutes, transferCount: $transferCount, legs: $legs)';
}


}

/// @nodoc
abstract mixin class $TransitRouteCopyWith<$Res>  {
  factory $TransitRouteCopyWith(TransitRoute value, $Res Function(TransitRoute) _then) = _$TransitRouteCopyWithImpl;
@useResult
$Res call({
 int totalMinutes, int transferCount, List<RouteLeg> legs
});




}
/// @nodoc
class _$TransitRouteCopyWithImpl<$Res>
    implements $TransitRouteCopyWith<$Res> {
  _$TransitRouteCopyWithImpl(this._self, this._then);

  final TransitRoute _self;
  final $Res Function(TransitRoute) _then;

/// Create a copy of TransitRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalMinutes = null,Object? transferCount = null,Object? legs = null,}) {
  return _then(TransitRoute(
totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,transferCount: null == transferCount ? _self.transferCount : transferCount // ignore: cast_nullable_to_non_nullable
as int,legs: null == legs ? _self.legs : legs // ignore: cast_nullable_to_non_nullable
as List<RouteLeg>,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitRoute].
extension TransitRoutePatterns on TransitRoute {
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
