// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wiki_distill_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CandidateItem {

 WikiCandidate get candidate; WikiNote? get current; CandidateStatus get status;
/// Create a copy of CandidateItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandidateItemCopyWith<CandidateItem> get copyWith => _$CandidateItemCopyWithImpl<CandidateItem>(this as CandidateItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CandidateItem&&(identical(other.candidate, candidate) || other.candidate == candidate)&&(identical(other.current, current) || other.current == current)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,candidate,current,status);



}

/// @nodoc
abstract mixin class $CandidateItemCopyWith<$Res>  {
  factory $CandidateItemCopyWith(CandidateItem value, $Res Function(CandidateItem) _then) = _$CandidateItemCopyWithImpl;
@useResult
$Res call({
 WikiCandidate candidate, WikiNote? current, CandidateStatus status
});




}
/// @nodoc
class _$CandidateItemCopyWithImpl<$Res>
    implements $CandidateItemCopyWith<$Res> {
  _$CandidateItemCopyWithImpl(this._self, this._then);

  final CandidateItem _self;
  final $Res Function(CandidateItem) _then;

/// Create a copy of CandidateItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? candidate = null,Object? current = freezed,Object? status = null,}) {
  return _then(CandidateItem(
candidate: null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as WikiCandidate,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as WikiNote?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CandidateStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [CandidateItem].
extension CandidateItemPatterns on CandidateItem {
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

/// @nodoc
mixin _$WikiDistillState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillState);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $WikiDistillStateCopyWith<$Res>  {
$WikiDistillStateCopyWith(WikiDistillState _, $Res Function(WikiDistillState) __);
}


/// Adds pattern-matching-related methods to [WikiDistillState].
extension WikiDistillStatePatterns on WikiDistillState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WikiDistillLoading value)?  loading,TResult Function( WikiDistillReady value)?  ready,TResult Function( WikiDistillFailedState value)?  failed,TResult Function( WikiDistillUnparsableState value)?  unparsable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WikiDistillLoading() when loading != null:
return loading(_that);case WikiDistillReady() when ready != null:
return ready(_that);case WikiDistillFailedState() when failed != null:
return failed(_that);case WikiDistillUnparsableState() when unparsable != null:
return unparsable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WikiDistillLoading value)  loading,required TResult Function( WikiDistillReady value)  ready,required TResult Function( WikiDistillFailedState value)  failed,required TResult Function( WikiDistillUnparsableState value)  unparsable,}){
final _that = this;
switch (_that) {
case WikiDistillLoading():
return loading(_that);case WikiDistillReady():
return ready(_that);case WikiDistillFailedState():
return failed(_that);case WikiDistillUnparsableState():
return unparsable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WikiDistillLoading value)?  loading,TResult? Function( WikiDistillReady value)?  ready,TResult? Function( WikiDistillFailedState value)?  failed,TResult? Function( WikiDistillUnparsableState value)?  unparsable,}){
final _that = this;
switch (_that) {
case WikiDistillLoading() when loading != null:
return loading(_that);case WikiDistillReady() when ready != null:
return ready(_that);case WikiDistillFailedState() when failed != null:
return failed(_that);case WikiDistillUnparsableState() when unparsable != null:
return unparsable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<CandidateItem> items,  Map<int, WikiNote> notes,  Map<String, DiaryEntry> entries,  List<String> citedEntryIds)?  ready,TResult Function( ChatFailure failure)?  failed,TResult Function()?  unparsable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WikiDistillLoading() when loading != null:
return loading();case WikiDistillReady() when ready != null:
return ready(_that.items,_that.notes,_that.entries,_that.citedEntryIds);case WikiDistillFailedState() when failed != null:
return failed(_that.failure);case WikiDistillUnparsableState() when unparsable != null:
return unparsable();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<CandidateItem> items,  Map<int, WikiNote> notes,  Map<String, DiaryEntry> entries,  List<String> citedEntryIds)  ready,required TResult Function( ChatFailure failure)  failed,required TResult Function()  unparsable,}) {final _that = this;
switch (_that) {
case WikiDistillLoading():
return loading();case WikiDistillReady():
return ready(_that.items,_that.notes,_that.entries,_that.citedEntryIds);case WikiDistillFailedState():
return failed(_that.failure);case WikiDistillUnparsableState():
return unparsable();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<CandidateItem> items,  Map<int, WikiNote> notes,  Map<String, DiaryEntry> entries,  List<String> citedEntryIds)?  ready,TResult? Function( ChatFailure failure)?  failed,TResult? Function()?  unparsable,}) {final _that = this;
switch (_that) {
case WikiDistillLoading() when loading != null:
return loading();case WikiDistillReady() when ready != null:
return ready(_that.items,_that.notes,_that.entries,_that.citedEntryIds);case WikiDistillFailedState() when failed != null:
return failed(_that.failure);case WikiDistillUnparsableState() when unparsable != null:
return unparsable();case _:
  return null;

}
}

}

