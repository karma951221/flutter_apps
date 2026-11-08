// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_period.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapPeriod {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPeriod);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapPeriod()';
}


}

/// @nodoc
class $MapPeriodCopyWith<$Res>  {
$MapPeriodCopyWith(MapPeriod _, $Res Function(MapPeriod) __);
}


/// Adds pattern-matching-related methods to [MapPeriod].
extension MapPeriodPatterns on MapPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DayPeriod value)?  day,TResult Function( MonthPeriod value)?  month,TResult Function( StoryPeriod value)?  story,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DayPeriod() when day != null:
return day(_that);case MonthPeriod() when month != null:
return month(_that);case StoryPeriod() when story != null:
return story(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DayPeriod value)  day,required TResult Function( MonthPeriod value)  month,required TResult Function( StoryPeriod value)  story,}){
final _that = this;
switch (_that) {
case DayPeriod():
return day(_that);case MonthPeriod():
return month(_that);case StoryPeriod():
return story(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DayPeriod value)?  day,TResult? Function( MonthPeriod value)?  month,TResult? Function( StoryPeriod value)?  story,}){
final _that = this;
switch (_that) {
case DayPeriod() when day != null:
return day(_that);case MonthPeriod() when month != null:
return month(_that);case StoryPeriod() when story != null:
return story(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DateTime date)?  day,TResult Function( int year,  int month)?  month,TResult Function( Story story)?  story,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DayPeriod() when day != null:
return day(_that.date);case MonthPeriod() when month != null:
return month(_that.year,_that.month);case StoryPeriod() when story != null:
return story(_that.story);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DateTime date)  day,required TResult Function( int year,  int month)  month,required TResult Function( Story story)  story,}) {final _that = this;
switch (_that) {
case DayPeriod():
return day(_that.date);case MonthPeriod():
return month(_that.year,_that.month);case StoryPeriod():
return story(_that.story);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DateTime date)?  day,TResult? Function( int year,  int month)?  month,TResult? Function( Story story)?  story,}) {final _that = this;
switch (_that) {
case DayPeriod() when day != null:
return day(_that.date);case MonthPeriod() when month != null:
return month(_that.year,_that.month);case StoryPeriod() when story != null:
return story(_that.story);case _:
  return null;

}
}

}

/// @nodoc


class DayPeriod implements MapPeriod {
  const DayPeriod(this.date);
  

 final  DateTime date;

/// Create a copy of MapPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayPeriodCopyWith<DayPeriod> get copyWith => _$DayPeriodCopyWithImpl<DayPeriod>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayPeriod&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode => Object.hash(runtimeType,date);

@override
String toString() {
  return 'MapPeriod.day(date: $date)';
}


}

/// @nodoc
abstract mixin class $DayPeriodCopyWith<$Res> implements $MapPeriodCopyWith<$Res> {
  factory $DayPeriodCopyWith(DayPeriod value, $Res Function(DayPeriod) _then) = _$DayPeriodCopyWithImpl;
@useResult
$Res call({
 DateTime date
});




}
/// @nodoc
class _$DayPeriodCopyWithImpl<$Res>
    implements $DayPeriodCopyWith<$Res> {
  _$DayPeriodCopyWithImpl(this._self, this._then);

  final DayPeriod _self;
  final $Res Function(DayPeriod) _then;

/// Create a copy of MapPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? date = null,}) {
  return _then(DayPeriod(
null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class MonthPeriod implements MapPeriod {
  const MonthPeriod(this.year, this.month);
  

 final  int year;
 final  int month;

/// Create a copy of MapPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthPeriodCopyWith<MonthPeriod> get copyWith => _$MonthPeriodCopyWithImpl<MonthPeriod>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthPeriod&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month));
}


@override
int get hashCode => Object.hash(runtimeType,year,month);

@override
String toString() {
  return 'MapPeriod.month(year: $year, month: $month)';
}


}

/// @nodoc
abstract mixin class $MonthPeriodCopyWith<$Res> implements $MapPeriodCopyWith<$Res> {
  factory $MonthPeriodCopyWith(MonthPeriod value, $Res Function(MonthPeriod) _then) = _$MonthPeriodCopyWithImpl;
@useResult
$Res call({
 int year, int month
});




}
/// @nodoc
class _$MonthPeriodCopyWithImpl<$Res>
    implements $MonthPeriodCopyWith<$Res> {
  _$MonthPeriodCopyWithImpl(this._self, this._then);

  final MonthPeriod _self;
  final $Res Function(MonthPeriod) _then;

/// Create a copy of MapPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? year = null,Object? month = null,}) {
  return _then(MonthPeriod(
null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class StoryPeriod implements MapPeriod {
  const StoryPeriod(this.story);
  

 final  Story story;

/// Create a copy of MapPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryPeriodCopyWith<StoryPeriod> get copyWith => _$StoryPeriodCopyWithImpl<StoryPeriod>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryPeriod&&(identical(other.story, story) || other.story == story));
}


@override
int get hashCode => Object.hash(runtimeType,story);

@override
String toString() {
  return 'MapPeriod.story(story: $story)';
}


}

/// @nodoc
abstract mixin class $StoryPeriodCopyWith<$Res> implements $MapPeriodCopyWith<$Res> {
  factory $StoryPeriodCopyWith(StoryPeriod value, $Res Function(StoryPeriod) _then) = _$StoryPeriodCopyWithImpl;
@useResult
$Res call({
 Story story
});


$StoryCopyWith<$Res> get story;

}
/// @nodoc
class _$StoryPeriodCopyWithImpl<$Res>
    implements $StoryPeriodCopyWith<$Res> {
  _$StoryPeriodCopyWithImpl(this._self, this._then);

  final StoryPeriod _self;
  final $Res Function(StoryPeriod) _then;

/// Create a copy of MapPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? story = null,}) {
  return _then(StoryPeriod(
null == story ? _self.story : story // ignore: cast_nullable_to_non_nullable
as Story,
  ));
}

/// Create a copy of MapPeriod
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoryCopyWith<$Res> get story {
  
  return $StoryCopyWith<$Res>(_self.story, (value) {
    return _then(_self.copyWith(story: value));
  });
}
}

// dart format on
