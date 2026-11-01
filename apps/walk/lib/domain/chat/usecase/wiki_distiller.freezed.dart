// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wiki_distiller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WikiDistillResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WikiDistillResult()';
}


}

/// @nodoc
class $WikiDistillResultCopyWith<$Res>  {
$WikiDistillResultCopyWith(WikiDistillResult _, $Res Function(WikiDistillResult) __);
}


/// Adds pattern-matching-related methods to [WikiDistillResult].
extension WikiDistillResultPatterns on WikiDistillResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WikiDistillCandidates value)?  candidates,TResult Function( WikiDistillFailed value)?  failed,TResult Function( WikiDistillUnparsable value)?  unparsable,TResult Function( WikiDistillCancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WikiDistillCandidates() when candidates != null:
return candidates(_that);case WikiDistillFailed() when failed != null:
return failed(_that);case WikiDistillUnparsable() when unparsable != null:
return unparsable(_that);case WikiDistillCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WikiDistillCandidates value)  candidates,required TResult Function( WikiDistillFailed value)  failed,required TResult Function( WikiDistillUnparsable value)  unparsable,required TResult Function( WikiDistillCancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case WikiDistillCandidates():
return candidates(_that);case WikiDistillFailed():
return failed(_that);case WikiDistillUnparsable():
return unparsable(_that);case WikiDistillCancelled():
return cancelled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WikiDistillCandidates value)?  candidates,TResult? Function( WikiDistillFailed value)?  failed,TResult? Function( WikiDistillUnparsable value)?  unparsable,TResult? Function( WikiDistillCancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case WikiDistillCandidates() when candidates != null:
return candidates(_that);case WikiDistillFailed() when failed != null:
return failed(_that);case WikiDistillUnparsable() when unparsable != null:
return unparsable(_that);case WikiDistillCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<WikiCandidate> candidates)?  candidates,TResult Function( ChatFailure failure)?  failed,TResult Function()?  unparsable,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WikiDistillCandidates() when candidates != null:
return candidates(_that.candidates);case WikiDistillFailed() when failed != null:
return failed(_that.failure);case WikiDistillUnparsable() when unparsable != null:
return unparsable();case WikiDistillCancelled() when cancelled != null:
return cancelled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<WikiCandidate> candidates)  candidates,required TResult Function( ChatFailure failure)  failed,required TResult Function()  unparsable,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case WikiDistillCandidates():
return candidates(_that.candidates);case WikiDistillFailed():
return failed(_that.failure);case WikiDistillUnparsable():
return unparsable();case WikiDistillCancelled():
return cancelled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<WikiCandidate> candidates)?  candidates,TResult? Function( ChatFailure failure)?  failed,TResult? Function()?  unparsable,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case WikiDistillCandidates() when candidates != null:
return candidates(_that.candidates);case WikiDistillFailed() when failed != null:
return failed(_that.failure);case WikiDistillUnparsable() when unparsable != null:
return unparsable();case WikiDistillCancelled() when cancelled != null:
return cancelled();case _:
  return null;

}
}

}

/// @nodoc


class WikiDistillCandidates implements WikiDistillResult {
  const WikiDistillCandidates(final  List<WikiCandidate> candidates): _candidates = candidates;
  

 final  List<WikiCandidate> _candidates;
 List<WikiCandidate> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}


/// Create a copy of WikiDistillResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiDistillCandidatesCopyWith<WikiDistillCandidates> get copyWith => _$WikiDistillCandidatesCopyWithImpl<WikiDistillCandidates>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillCandidates&&const DeepCollectionEquality().equals(other._candidates, _candidates));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_candidates));

@override
String toString() {
  return 'WikiDistillResult.candidates(candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class $WikiDistillCandidatesCopyWith<$Res> implements $WikiDistillResultCopyWith<$Res> {
  factory $WikiDistillCandidatesCopyWith(WikiDistillCandidates value, $Res Function(WikiDistillCandidates) _then) = _$WikiDistillCandidatesCopyWithImpl;
@useResult
$Res call({
 List<WikiCandidate> candidates
});




}
/// @nodoc
class _$WikiDistillCandidatesCopyWithImpl<$Res>
    implements $WikiDistillCandidatesCopyWith<$Res> {
  _$WikiDistillCandidatesCopyWithImpl(this._self, this._then);

  final WikiDistillCandidates _self;
  final $Res Function(WikiDistillCandidates) _then;

/// Create a copy of WikiDistillResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? candidates = null,}) {
  return _then(WikiDistillCandidates(
null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<WikiCandidate>,
  ));
}


}

/// @nodoc


class WikiDistillFailed implements WikiDistillResult {
  const WikiDistillFailed(this.failure);
  

 final  ChatFailure failure;

/// Create a copy of WikiDistillResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiDistillFailedCopyWith<WikiDistillFailed> get copyWith => _$WikiDistillFailedCopyWithImpl<WikiDistillFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'WikiDistillResult.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WikiDistillFailedCopyWith<$Res> implements $WikiDistillResultCopyWith<$Res> {
  factory $WikiDistillFailedCopyWith(WikiDistillFailed value, $Res Function(WikiDistillFailed) _then) = _$WikiDistillFailedCopyWithImpl;
@useResult
$Res call({
 ChatFailure failure
});




}
/// @nodoc
class _$WikiDistillFailedCopyWithImpl<$Res>
    implements $WikiDistillFailedCopyWith<$Res> {
  _$WikiDistillFailedCopyWithImpl(this._self, this._then);

  final WikiDistillFailed _self;
  final $Res Function(WikiDistillFailed) _then;

/// Create a copy of WikiDistillResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WikiDistillFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ChatFailure,
  ));
}


}

/// @nodoc


class WikiDistillUnparsable implements WikiDistillResult {
  const WikiDistillUnparsable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillUnparsable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WikiDistillResult.unparsable()';
}


}




/// @nodoc


class WikiDistillCancelled implements WikiDistillResult {
  const WikiDistillCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDistillCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WikiDistillResult.cancelled()';
}


}




// dart format on
