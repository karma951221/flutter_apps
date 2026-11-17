// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit_path.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransitLeg {

 int get minutes;
/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitLegCopyWith<TransitLeg> get copyWith => _$TransitLegCopyWithImpl<TransitLeg>(this as TransitLeg, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitLeg&&(identical(other.minutes, minutes) || other.minutes == minutes));
}


@override
int get hashCode => Object.hash(runtimeType,minutes);

@override
String toString() {
  return 'TransitLeg(minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class $TransitLegCopyWith<$Res>  {
  factory $TransitLegCopyWith(TransitLeg value, $Res Function(TransitLeg) _then) = _$TransitLegCopyWithImpl;
@useResult
$Res call({
 int minutes
});




}
/// @nodoc
class _$TransitLegCopyWithImpl<$Res>
    implements $TransitLegCopyWith<$Res> {
  _$TransitLegCopyWithImpl(this._self, this._then);

  final TransitLeg _self;
  final $Res Function(TransitLeg) _then;

/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minutes = null,}) {
  return _then(_self.copyWith(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitLeg].
extension TransitLegPatterns on TransitLeg {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TransitWalkLeg value)?  walk,TResult Function( TransitSubwayLeg value)?  subway,TResult Function( TransitBusLeg value)?  bus,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TransitWalkLeg() when walk != null:
return walk(_that);case TransitSubwayLeg() when subway != null:
return subway(_that);case TransitBusLeg() when bus != null:
return bus(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TransitWalkLeg value)  walk,required TResult Function( TransitSubwayLeg value)  subway,required TResult Function( TransitBusLeg value)  bus,}){
final _that = this;
switch (_that) {
case TransitWalkLeg():
return walk(_that);case TransitSubwayLeg():
return subway(_that);case TransitBusLeg():
return bus(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TransitWalkLeg value)?  walk,TResult? Function( TransitSubwayLeg value)?  subway,TResult? Function( TransitBusLeg value)?  bus,}){
final _that = this;
switch (_that) {
case TransitWalkLeg() when walk != null:
return walk(_that);case TransitSubwayLeg() when subway != null:
return subway(_that);case TransitBusLeg() when bus != null:
return bus(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int minutes,  int distanceM)?  walk,TResult Function( int minutes,  String lineName,  int? subwayCode,  String start,  String end,  int stationCount,  String way)?  subway,TResult Function( int minutes,  List<String> busNumbers,  String start,  String end,  int stationCount)?  bus,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransitWalkLeg() when walk != null:
return walk(_that.minutes,_that.distanceM);case TransitSubwayLeg() when subway != null:
return subway(_that.minutes,_that.lineName,_that.subwayCode,_that.start,_that.end,_that.stationCount,_that.way);case TransitBusLeg() when bus != null:
return bus(_that.minutes,_that.busNumbers,_that.start,_that.end,_that.stationCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int minutes,  int distanceM)  walk,required TResult Function( int minutes,  String lineName,  int? subwayCode,  String start,  String end,  int stationCount,  String way)  subway,required TResult Function( int minutes,  List<String> busNumbers,  String start,  String end,  int stationCount)  bus,}) {final _that = this;
switch (_that) {
case TransitWalkLeg():
return walk(_that.minutes,_that.distanceM);case TransitSubwayLeg():
return subway(_that.minutes,_that.lineName,_that.subwayCode,_that.start,_that.end,_that.stationCount,_that.way);case TransitBusLeg():
return bus(_that.minutes,_that.busNumbers,_that.start,_that.end,_that.stationCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int minutes,  int distanceM)?  walk,TResult? Function( int minutes,  String lineName,  int? subwayCode,  String start,  String end,  int stationCount,  String way)?  subway,TResult? Function( int minutes,  List<String> busNumbers,  String start,  String end,  int stationCount)?  bus,}) {final _that = this;
switch (_that) {
case TransitWalkLeg() when walk != null:
return walk(_that.minutes,_that.distanceM);case TransitSubwayLeg() when subway != null:
return subway(_that.minutes,_that.lineName,_that.subwayCode,_that.start,_that.end,_that.stationCount,_that.way);case TransitBusLeg() when bus != null:
return bus(_that.minutes,_that.busNumbers,_that.start,_that.end,_that.stationCount);case _:
  return null;

}
}

}

