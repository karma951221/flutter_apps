// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holiday_calendar.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HolidaySource {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HolidaySource);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HolidaySource()';
}


}

/// @nodoc
class $HolidaySourceCopyWith<$Res>  {
$HolidaySourceCopyWith(HolidaySource _, $Res Function(HolidaySource) __);
}


/// Adds pattern-matching-related methods to [HolidaySource].
extension HolidaySourcePatterns on HolidaySource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeviceCalendarHolidays value)?  device,TResult Function( BundledHolidays value)?  bundled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeviceCalendarHolidays() when device != null:
return device(_that);case BundledHolidays() when bundled != null:
return bundled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeviceCalendarHolidays value)  device,required TResult Function( BundledHolidays value)  bundled,}){
final _that = this;
switch (_that) {
case DeviceCalendarHolidays():
return device(_that);case BundledHolidays():
return bundled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeviceCalendarHolidays value)?  device,TResult? Function( BundledHolidays value)?  bundled,}){
final _that = this;
switch (_that) {
case DeviceCalendarHolidays() when device != null:
return device(_that);case BundledHolidays() when bundled != null:
return bundled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String calendarName)?  device,TResult Function( int firstYear,  int lastYear)?  bundled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeviceCalendarHolidays() when device != null:
return device(_that.calendarName);case BundledHolidays() when bundled != null:
return bundled(_that.firstYear,_that.lastYear);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String calendarName)  device,required TResult Function( int firstYear,  int lastYear)  bundled,}) {final _that = this;
switch (_that) {
case DeviceCalendarHolidays():
return device(_that.calendarName);case BundledHolidays():
return bundled(_that.firstYear,_that.lastYear);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String calendarName)?  device,TResult? Function( int firstYear,  int lastYear)?  bundled,}) {final _that = this;
switch (_that) {
case DeviceCalendarHolidays() when device != null:
return device(_that.calendarName);case BundledHolidays() when bundled != null:
return bundled(_that.firstYear,_that.lastYear);case _:
  return null;

}
}

}

/// @nodoc


class DeviceCalendarHolidays implements HolidaySource {
  const DeviceCalendarHolidays({required this.calendarName});
  

 final  String calendarName;

/// Create a copy of HolidaySource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceCalendarHolidaysCopyWith<DeviceCalendarHolidays> get copyWith => _$DeviceCalendarHolidaysCopyWithImpl<DeviceCalendarHolidays>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceCalendarHolidays&&(identical(other.calendarName, calendarName) || other.calendarName == calendarName));
}


@override
int get hashCode => Object.hash(runtimeType,calendarName);

@override
String toString() {
  return 'HolidaySource.device(calendarName: $calendarName)';
}


}

/// @nodoc
abstract mixin class $DeviceCalendarHolidaysCopyWith<$Res> implements $HolidaySourceCopyWith<$Res> {
  factory $DeviceCalendarHolidaysCopyWith(DeviceCalendarHolidays value, $Res Function(DeviceCalendarHolidays) _then) = _$DeviceCalendarHolidaysCopyWithImpl;
@useResult
$Res call({
 String calendarName
});




}
/// @nodoc
class _$DeviceCalendarHolidaysCopyWithImpl<$Res>
    implements $DeviceCalendarHolidaysCopyWith<$Res> {
  _$DeviceCalendarHolidaysCopyWithImpl(this._self, this._then);

  final DeviceCalendarHolidays _self;
  final $Res Function(DeviceCalendarHolidays) _then;

/// Create a copy of HolidaySource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? calendarName = null,}) {
  return _then(DeviceCalendarHolidays(
calendarName: null == calendarName ? _self.calendarName : calendarName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BundledHolidays implements HolidaySource {
  const BundledHolidays({required this.firstYear, required this.lastYear});
  

 final  int firstYear;
 final  int lastYear;

/// Create a copy of HolidaySource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BundledHolidaysCopyWith<BundledHolidays> get copyWith => _$BundledHolidaysCopyWithImpl<BundledHolidays>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BundledHolidays&&(identical(other.firstYear, firstYear) || other.firstYear == firstYear)&&(identical(other.lastYear, lastYear) || other.lastYear == lastYear));
}


@override
int get hashCode => Object.hash(runtimeType,firstYear,lastYear);

@override
String toString() {
  return 'HolidaySource.bundled(firstYear: $firstYear, lastYear: $lastYear)';
}


}

/// @nodoc
abstract mixin class $BundledHolidaysCopyWith<$Res> implements $HolidaySourceCopyWith<$Res> {
  factory $BundledHolidaysCopyWith(BundledHolidays value, $Res Function(BundledHolidays) _then) = _$BundledHolidaysCopyWithImpl;
@useResult
$Res call({
 int firstYear, int lastYear
});




}
/// @nodoc
class _$BundledHolidaysCopyWithImpl<$Res>
    implements $BundledHolidaysCopyWith<$Res> {
  _$BundledHolidaysCopyWithImpl(this._self, this._then);

  final BundledHolidays _self;
  final $Res Function(BundledHolidays) _then;

/// Create a copy of HolidaySource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? firstYear = null,Object? lastYear = null,}) {
  return _then(BundledHolidays(
firstYear: null == firstYear ? _self.firstYear : firstYear // ignore: cast_nullable_to_non_nullable
as int,lastYear: null == lastYear ? _self.lastYear : lastYear // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
