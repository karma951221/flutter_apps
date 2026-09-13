// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'station_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StationSearchState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationSearchState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StationSearchState()';
}


}

/// @nodoc
class $StationSearchStateCopyWith<$Res>  {
$StationSearchStateCopyWith(StationSearchState _, $Res Function(StationSearchState) __);
}


/// Adds pattern-matching-related methods to [StationSearchState].
extension StationSearchStatePatterns on StationSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StationSearchIdle value)?  idle,TResult Function( StationSearchSearching value)?  searching,TResult Function( StationSearchResults value)?  results,TResult Function( StationSearchFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StationSearchIdle() when idle != null:
return idle(_that);case StationSearchSearching() when searching != null:
return searching(_that);case StationSearchResults() when results != null:
return results(_that);case StationSearchFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StationSearchIdle value)  idle,required TResult Function( StationSearchSearching value)  searching,required TResult Function( StationSearchResults value)  results,required TResult Function( StationSearchFailure value)  failure,}){
final _that = this;
switch (_that) {
case StationSearchIdle():
return idle(_that);case StationSearchSearching():
return searching(_that);case StationSearchResults():
return results(_that);case StationSearchFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StationSearchIdle value)?  idle,TResult? Function( StationSearchSearching value)?  searching,TResult? Function( StationSearchResults value)?  results,TResult? Function( StationSearchFailure value)?  failure,}){
final _that = this;
switch (_that) {
case StationSearchIdle() when idle != null:
return idle(_that);case StationSearchSearching() when searching != null:
return searching(_that);case StationSearchResults() when results != null:
return results(_that);case StationSearchFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( String query)?  searching,TResult Function( String query,  List<Station> stations)?  results,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StationSearchIdle() when idle != null:
return idle();case StationSearchSearching() when searching != null:
return searching(_that.query);case StationSearchResults() when results != null:
return results(_that.query,_that.stations);case StationSearchFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( String query)  searching,required TResult Function( String query,  List<Station> stations)  results,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case StationSearchIdle():
return idle();case StationSearchSearching():
return searching(_that.query);case StationSearchResults():
return results(_that.query,_that.stations);case StationSearchFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( String query)?  searching,TResult? Function( String query,  List<Station> stations)?  results,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case StationSearchIdle() when idle != null:
return idle();case StationSearchSearching() when searching != null:
return searching(_that.query);case StationSearchResults() when results != null:
return results(_that.query,_that.stations);case StationSearchFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class StationSearchIdle implements StationSearchState {
  const StationSearchIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationSearchIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StationSearchState.idle()';
}


}




/// @nodoc


class StationSearchSearching implements StationSearchState {
  const StationSearchSearching(this.query);
  

 final  String query;

/// Create a copy of StationSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StationSearchSearchingCopyWith<StationSearchSearching> get copyWith => _$StationSearchSearchingCopyWithImpl<StationSearchSearching>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationSearchSearching&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'StationSearchState.searching(query: $query)';
}


}

/// @nodoc
abstract mixin class $StationSearchSearchingCopyWith<$Res> implements $StationSearchStateCopyWith<$Res> {
  factory $StationSearchSearchingCopyWith(StationSearchSearching value, $Res Function(StationSearchSearching) _then) = _$StationSearchSearchingCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$StationSearchSearchingCopyWithImpl<$Res>
    implements $StationSearchSearchingCopyWith<$Res> {
  _$StationSearchSearchingCopyWithImpl(this._self, this._then);

  final StationSearchSearching _self;
  final $Res Function(StationSearchSearching) _then;

/// Create a copy of StationSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(StationSearchSearching(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StationSearchResults implements StationSearchState {
  const StationSearchResults(this.query, final  List<Station> stations): _stations = stations;
  

 final  String query;
 final  List<Station> _stations;
 List<Station> get stations {
  if (_stations is EqualUnmodifiableListView) return _stations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stations);
}


/// Create a copy of StationSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StationSearchResultsCopyWith<StationSearchResults> get copyWith => _$StationSearchResultsCopyWithImpl<StationSearchResults>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationSearchResults&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._stations, _stations));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_stations));

@override
String toString() {
  return 'StationSearchState.results(query: $query, stations: $stations)';
}


}

/// @nodoc
abstract mixin class $StationSearchResultsCopyWith<$Res> implements $StationSearchStateCopyWith<$Res> {
  factory $StationSearchResultsCopyWith(StationSearchResults value, $Res Function(StationSearchResults) _then) = _$StationSearchResultsCopyWithImpl;
@useResult
$Res call({
 String query, List<Station> stations
});




}
/// @nodoc
class _$StationSearchResultsCopyWithImpl<$Res>
    implements $StationSearchResultsCopyWith<$Res> {
  _$StationSearchResultsCopyWithImpl(this._self, this._then);

  final StationSearchResults _self;
  final $Res Function(StationSearchResults) _then;

/// Create a copy of StationSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,Object? stations = null,}) {
  return _then(StationSearchResults(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,null == stations ? _self._stations : stations // ignore: cast_nullable_to_non_nullable
as List<Station>,
  ));
}


}

/// @nodoc


class StationSearchFailure implements StationSearchState {
  const StationSearchFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of StationSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StationSearchFailureCopyWith<StationSearchFailure> get copyWith => _$StationSearchFailureCopyWithImpl<StationSearchFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationSearchFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'StationSearchState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StationSearchFailureCopyWith<$Res> implements $StationSearchStateCopyWith<$Res> {
  factory $StationSearchFailureCopyWith(StationSearchFailure value, $Res Function(StationSearchFailure) _then) = _$StationSearchFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$StationSearchFailureCopyWithImpl<$Res>
    implements $StationSearchFailureCopyWith<$Res> {
  _$StationSearchFailureCopyWithImpl(this._self, this._then);

  final StationSearchFailure _self;
  final $Res Function(StationSearchFailure) _then;

/// Create a copy of StationSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(StationSearchFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of StationSearchState
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