/// @nodoc


class TransitWalkLeg implements TransitLeg {
  const TransitWalkLeg({required this.minutes, required this.distanceM});
  

@override final  int minutes;
 final  int distanceM;

/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitWalkLegCopyWith<TransitWalkLeg> get copyWith => _$TransitWalkLegCopyWithImpl<TransitWalkLeg>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitWalkLeg&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM));
}


@override
int get hashCode => Object.hash(runtimeType,minutes,distanceM);

@override
String toString() {
  return 'TransitLeg.walk(minutes: $minutes, distanceM: $distanceM)';
}


}

/// @nodoc
abstract mixin class $TransitWalkLegCopyWith<$Res> implements $TransitLegCopyWith<$Res> {
  factory $TransitWalkLegCopyWith(TransitWalkLeg value, $Res Function(TransitWalkLeg) _then) = _$TransitWalkLegCopyWithImpl;
@override @useResult
$Res call({
 int minutes, int distanceM
});




}
/// @nodoc
class _$TransitWalkLegCopyWithImpl<$Res>
    implements $TransitWalkLegCopyWith<$Res> {
  _$TransitWalkLegCopyWithImpl(this._self, this._then);

  final TransitWalkLeg _self;
  final $Res Function(TransitWalkLeg) _then;

/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minutes = null,Object? distanceM = null,}) {
  return _then(TransitWalkLeg(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class TransitSubwayLeg implements TransitLeg {
  const TransitSubwayLeg({required this.minutes, required this.lineName, this.subwayCode, required this.start, required this.end, required this.stationCount, required this.way});
  

@override final  int minutes;
 final  String lineName;
 final  int? subwayCode;
 final  String start;
 final  String end;
 final  int stationCount;
 final  String way;

/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitSubwayLegCopyWith<TransitSubwayLeg> get copyWith => _$TransitSubwayLegCopyWithImpl<TransitSubwayLeg>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitSubwayLeg&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.lineName, lineName) || other.lineName == lineName)&&(identical(other.subwayCode, subwayCode) || other.subwayCode == subwayCode)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.stationCount, stationCount) || other.stationCount == stationCount)&&(identical(other.way, way) || other.way == way));
}


@override
int get hashCode => Object.hash(runtimeType,minutes,lineName,subwayCode,start,end,stationCount,way);

@override
String toString() {
  return 'TransitLeg.subway(minutes: $minutes, lineName: $lineName, subwayCode: $subwayCode, start: $start, end: $end, stationCount: $stationCount, way: $way)';
}


}

/// @nodoc
abstract mixin class $TransitSubwayLegCopyWith<$Res> implements $TransitLegCopyWith<$Res> {
  factory $TransitSubwayLegCopyWith(TransitSubwayLeg value, $Res Function(TransitSubwayLeg) _then) = _$TransitSubwayLegCopyWithImpl;
@override @useResult
$Res call({
 int minutes, String lineName, int? subwayCode, String start, String end, int stationCount, String way
});




}
/// @nodoc
class _$TransitSubwayLegCopyWithImpl<$Res>
    implements $TransitSubwayLegCopyWith<$Res> {
  _$TransitSubwayLegCopyWithImpl(this._self, this._then);

  final TransitSubwayLeg _self;
  final $Res Function(TransitSubwayLeg) _then;

/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minutes = null,Object? lineName = null,Object? subwayCode = freezed,Object? start = null,Object? end = null,Object? stationCount = null,Object? way = null,}) {
  return _then(TransitSubwayLeg(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,lineName: null == lineName ? _self.lineName : lineName // ignore: cast_nullable_to_non_nullable
as String,subwayCode: freezed == subwayCode ? _self.subwayCode : subwayCode // ignore: cast_nullable_to_non_nullable
as int?,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,stationCount: null == stationCount ? _self.stationCount : stationCount // ignore: cast_nullable_to_non_nullable
as int,way: null == way ? _self.way : way // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransitBusLeg implements TransitLeg {
  const TransitBusLeg({required this.minutes, required final  List<String> busNumbers, required this.start, required this.end, required this.stationCount}): _busNumbers = busNumbers;
  

@override final  int minutes;
 final  List<String> _busNumbers;
 List<String> get busNumbers {
  if (_busNumbers is EqualUnmodifiableListView) return _busNumbers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_busNumbers);
}

 final  String start;
 final  String end;
 final  int stationCount;

/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitBusLegCopyWith<TransitBusLeg> get copyWith => _$TransitBusLegCopyWithImpl<TransitBusLeg>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitBusLeg&&(identical(other.minutes, minutes) || other.minutes == minutes)&&const DeepCollectionEquality().equals(other._busNumbers, _busNumbers)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.stationCount, stationCount) || other.stationCount == stationCount));
}


