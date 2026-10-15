// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StatsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StatsState()';
}


}

/// @nodoc
class $StatsStateCopyWith<$Res>  {
$StatsStateCopyWith(StatsState _, $Res Function(StatsState) __);
}


/// Adds pattern-matching-related methods to [StatsState].
extension StatsStatePatterns on StatsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StatsLoading value)?  loading,TResult Function( StatsLoaded value)?  loaded,TResult Function( StatsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StatsLoading() when loading != null:
return loading(_that);case StatsLoaded() when loaded != null:
return loaded(_that);case StatsFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StatsLoading value)  loading,required TResult Function( StatsLoaded value)  loaded,required TResult Function( StatsFailure value)  failure,}){
final _that = this;
switch (_that) {
case StatsLoading():
return loading(_that);case StatsLoaded():
return loaded(_that);case StatsFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StatsLoading value)?  loading,TResult? Function( StatsLoaded value)?  loaded,TResult? Function( StatsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case StatsLoading() when loading != null:
return loading(_that);case StatsLoaded() when loaded != null:
return loaded(_that);case StatsFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( PeriodStats stats,  WalkRecords records,  int offset,  bool canShowPrevious,  bool canShowNext,  bool isEmpty,  DateTime now)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StatsLoading() when loading != null:
return loading();case StatsLoaded() when loaded != null:
return loaded(_that.stats,_that.records,_that.offset,_that.canShowPrevious,_that.canShowNext,_that.isEmpty,_that.now);case StatsFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( PeriodStats stats,  WalkRecords records,  int offset,  bool canShowPrevious,  bool canShowNext,  bool isEmpty,  DateTime now)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case StatsLoading():
return loading();case StatsLoaded():
return loaded(_that.stats,_that.records,_that.offset,_that.canShowPrevious,_that.canShowNext,_that.isEmpty,_that.now);case StatsFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( PeriodStats stats,  WalkRecords records,  int offset,  bool canShowPrevious,  bool canShowNext,  bool isEmpty,  DateTime now)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case StatsLoading() when loading != null:
return loading();case StatsLoaded() when loaded != null:
return loaded(_that.stats,_that.records,_that.offset,_that.canShowPrevious,_that.canShowNext,_that.isEmpty,_that.now);case StatsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class StatsLoading implements StatsState {
  const StatsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StatsState.loading()';
}


}




/// @nodoc


class StatsLoaded implements StatsState {
  const StatsLoaded({required this.stats, required this.records, required this.offset, required this.canShowPrevious, required this.canShowNext, required this.isEmpty, required this.now});
  

 final  PeriodStats stats;
 final  WalkRecords records;
 final  int offset;
 final  bool canShowPrevious;
 final  bool canShowNext;
 final  bool isEmpty;
 final  DateTime now;

/// Create a copy of StatsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsLoadedCopyWith<StatsLoaded> get copyWith => _$StatsLoadedCopyWithImpl<StatsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsLoaded&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.records, records) || other.records == records)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.canShowPrevious, canShowPrevious) || other.canShowPrevious == canShowPrevious)&&(identical(other.canShowNext, canShowNext) || other.canShowNext == canShowNext)&&(identical(other.isEmpty, isEmpty) || other.isEmpty == isEmpty)&&(identical(other.now, now) || other.now == now));
}


@override
int get hashCode => Object.hash(runtimeType,stats,records,offset,canShowPrevious,canShowNext,isEmpty,now);

@override
String toString() {
  return 'StatsState.loaded(stats: $stats, records: $records, offset: $offset, canShowPrevious: $canShowPrevious, canShowNext: $canShowNext, isEmpty: $isEmpty, now: $now)';
}


}

/// @nodoc
abstract mixin class $StatsLoadedCopyWith<$Res> implements $StatsStateCopyWith<$Res> {
  factory $StatsLoadedCopyWith(StatsLoaded value, $Res Function(StatsLoaded) _then) = _$StatsLoadedCopyWithImpl;
@useResult
$Res call({
 PeriodStats stats, WalkRecords records, int offset, bool canShowPrevious, bool canShowNext, bool isEmpty, DateTime now
});


$PeriodStatsCopyWith<$Res> get stats;$WalkRecordsCopyWith<$Res> get records;

}
/// @nodoc
class _$StatsLoadedCopyWithImpl<$Res>
    implements $StatsLoadedCopyWith<$Res> {
  _$StatsLoadedCopyWithImpl(this._self, this._then);

  final StatsLoaded _self;
  final $Res Function(StatsLoaded) _then;

/// Create a copy of StatsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stats = null,Object? records = null,Object? offset = null,Object? canShowPrevious = null,Object? canShowNext = null,Object? isEmpty = null,Object? now = null,}) {
  return _then(StatsLoaded(
stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as PeriodStats,records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as WalkRecords,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,canShowPrevious: null == canShowPrevious ? _self.canShowPrevious : canShowPrevious // ignore: cast_nullable_to_non_nullable
as bool,canShowNext: null == canShowNext ? _self.canShowNext : canShowNext // ignore: cast_nullable_to_non_nullable
as bool,isEmpty: null == isEmpty ? _self.isEmpty : isEmpty // ignore: cast_nullable_to_non_nullable
as bool,now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of StatsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStatsCopyWith<$Res> get stats {
  
  return $PeriodStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}/// Create a copy of StatsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalkRecordsCopyWith<$Res> get records {
  
  return $WalkRecordsCopyWith<$Res>(_self.records, (value) {
    return _then(_self.copyWith(records: value));
  });
}
}

/// @nodoc


class StatsFailure implements StatsState {
  const StatsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of StatsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsFailureCopyWith<StatsFailure> get copyWith => _$StatsFailureCopyWithImpl<StatsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'StatsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StatsFailureCopyWith<$Res> implements $StatsStateCopyWith<$Res> {
  factory $StatsFailureCopyWith(StatsFailure value, $Res Function(StatsFailure) _then) = _$StatsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$StatsFailureCopyWithImpl<$Res>
    implements $StatsFailureCopyWith<$Res> {
  _$StatsFailureCopyWithImpl(this._self, this._then);

  final StatsFailure _self;
  final $Res Function(StatsFailure) _then;

/// Create a copy of StatsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(StatsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of StatsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
