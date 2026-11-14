// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rain_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RainSummary {

 int get maxProbability;
/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RainSummaryCopyWith<RainSummary> get copyWith => _$RainSummaryCopyWithImpl<RainSummary>(this as RainSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RainSummary&&(identical(other.maxProbability, maxProbability) || other.maxProbability == maxProbability));
}


@override
int get hashCode => Object.hash(runtimeType,maxProbability);

@override
String toString() {
  return 'RainSummary(maxProbability: $maxProbability)';
}


}

/// @nodoc
abstract mixin class $RainSummaryCopyWith<$Res>  {
  factory $RainSummaryCopyWith(RainSummary value, $Res Function(RainSummary) _then) = _$RainSummaryCopyWithImpl;
@useResult
$Res call({
 int maxProbability
});




}
/// @nodoc
class _$RainSummaryCopyWithImpl<$Res>
    implements $RainSummaryCopyWith<$Res> {
  _$RainSummaryCopyWithImpl(this._self, this._then);

  final RainSummary _self;
  final $Res Function(RainSummary) _then;

/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxProbability = null,}) {
  return _then(_self.copyWith(
maxProbability: null == maxProbability ? _self.maxProbability : maxProbability // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RainSummary].
extension RainSummaryPatterns on RainSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RainNow value)?  now,TResult Function( RainLater value)?  later,TResult Function( NoRain value)?  none,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RainNow() when now != null:
return now(_that);case RainLater() when later != null:
return later(_that);case NoRain() when none != null:
return none(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RainNow value)  now,required TResult Function( RainLater value)  later,required TResult Function( NoRain value)  none,}){
final _that = this;
switch (_that) {
case RainNow():
return now(_that);case RainLater():
return later(_that);case NoRain():
return none(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RainNow value)?  now,TResult? Function( RainLater value)?  later,TResult? Function( NoRain value)?  none,}){
final _that = this;
switch (_that) {
case RainNow() when now != null:
return now(_that);case RainLater() when later != null:
return later(_that);case NoRain() when none != null:
return none(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DateTime? stopsAt,  bool snow,  int maxProbability,  double totalMm)?  now,TResult Function( DateTime startsAt,  bool snow,  int maxProbability,  double totalMm)?  later,TResult Function( int maxProbability)?  none,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RainNow() when now != null:
return now(_that.stopsAt,_that.snow,_that.maxProbability,_that.totalMm);case RainLater() when later != null:
return later(_that.startsAt,_that.snow,_that.maxProbability,_that.totalMm);case NoRain() when none != null:
return none(_that.maxProbability);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DateTime? stopsAt,  bool snow,  int maxProbability,  double totalMm)  now,required TResult Function( DateTime startsAt,  bool snow,  int maxProbability,  double totalMm)  later,required TResult Function( int maxProbability)  none,}) {final _that = this;
switch (_that) {
case RainNow():
return now(_that.stopsAt,_that.snow,_that.maxProbability,_that.totalMm);case RainLater():
return later(_that.startsAt,_that.snow,_that.maxProbability,_that.totalMm);case NoRain():
return none(_that.maxProbability);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DateTime? stopsAt,  bool snow,  int maxProbability,  double totalMm)?  now,TResult? Function( DateTime startsAt,  bool snow,  int maxProbability,  double totalMm)?  later,TResult? Function( int maxProbability)?  none,}) {final _that = this;
switch (_that) {
case RainNow() when now != null:
return now(_that.stopsAt,_that.snow,_that.maxProbability,_that.totalMm);case RainLater() when later != null:
return later(_that.startsAt,_that.snow,_that.maxProbability,_that.totalMm);case NoRain() when none != null:
return none(_that.maxProbability);case _:
  return null;

}
}

}

/// @nodoc


class RainNow implements RainSummary {
  const RainNow({this.stopsAt, required this.snow, required this.maxProbability, required this.totalMm});
  

 final  DateTime? stopsAt;
 final  bool snow;
@override final  int maxProbability;
 final  double totalMm;

/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RainNowCopyWith<RainNow> get copyWith => _$RainNowCopyWithImpl<RainNow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RainNow&&(identical(other.stopsAt, stopsAt) || other.stopsAt == stopsAt)&&(identical(other.snow, snow) || other.snow == snow)&&(identical(other.maxProbability, maxProbability) || other.maxProbability == maxProbability)&&(identical(other.totalMm, totalMm) || other.totalMm == totalMm));
}


@override
int get hashCode => Object.hash(runtimeType,stopsAt,snow,maxProbability,totalMm);

