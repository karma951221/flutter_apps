// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PeriodStats {

 StatsPeriod get period; PeriodRange get range; PeriodSummary get summary; PeriodSummary get previousSummary; List<StatsBucket> get buckets;
/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodStatsCopyWith<PeriodStats> get copyWith => _$PeriodStatsCopyWithImpl<PeriodStats>(this as PeriodStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodStats&&(identical(other.period, period) || other.period == period)&&(identical(other.range, range) || other.range == range)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.previousSummary, previousSummary) || other.previousSummary == previousSummary)&&const DeepCollectionEquality().equals(other.buckets, buckets));
}


@override
int get hashCode => Object.hash(runtimeType,period,range,summary,previousSummary,const DeepCollectionEquality().hash(buckets));

@override
String toString() {
  return 'PeriodStats(period: $period, range: $range, summary: $summary, previousSummary: $previousSummary, buckets: $buckets)';
}


}

/// @nodoc
abstract mixin class $PeriodStatsCopyWith<$Res>  {
  factory $PeriodStatsCopyWith(PeriodStats value, $Res Function(PeriodStats) _then) = _$PeriodStatsCopyWithImpl;
@useResult
$Res call({
 StatsPeriod period, PeriodRange range, PeriodSummary summary, PeriodSummary previousSummary, List<StatsBucket> buckets
});




}
/// @nodoc
class _$PeriodStatsCopyWithImpl<$Res>
    implements $PeriodStatsCopyWith<$Res> {
  _$PeriodStatsCopyWithImpl(this._self, this._then);

  final PeriodStats _self;
  final $Res Function(PeriodStats) _then;

/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? range = null,Object? summary = null,Object? previousSummary = null,Object? buckets = null,}) {
  return _then(PeriodStats(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as StatsPeriod,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as PeriodRange,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PeriodSummary,previousSummary: null == previousSummary ? _self.previousSummary : previousSummary // ignore: cast_nullable_to_non_nullable
as PeriodSummary,buckets: null == buckets ? _self.buckets : buckets // ignore: cast_nullable_to_non_nullable
as List<StatsBucket>,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodStats].
extension PeriodStatsPatterns on PeriodStats {
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
