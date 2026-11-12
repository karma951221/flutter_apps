// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkspaceState()';
}


}

/// @nodoc
class $WorkspaceStateCopyWith<$Res>  {
$WorkspaceStateCopyWith(WorkspaceState _, $Res Function(WorkspaceState) __);
}


/// Adds pattern-matching-related methods to [WorkspaceState].
extension WorkspaceStatePatterns on WorkspaceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WorkspaceLoading value)?  loading,TResult Function( WorkspaceReady value)?  ready,TResult Function( WorkspaceFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WorkspaceLoading() when loading != null:
return loading(_that);case WorkspaceReady() when ready != null:
return ready(_that);case WorkspaceFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WorkspaceLoading value)  loading,required TResult Function( WorkspaceReady value)  ready,required TResult Function( WorkspaceFailure value)  failure,}){
final _that = this;
switch (_that) {
case WorkspaceLoading():
return loading(_that);case WorkspaceReady():
return ready(_that);case WorkspaceFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WorkspaceLoading value)?  loading,TResult? Function( WorkspaceReady value)?  ready,TResult? Function( WorkspaceFailure value)?  failure,}){
final _that = this;
switch (_that) {
case WorkspaceLoading() when loading != null:
return loading(_that);case WorkspaceReady() when ready != null:
return ready(_that);case WorkspaceFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<WorkspaceFile> out,  List<WorkspaceFile> inbox,  int totalCount,  int totalBytes)?  ready,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WorkspaceLoading() when loading != null:
return loading();case WorkspaceReady() when ready != null:
return ready(_that.out,_that.inbox,_that.totalCount,_that.totalBytes);case WorkspaceFailure() when failure != null:
return failure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<WorkspaceFile> out,  List<WorkspaceFile> inbox,  int totalCount,  int totalBytes)  ready,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case WorkspaceLoading():
return loading();case WorkspaceReady():
return ready(_that.out,_that.inbox,_that.totalCount,_that.totalBytes);case WorkspaceFailure():
return failure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<WorkspaceFile> out,  List<WorkspaceFile> inbox,  int totalCount,  int totalBytes)?  ready,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case WorkspaceLoading() when loading != null:
return loading();case WorkspaceReady() when ready != null:
return ready(_that.out,_that.inbox,_that.totalCount,_that.totalBytes);case WorkspaceFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class WorkspaceLoading implements WorkspaceState {
  const WorkspaceLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkspaceState.loading()';
}


}




/// @nodoc


class WorkspaceReady implements WorkspaceState {
  const WorkspaceReady({required final  List<WorkspaceFile> out, required final  List<WorkspaceFile> inbox, required this.totalCount, required this.totalBytes}): _out = out,_inbox = inbox;
  

 final  List<WorkspaceFile> _out;
 List<WorkspaceFile> get out {
  if (_out is EqualUnmodifiableListView) return _out;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_out);
}

 final  List<WorkspaceFile> _inbox;
 List<WorkspaceFile> get inbox {
  if (_inbox is EqualUnmodifiableListView) return _inbox;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inbox);
}

 final  int totalCount;
 final  int totalBytes;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceReadyCopyWith<WorkspaceReady> get copyWith => _$WorkspaceReadyCopyWithImpl<WorkspaceReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceReady&&const DeepCollectionEquality().equals(other._out, _out)&&const DeepCollectionEquality().equals(other._inbox, _inbox)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_out),const DeepCollectionEquality().hash(_inbox),totalCount,totalBytes);

@override
String toString() {
  return 'WorkspaceState.ready(out: $out, inbox: $inbox, totalCount: $totalCount, totalBytes: $totalBytes)';
}


}

/// @nodoc
abstract mixin class $WorkspaceReadyCopyWith<$Res> implements $WorkspaceStateCopyWith<$Res> {
  factory $WorkspaceReadyCopyWith(WorkspaceReady value, $Res Function(WorkspaceReady) _then) = _$WorkspaceReadyCopyWithImpl;
@useResult
$Res call({
 List<WorkspaceFile> out, List<WorkspaceFile> inbox, int totalCount, int totalBytes
});




}
/// @nodoc
class _$WorkspaceReadyCopyWithImpl<$Res>
    implements $WorkspaceReadyCopyWith<$Res> {
  _$WorkspaceReadyCopyWithImpl(this._self, this._then);

  final WorkspaceReady _self;
  final $Res Function(WorkspaceReady) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? out = null,Object? inbox = null,Object? totalCount = null,Object? totalBytes = null,}) {
  return _then(WorkspaceReady(
out: null == out ? _self._out : out // ignore: cast_nullable_to_non_nullable
as List<WorkspaceFile>,inbox: null == inbox ? _self._inbox : inbox // ignore: cast_nullable_to_non_nullable
as List<WorkspaceFile>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class WorkspaceFailure implements WorkspaceState {
  const WorkspaceFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkspaceState.failure()';
}


}




// dart format on
