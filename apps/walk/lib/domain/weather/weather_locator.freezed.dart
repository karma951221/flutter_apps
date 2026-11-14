// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_locator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeatherFix {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherFix);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WeatherFix()';
}


}

/// @nodoc
class $WeatherFixCopyWith<$Res>  {
$WeatherFixCopyWith(WeatherFix _, $Res Function(WeatherFix) __);
}


/// Adds pattern-matching-related methods to [WeatherFix].
extension WeatherFixPatterns on WeatherFix {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WeatherLocated value)?  located,TResult Function( WeatherNoFix value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WeatherLocated() when located != null:
return located(_that);case WeatherNoFix() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WeatherLocated value)  located,required TResult Function( WeatherNoFix value)  failed,}){
final _that = this;
switch (_that) {
case WeatherLocated():
return located(_that);case WeatherNoFix():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WeatherLocated value)?  located,TResult? Function( WeatherNoFix value)?  failed,}){
final _that = this;
switch (_that) {
case WeatherLocated() when located != null:
return located(_that);case WeatherNoFix() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double lat,  double lng)?  located,TResult Function( WeatherProblem problem)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WeatherLocated() when located != null:
return located(_that.lat,_that.lng);case WeatherNoFix() when failed != null:
return failed(_that.problem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double lat,  double lng)  located,required TResult Function( WeatherProblem problem)  failed,}) {final _that = this;
switch (_that) {
case WeatherLocated():
return located(_that.lat,_that.lng);case WeatherNoFix():
return failed(_that.problem);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double lat,  double lng)?  located,TResult? Function( WeatherProblem problem)?  failed,}) {final _that = this;
switch (_that) {
case WeatherLocated() when located != null:
return located(_that.lat,_that.lng);case WeatherNoFix() when failed != null:
return failed(_that.problem);case _:
  return null;

}
}

}

/// @nodoc


class WeatherLocated implements WeatherFix {
  const WeatherLocated(this.lat, this.lng);
  

 final  double lat;
 final  double lng;

/// Create a copy of WeatherFix
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherLocatedCopyWith<WeatherLocated> get copyWith => _$WeatherLocatedCopyWithImpl<WeatherLocated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherLocated&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}


@override
int get hashCode => Object.hash(runtimeType,lat,lng);

@override
String toString() {
  return 'WeatherFix.located(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class $WeatherLocatedCopyWith<$Res> implements $WeatherFixCopyWith<$Res> {
  factory $WeatherLocatedCopyWith(WeatherLocated value, $Res Function(WeatherLocated) _then) = _$WeatherLocatedCopyWithImpl;
@useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class _$WeatherLocatedCopyWithImpl<$Res>
    implements $WeatherLocatedCopyWith<$Res> {
  _$WeatherLocatedCopyWithImpl(this._self, this._then);

  final WeatherLocated _self;
  final $Res Function(WeatherLocated) _then;

/// Create a copy of WeatherFix
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(WeatherLocated(
null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class WeatherNoFix implements WeatherFix {
  const WeatherNoFix(this.problem);
  

 final  WeatherProblem problem;

/// Create a copy of WeatherFix
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherNoFixCopyWith<WeatherNoFix> get copyWith => _$WeatherNoFixCopyWithImpl<WeatherNoFix>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherNoFix&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode => Object.hash(runtimeType,problem);

@override
String toString() {
  return 'WeatherFix.failed(problem: $problem)';
}


}

/// @nodoc
abstract mixin class $WeatherNoFixCopyWith<$Res> implements $WeatherFixCopyWith<$Res> {
  factory $WeatherNoFixCopyWith(WeatherNoFix value, $Res Function(WeatherNoFix) _then) = _$WeatherNoFixCopyWithImpl;
@useResult
$Res call({
 WeatherProblem problem
});




}
/// @nodoc
class _$WeatherNoFixCopyWithImpl<$Res>
    implements $WeatherNoFixCopyWith<$Res> {
  _$WeatherNoFixCopyWithImpl(this._self, this._then);

  final WeatherNoFix _self;
  final $Res Function(WeatherNoFix) _then;

/// Create a copy of WeatherFix
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problem = null,}) {
  return _then(WeatherNoFix(
null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as WeatherProblem,
  ));
}


}

// dart format on