@override
String toString() {
  return 'RainSummary.now(stopsAt: $stopsAt, snow: $snow, maxProbability: $maxProbability, totalMm: $totalMm)';
}


}

/// @nodoc
abstract mixin class $RainNowCopyWith<$Res> implements $RainSummaryCopyWith<$Res> {
  factory $RainNowCopyWith(RainNow value, $Res Function(RainNow) _then) = _$RainNowCopyWithImpl;
@override @useResult
$Res call({
 DateTime? stopsAt, bool snow, int maxProbability, double totalMm
});




}
/// @nodoc
class _$RainNowCopyWithImpl<$Res>
    implements $RainNowCopyWith<$Res> {
  _$RainNowCopyWithImpl(this._self, this._then);

  final RainNow _self;
  final $Res Function(RainNow) _then;

/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stopsAt = freezed,Object? snow = null,Object? maxProbability = null,Object? totalMm = null,}) {
  return _then(RainNow(
stopsAt: freezed == stopsAt ? _self.stopsAt : stopsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snow: null == snow ? _self.snow : snow // ignore: cast_nullable_to_non_nullable
as bool,maxProbability: null == maxProbability ? _self.maxProbability : maxProbability // ignore: cast_nullable_to_non_nullable
as int,totalMm: null == totalMm ? _self.totalMm : totalMm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class RainLater implements RainSummary {
  const RainLater({required this.startsAt, required this.snow, required this.maxProbability, required this.totalMm});
  

 final  DateTime startsAt;
 final  bool snow;
@override final  int maxProbability;
 final  double totalMm;

/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RainLaterCopyWith<RainLater> get copyWith => _$RainLaterCopyWithImpl<RainLater>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RainLater&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.snow, snow) || other.snow == snow)&&(identical(other.maxProbability, maxProbability) || other.maxProbability == maxProbability)&&(identical(other.totalMm, totalMm) || other.totalMm == totalMm));
}


@override
int get hashCode => Object.hash(runtimeType,startsAt,snow,maxProbability,totalMm);

@override
String toString() {
  return 'RainSummary.later(startsAt: $startsAt, snow: $snow, maxProbability: $maxProbability, totalMm: $totalMm)';
}


}

/// @nodoc
abstract mixin class $RainLaterCopyWith<$Res> implements $RainSummaryCopyWith<$Res> {
  factory $RainLaterCopyWith(RainLater value, $Res Function(RainLater) _then) = _$RainLaterCopyWithImpl;
@override @useResult
$Res call({
 DateTime startsAt, bool snow, int maxProbability, double totalMm
});




}
/// @nodoc
class _$RainLaterCopyWithImpl<$Res>
    implements $RainLaterCopyWith<$Res> {
  _$RainLaterCopyWithImpl(this._self, this._then);

  final RainLater _self;
  final $Res Function(RainLater) _then;

/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startsAt = null,Object? snow = null,Object? maxProbability = null,Object? totalMm = null,}) {
  return _then(RainLater(
startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,snow: null == snow ? _self.snow : snow // ignore: cast_nullable_to_non_nullable
as bool,maxProbability: null == maxProbability ? _self.maxProbability : maxProbability // ignore: cast_nullable_to_non_nullable
as int,totalMm: null == totalMm ? _self.totalMm : totalMm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class NoRain implements RainSummary {
  const NoRain({required this.maxProbability});
  

@override final  int maxProbability;

/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoRainCopyWith<NoRain> get copyWith => _$NoRainCopyWithImpl<NoRain>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoRain&&(identical(other.maxProbability, maxProbability) || other.maxProbability == maxProbability));
}


@override
int get hashCode => Object.hash(runtimeType,maxProbability);

@override
String toString() {
  return 'RainSummary.none(maxProbability: $maxProbability)';
}


}

/// @nodoc
abstract mixin class $NoRainCopyWith<$Res> implements $RainSummaryCopyWith<$Res> {
  factory $NoRainCopyWith(NoRain value, $Res Function(NoRain) _then) = _$NoRainCopyWithImpl;
@override @useResult
$Res call({
 int maxProbability
});




}
/// @nodoc
class _$NoRainCopyWithImpl<$Res>
    implements $NoRainCopyWith<$Res> {
  _$NoRainCopyWithImpl(this._self, this._then);

  final NoRain _self;
  final $Res Function(NoRain) _then;

/// Create a copy of RainSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxProbability = null,}) {
  return _then(NoRain(
maxProbability: null == maxProbability ? _self.maxProbability : maxProbability // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