/// @nodoc


class WikiDistillLoading extends WikiDistillState {
  const WikiDistillLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillLoading);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class WikiDistillReady extends WikiDistillState {
  const WikiDistillReady(final  List<CandidateItem> items, {final  Map<int, WikiNote> notes = const {}, final  Map<String, DiaryEntry> entries = const {}, final  List<String> citedEntryIds = const []}): _items = items,_notes = notes,_entries = entries,_citedEntryIds = citedEntryIds,super._();
  

 final  List<CandidateItem> _items;
 List<CandidateItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  Map<int, WikiNote> _notes;
@JsonKey() Map<int, WikiNote> get notes {
  if (_notes is EqualUnmodifiableMapView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_notes);
}

 final  Map<String, DiaryEntry> _entries;
@JsonKey() Map<String, DiaryEntry> get entries {
  if (_entries is EqualUnmodifiableMapView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_entries);
}

 final  List<String> _citedEntryIds;
@JsonKey() List<String> get citedEntryIds {
  if (_citedEntryIds is EqualUnmodifiableListView) return _citedEntryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citedEntryIds);
}


/// Create a copy of WikiDistillState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiDistillReadyCopyWith<WikiDistillReady> get copyWith => _$WikiDistillReadyCopyWithImpl<WikiDistillReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillReady&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._notes, _notes)&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._citedEntryIds, _citedEntryIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_notes),const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_citedEntryIds));



}

/// @nodoc
abstract mixin class $WikiDistillReadyCopyWith<$Res> implements $WikiDistillStateCopyWith<$Res> {
  factory $WikiDistillReadyCopyWith(WikiDistillReady value, $Res Function(WikiDistillReady) _then) = _$WikiDistillReadyCopyWithImpl;
@useResult
$Res call({
 List<CandidateItem> items, Map<int, WikiNote> notes, Map<String, DiaryEntry> entries, List<String> citedEntryIds
});




}
/// @nodoc
class _$WikiDistillReadyCopyWithImpl<$Res>
    implements $WikiDistillReadyCopyWith<$Res> {
  _$WikiDistillReadyCopyWithImpl(this._self, this._then);

  final WikiDistillReady _self;
  final $Res Function(WikiDistillReady) _then;

/// Create a copy of WikiDistillState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? notes = null,Object? entries = null,Object? citedEntryIds = null,}) {
  return _then(WikiDistillReady(
null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CandidateItem>,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as Map<int, WikiNote>,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as Map<String, DiaryEntry>,citedEntryIds: null == citedEntryIds ? _self._citedEntryIds : citedEntryIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class WikiDistillFailedState extends WikiDistillState {
  const WikiDistillFailedState(this.failure): super._();
  

 final  ChatFailure failure;

/// Create a copy of WikiDistillState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiDistillFailedStateCopyWith<WikiDistillFailedState> get copyWith => _$WikiDistillFailedStateCopyWithImpl<WikiDistillFailedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillFailedState&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);



}

/// @nodoc
abstract mixin class $WikiDistillFailedStateCopyWith<$Res> implements $WikiDistillStateCopyWith<$Res> {
  factory $WikiDistillFailedStateCopyWith(WikiDistillFailedState value, $Res Function(WikiDistillFailedState) _then) = _$WikiDistillFailedStateCopyWithImpl;
@useResult
$Res call({
 ChatFailure failure
});




}
/// @nodoc
class _$WikiDistillFailedStateCopyWithImpl<$Res>
    implements $WikiDistillFailedStateCopyWith<$Res> {
  _$WikiDistillFailedStateCopyWithImpl(this._self, this._then);

  final WikiDistillFailedState _self;
  final $Res Function(WikiDistillFailedState) _then;

/// Create a copy of WikiDistillState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WikiDistillFailedState(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ChatFailure,
  ));
}


}

/// @nodoc


class WikiDistillUnparsableState extends WikiDistillState {
  const WikiDistillUnparsableState(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillUnparsableState);
}


@override
int get hashCode => runtimeType.hashCode;



}




// dart format on
