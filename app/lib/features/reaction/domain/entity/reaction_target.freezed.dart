// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reaction_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReactionTarget {

 String get id;
/// Create a copy of ReactionTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactionTargetCopyWith<ReactionTarget> get copyWith => _$ReactionTargetCopyWithImpl<ReactionTarget>(this as ReactionTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReactionTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReactionTarget(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReactionTargetCopyWith<$Res>  {
  factory $ReactionTargetCopyWith(ReactionTarget value, $Res Function(ReactionTarget) _then) = _$ReactionTargetCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReactionTargetCopyWithImpl<$Res>
    implements $ReactionTargetCopyWith<$Res> {
  _$ReactionTargetCopyWithImpl(this._self, this._then);

  final ReactionTarget _self;
  final $Res Function(ReactionTarget) _then;

/// Create a copy of ReactionTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReactionTarget].
extension ReactionTargetPatterns on ReactionTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReactionPostTarget value)?  post,TResult Function( ReactionCommentTarget value)?  comment,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReactionPostTarget() when post != null:
return post(_that);case ReactionCommentTarget() when comment != null:
return comment(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReactionPostTarget value)  post,required TResult Function( ReactionCommentTarget value)  comment,}){
final _that = this;
switch (_that) {
case ReactionPostTarget():
return post(_that);case ReactionCommentTarget():
return comment(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReactionPostTarget value)?  post,TResult? Function( ReactionCommentTarget value)?  comment,}){
final _that = this;
switch (_that) {
case ReactionPostTarget() when post != null:
return post(_that);case ReactionCommentTarget() when comment != null:
return comment(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id)?  post,TResult Function( String id)?  comment,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReactionPostTarget() when post != null:
return post(_that.id);case ReactionCommentTarget() when comment != null:
return comment(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id)  post,required TResult Function( String id)  comment,}) {final _that = this;
switch (_that) {
case ReactionPostTarget():
return post(_that.id);case ReactionCommentTarget():
return comment(_that.id);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id)?  post,TResult? Function( String id)?  comment,}) {final _that = this;
switch (_that) {
case ReactionPostTarget() when post != null:
return post(_that.id);case ReactionCommentTarget() when comment != null:
return comment(_that.id);case _:
  return null;

}
}

}

/// @nodoc


class ReactionPostTarget implements ReactionTarget {
  const ReactionPostTarget(this.id);
  

@override final  String id;

/// Create a copy of ReactionTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactionPostTargetCopyWith<ReactionPostTarget> get copyWith => _$ReactionPostTargetCopyWithImpl<ReactionPostTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReactionPostTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReactionTarget.post(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReactionPostTargetCopyWith<$Res> implements $ReactionTargetCopyWith<$Res> {
  factory $ReactionPostTargetCopyWith(ReactionPostTarget value, $Res Function(ReactionPostTarget) _then) = _$ReactionPostTargetCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReactionPostTargetCopyWithImpl<$Res>
    implements $ReactionPostTargetCopyWith<$Res> {
  _$ReactionPostTargetCopyWithImpl(this._self, this._then);

  final ReactionPostTarget _self;
  final $Res Function(ReactionPostTarget) _then;

/// Create a copy of ReactionTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ReactionPostTarget(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReactionCommentTarget implements ReactionTarget {
  const ReactionCommentTarget(this.id);
  

@override final  String id;

/// Create a copy of ReactionTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactionCommentTargetCopyWith<ReactionCommentTarget> get copyWith => _$ReactionCommentTargetCopyWithImpl<ReactionCommentTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReactionCommentTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReactionTarget.comment(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReactionCommentTargetCopyWith<$Res> implements $ReactionTargetCopyWith<$Res> {
  factory $ReactionCommentTargetCopyWith(ReactionCommentTarget value, $Res Function(ReactionCommentTarget) _then) = _$ReactionCommentTargetCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReactionCommentTargetCopyWithImpl<$Res>
    implements $ReactionCommentTargetCopyWith<$Res> {
  _$ReactionCommentTargetCopyWithImpl(this._self, this._then);

  final ReactionCommentTarget _self;
  final $Res Function(ReactionCommentTarget) _then;

/// Create a copy of ReactionTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ReactionCommentTarget(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
