// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_pick.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryPick {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryPick);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoryPick()';
}


}

/// @nodoc
class $StoryPickCopyWith<$Res>  {
$StoryPickCopyWith(StoryPick _, $Res Function(StoryPick) __);
}


/// Adds pattern-matching-related methods to [StoryPick].
extension StoryPickPatterns on StoryPick {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StoryPickExisting value)?  existing,TResult Function( StoryPickCreate value)?  create,TResult Function( StoryPickFallback value)?  fallback,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StoryPickExisting() when existing != null:
return existing(_that);case StoryPickCreate() when create != null:
return create(_that);case StoryPickFallback() when fallback != null:
return fallback(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StoryPickExisting value)  existing,required TResult Function( StoryPickCreate value)  create,required TResult Function( StoryPickFallback value)  fallback,}){
final _that = this;
switch (_that) {
case StoryPickExisting():
return existing(_that);case StoryPickCreate():
return create(_that);case StoryPickFallback():
return fallback(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StoryPickExisting value)?  existing,TResult? Function( StoryPickCreate value)?  create,TResult? Function( StoryPickFallback value)?  fallback,}){
final _that = this;
switch (_that) {
case StoryPickExisting() when existing != null:
return existing(_that);case StoryPickCreate() when create != null:
return create(_that);case StoryPickFallback() when fallback != null:
return fallback(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String storyId,  String reason)?  existing,TResult Function( String title,  String reason)?  create,TResult Function( String storyId)?  fallback,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StoryPickExisting() when existing != null:
return existing(_that.storyId,_that.reason);case StoryPickCreate() when create != null:
return create(_that.title,_that.reason);case StoryPickFallback() when fallback != null:
return fallback(_that.storyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String storyId,  String reason)  existing,required TResult Function( String title,  String reason)  create,required TResult Function( String storyId)  fallback,}) {final _that = this;
switch (_that) {
case StoryPickExisting():
return existing(_that.storyId,_that.reason);case StoryPickCreate():
return create(_that.title,_that.reason);case StoryPickFallback():
return fallback(_that.storyId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String storyId,  String reason)?  existing,TResult? Function( String title,  String reason)?  create,TResult? Function( String storyId)?  fallback,}) {final _that = this;
switch (_that) {
case StoryPickExisting() when existing != null:
return existing(_that.storyId,_that.reason);case StoryPickCreate() when create != null:
return create(_that.title,_that.reason);case StoryPickFallback() when fallback != null:
return fallback(_that.storyId);case _:
  return null;

}
}

}

/// @nodoc


class StoryPickExisting implements StoryPick {
  const StoryPickExisting({required this.storyId, required this.reason});
  

 final  String storyId;
 final  String reason;

/// Create a copy of StoryPick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryPickExistingCopyWith<StoryPickExisting> get copyWith => _$StoryPickExistingCopyWithImpl<StoryPickExisting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryPickExisting&&(identical(other.storyId, storyId) || other.storyId == storyId)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,storyId,reason);

@override
String toString() {
  return 'StoryPick.existing(storyId: $storyId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $StoryPickExistingCopyWith<$Res> implements $StoryPickCopyWith<$Res> {
  factory $StoryPickExistingCopyWith(StoryPickExisting value, $Res Function(StoryPickExisting) _then) = _$StoryPickExistingCopyWithImpl;
@useResult
$Res call({
 String storyId, String reason
});




}
/// @nodoc
class _$StoryPickExistingCopyWithImpl<$Res>
    implements $StoryPickExistingCopyWith<$Res> {
  _$StoryPickExistingCopyWithImpl(this._self, this._then);

  final StoryPickExisting _self;
  final $Res Function(StoryPickExisting) _then;

/// Create a copy of StoryPick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? storyId = null,Object? reason = null,}) {
  return _then(StoryPickExisting(
storyId: null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StoryPickCreate implements StoryPick {
  const StoryPickCreate({required this.title, required this.reason});
  

 final  String title;
 final  String reason;

/// Create a copy of StoryPick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryPickCreateCopyWith<StoryPickCreate> get copyWith => _$StoryPickCreateCopyWithImpl<StoryPickCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryPickCreate&&(identical(other.title, title) || other.title == title)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,title,reason);

@override
String toString() {
  return 'StoryPick.create(title: $title, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $StoryPickCreateCopyWith<$Res> implements $StoryPickCopyWith<$Res> {
  factory $StoryPickCreateCopyWith(StoryPickCreate value, $Res Function(StoryPickCreate) _then) = _$StoryPickCreateCopyWithImpl;
@useResult
$Res call({
 String title, String reason
});




}
/// @nodoc
class _$StoryPickCreateCopyWithImpl<$Res>
    implements $StoryPickCreateCopyWith<$Res> {
  _$StoryPickCreateCopyWithImpl(this._self, this._then);

  final StoryPickCreate _self;
  final $Res Function(StoryPickCreate) _then;

/// Create a copy of StoryPick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? reason = null,}) {
  return _then(StoryPickCreate(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StoryPickFallback implements StoryPick {
  const StoryPickFallback(this.storyId);
  

 final  String storyId;

/// Create a copy of StoryPick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryPickFallbackCopyWith<StoryPickFallback> get copyWith => _$StoryPickFallbackCopyWithImpl<StoryPickFallback>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryPickFallback&&(identical(other.storyId, storyId) || other.storyId == storyId));
}


@override
int get hashCode => Object.hash(runtimeType,storyId);

@override
String toString() {
  return 'StoryPick.fallback(storyId: $storyId)';
}


}

/// @nodoc
abstract mixin class $StoryPickFallbackCopyWith<$Res> implements $StoryPickCopyWith<$Res> {
  factory $StoryPickFallbackCopyWith(StoryPickFallback value, $Res Function(StoryPickFallback) _then) = _$StoryPickFallbackCopyWithImpl;
@useResult
$Res call({
 String storyId
});




}
/// @nodoc
class _$StoryPickFallbackCopyWithImpl<$Res>
    implements $StoryPickFallbackCopyWith<$Res> {
  _$StoryPickFallbackCopyWithImpl(this._self, this._then);

  final StoryPickFallback _self;
  final $Res Function(StoryPickFallback) _then;

/// Create a copy of StoryPick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? storyId = null,}) {
  return _then(StoryPickFallback(
null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
