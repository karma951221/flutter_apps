// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PointPickerState {

 String get query; bool get searching; List<StationHit> get stations; List<PlaceCandidate> get addresses; bool get addressSearching; TransitFailure? get stationFailure; TransitSuggestions? get suggestions;
/// Create a copy of PointPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointPickerStateCopyWith<PointPickerState> get copyWith => _$PointPickerStateCopyWithImpl<PointPickerState>(this as PointPickerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PointPickerState&&(identical(other.query, query) || other.query == query)&&(identical(other.searching, searching) || other.searching == searching)&&const DeepCollectionEquality().equals(other.stations, stations)&&const DeepCollectionEquality().equals(other.addresses, addresses)&&(identical(other.addressSearching, addressSearching) || other.addressSearching == addressSearching)&&(identical(other.stationFailure, stationFailure) || other.stationFailure == stationFailure)&&(identical(other.suggestions, suggestions) || other.suggestions == suggestions));
}


@override
int get hashCode => Object.hash(runtimeType,query,searching,const DeepCollectionEquality().hash(stations),const DeepCollectionEquality().hash(addresses),addressSearching,stationFailure,suggestions);

@override
String toString() {
  return 'PointPickerState(query: $query, searching: $searching, stations: $stations, addresses: $addresses, addressSearching: $addressSearching, stationFailure: $stationFailure, suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class $PointPickerStateCopyWith<$Res>  {
  factory $PointPickerStateCopyWith(PointPickerState value, $Res Function(PointPickerState) _then) = _$PointPickerStateCopyWithImpl;
@useResult
$Res call({
 String query, bool searching, List<StationHit> stations, List<PlaceCandidate> addresses, bool addressSearching, TransitFailure? stationFailure, TransitSuggestions? suggestions
});




}
/// @nodoc
class _$PointPickerStateCopyWithImpl<$Res>
    implements $PointPickerStateCopyWith<$Res> {
  _$PointPickerStateCopyWithImpl(this._self, this._then);

  final PointPickerState _self;
  final $Res Function(PointPickerState) _then;

/// Create a copy of PointPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? searching = null,Object? stations = null,Object? addresses = null,Object? addressSearching = null,Object? stationFailure = freezed,Object? suggestions = freezed,}) {
  return _then(PointPickerState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,stations: null == stations ? _self.stations : stations // ignore: cast_nullable_to_non_nullable
as List<StationHit>,addresses: null == addresses ? _self.addresses : addresses // ignore: cast_nullable_to_non_nullable
as List<PlaceCandidate>,addressSearching: null == addressSearching ? _self.addressSearching : addressSearching // ignore: cast_nullable_to_non_nullable
as bool,stationFailure: freezed == stationFailure ? _self.stationFailure : stationFailure // ignore: cast_nullable_to_non_nullable
as TransitFailure?,suggestions: freezed == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as TransitSuggestions?,
  ));
}

}


/// Adds pattern-matching-related methods to [PointPickerState].
extension PointPickerStatePatterns on PointPickerState {
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