@override
int get hashCode => Object.hash(runtimeType,minutes,const DeepCollectionEquality().hash(_busNumbers),start,end,stationCount);

@override
String toString() {
  return 'TransitLeg.bus(minutes: $minutes, busNumbers: $busNumbers, start: $start, end: $end, stationCount: $stationCount)';
}


}

/// @nodoc
abstract mixin class $TransitBusLegCopyWith<$Res> implements $TransitLegCopyWith<$Res> {
  factory $TransitBusLegCopyWith(TransitBusLeg value, $Res Function(TransitBusLeg) _then) = _$TransitBusLegCopyWithImpl;
@override @useResult
$Res call({
 int minutes, List<String> busNumbers, String start, String end, int stationCount
});




}
/// @nodoc
class _$TransitBusLegCopyWithImpl<$Res>
    implements $TransitBusLegCopyWith<$Res> {
  _$TransitBusLegCopyWithImpl(this._self, this._then);

  final TransitBusLeg _self;
  final $Res Function(TransitBusLeg) _then;

/// Create a copy of TransitLeg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minutes = null,Object? busNumbers = null,Object? start = null,Object? end = null,Object? stationCount = null,}) {
  return _then(TransitBusLeg(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,busNumbers: null == busNumbers ? _self._busNumbers : busNumbers // ignore: cast_nullable_to_non_nullable
as List<String>,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,stationCount: null == stationCount ? _self.stationCount : stationCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TransitPath {

 int get totalMinutes; int get transferCount; int? get fare; List<TransitLeg> get legs;
/// Create a copy of TransitPath
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitPathCopyWith<TransitPath> get copyWith => _$TransitPathCopyWithImpl<TransitPath>(this as TransitPath, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitPath&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.transferCount, transferCount) || other.transferCount == transferCount)&&(identical(other.fare, fare) || other.fare == fare)&&const DeepCollectionEquality().equals(other.legs, legs));
}


@override
int get hashCode => Object.hash(runtimeType,totalMinutes,transferCount,fare,const DeepCollectionEquality().hash(legs));

@override
String toString() {
  return 'TransitPath(totalMinutes: $totalMinutes, transferCount: $transferCount, fare: $fare, legs: $legs)';
}


}

/// @nodoc
abstract mixin class $TransitPathCopyWith<$Res>  {
  factory $TransitPathCopyWith(TransitPath value, $Res Function(TransitPath) _then) = _$TransitPathCopyWithImpl;
@useResult
$Res call({
 int totalMinutes, int transferCount, int? fare, List<TransitLeg> legs
});




}
/// @nodoc
class _$TransitPathCopyWithImpl<$Res>
    implements $TransitPathCopyWith<$Res> {
  _$TransitPathCopyWithImpl(this._self, this._then);

  final TransitPath _self;
  final $Res Function(TransitPath) _then;

/// Create a copy of TransitPath
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalMinutes = null,Object? transferCount = null,Object? fare = freezed,Object? legs = null,}) {
  return _then(TransitPath(
totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,transferCount: null == transferCount ? _self.transferCount : transferCount // ignore: cast_nullable_to_non_nullable
as int,fare: freezed == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as int?,legs: null == legs ? _self.legs : legs // ignore: cast_nullable_to_non_nullable
as List<TransitLeg>,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitPath].
extension TransitPathPatterns on TransitPath {
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
