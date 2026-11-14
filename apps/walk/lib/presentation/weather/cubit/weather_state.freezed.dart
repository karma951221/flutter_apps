// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeatherState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WeatherState()';
}


}

/// @nodoc
class $WeatherStateCopyWith<$Res>  {
$WeatherStateCopyWith(WeatherState _, $Res Function(WeatherState) __);
}


/// Adds pattern-matching-related methods to [WeatherState].
extension WeatherStatePatterns on WeatherState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WeatherLoading value)?  loading,TResult Function( WeatherLoaded value)?  loaded,TResult Function( WeatherEmpty value)?  empty,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WeatherLoading() when loading != null:
return loading(_that);case WeatherLoaded() when loaded != null:
return loaded(_that);case WeatherEmpty() when empty != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WeatherLoading value)  loading,required TResult Function( WeatherLoaded value)  loaded,required TResult Function( WeatherEmpty value)  empty,}){
final _that = this;
switch (_that) {
case WeatherLoading():
return loading(_that);case WeatherLoaded():
return loaded(_that);case WeatherEmpty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WeatherLoading value)?  loading,TResult? Function( WeatherLoaded value)?  loaded,TResult? Function( WeatherEmpty value)?  empty,}){
final _that = this;
switch (_that) {
case WeatherLoading() when loading != null:
return loading(_that);case WeatherLoaded() when loaded != null:
return loaded(_that);case WeatherEmpty() when empty != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Forecast forecast,  String? placeName,  DateTime fetchedAt,  bool refreshing,  bool stale,  WeatherProblem? problem)?  loaded,TResult Function( WeatherProblem problem)?  empty,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WeatherLoading() when loading != null:
return loading();case WeatherLoaded() when loaded != null:
return loaded(_that.forecast,_that.placeName,_that.fetchedAt,_that.refreshing,_that.stale,_that.problem);case WeatherEmpty() when empty != null:
return empty(_that.problem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Forecast forecast,  String? placeName,  DateTime fetchedAt,  bool refreshing,  bool stale,  WeatherProblem? problem)  loaded,required TResult Function( WeatherProblem problem)  empty,}) {final _that = this;
switch (_that) {
case WeatherLoading():
return loading();case WeatherLoaded():
return loaded(_that.forecast,_that.placeName,_that.fetchedAt,_that.refreshing,_that.stale,_that.problem);case WeatherEmpty():
return empty(_that.problem);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Forecast forecast,  String? placeName,  DateTime fetchedAt,  bool refreshing,  bool stale,  WeatherProblem? problem)?  loaded,TResult? Function( WeatherProblem problem)?  empty,}) {final _that = this;
switch (_that) {
case WeatherLoading() when loading != null:
return loading();case WeatherLoaded() when loaded != null:
return loaded(_that.forecast,_that.placeName,_that.fetchedAt,_that.refreshing,_that.stale,_that.problem);case WeatherEmpty() when empty != null:
return empty(_that.problem);case _:
  return null;

}
}

}

/// @nodoc


class WeatherLoading implements WeatherState {
  const WeatherLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WeatherState.loading()';
}


}




/// @nodoc


class WeatherLoaded implements WeatherState {
  const WeatherLoaded({required this.forecast, this.placeName, required this.fetchedAt, this.refreshing = false, this.stale = false, this.problem});
  

 final  Forecast forecast;
 final  String? placeName;
 final  DateTime fetchedAt;
@JsonKey() final  bool refreshing;
@JsonKey() final  bool stale;
 final  WeatherProblem? problem;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherLoadedCopyWith<WeatherLoaded> get copyWith => _$WeatherLoadedCopyWithImpl<WeatherLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherLoaded&&(identical(other.forecast, forecast) || other.forecast == forecast)&&(identical(other.placeName, placeName) || other.placeName == placeName)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.stale, stale) || other.stale == stale)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode => Object.hash(runtimeType,forecast,placeName,fetchedAt,refreshing,stale,problem);

@override
String toString() {
  return 'WeatherState.loaded(forecast: $forecast, placeName: $placeName, fetchedAt: $fetchedAt, refreshing: $refreshing, stale: $stale, problem: $problem)';
}


}

/// @nodoc
abstract mixin class $WeatherLoadedCopyWith<$Res> implements $WeatherStateCopyWith<$Res> {
  factory $WeatherLoadedCopyWith(WeatherLoaded value, $Res Function(WeatherLoaded) _then) = _$WeatherLoadedCopyWithImpl;
@useResult
$Res call({
 Forecast forecast, String? placeName, DateTime fetchedAt, bool refreshing, bool stale, WeatherProblem? problem
});


$ForecastCopyWith<$Res> get forecast;

}
/// @nodoc
class _$WeatherLoadedCopyWithImpl<$Res>
    implements $WeatherLoadedCopyWith<$Res> {
  _$WeatherLoadedCopyWithImpl(this._self, this._then);

  final WeatherLoaded _self;
  final $Res Function(WeatherLoaded) _then;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? forecast = null,Object? placeName = freezed,Object? fetchedAt = null,Object? refreshing = null,Object? stale = null,Object? problem = freezed,}) {
  return _then(WeatherLoaded(
forecast: null == forecast ? _self.forecast : forecast // ignore: cast_nullable_to_non_nullable
as Forecast,placeName: freezed == placeName ? _self.placeName : placeName // ignore: cast_nullable_to_non_nullable
as String?,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as bool,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as WeatherProblem?,
  ));
}

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ForecastCopyWith<$Res> get forecast {
  
  return $ForecastCopyWith<$Res>(_self.forecast, (value) {
    return _then(_self.copyWith(forecast: value));
  });
}
}

/// @nodoc


class WeatherEmpty implements WeatherState {
  const WeatherEmpty(this.problem);
  

 final  WeatherProblem problem;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherEmptyCopyWith<WeatherEmpty> get copyWith => _$WeatherEmptyCopyWithImpl<WeatherEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherEmpty&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode => Object.hash(runtimeType,problem);

@override
String toString() {
  return 'WeatherState.empty(problem: $problem)';
}


}

/// @nodoc
abstract mixin class $WeatherEmptyCopyWith<$Res> implements $WeatherStateCopyWith<$Res> {
  factory $WeatherEmptyCopyWith(WeatherEmpty value, $Res Function(WeatherEmpty) _then) = _$WeatherEmptyCopyWithImpl;
@useResult
$Res call({
 WeatherProblem problem
});




}
/// @nodoc
class _$WeatherEmptyCopyWithImpl<$Res>
    implements $WeatherEmptyCopyWith<$Res> {
  _$WeatherEmptyCopyWithImpl(this._self, this._then);

  final WeatherEmpty _self;
  final $Res Function(WeatherEmpty) _then;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problem = null,}) {
  return _then(WeatherEmpty(
null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as WeatherProblem,
  ));
}


}

// dart format on
