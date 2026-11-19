// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_suggestion_sheet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StorySuggestionChoice {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorySuggestionChoice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StorySuggestionChoice()';
}


}

/// @nodoc
class $StorySuggestionChoiceCopyWith<$Res>  {
$StorySuggestionChoiceCopyWith(StorySuggestionChoice _, $Res Function(StorySuggestionChoice) __);
}


/// Adds pattern-matching-related methods to [StorySuggestionChoice].
extension StorySuggestionChoicePatterns on StorySuggestionChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StorySuggestionAccept value)?  accept,TResult Function( StorySuggestionCreate value)?  create,TResult Function( StorySuggestionOther value)?  other,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StorySuggestionAccept() when accept != null:
return accept(_that);case StorySuggestionCreate() when create != null:
return create(_that);case StorySuggestionOther() when other != null:
return other(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StorySuggestionAccept value)  accept,required TResult Function( StorySuggestionCreate value)  create,required TResult Function( StorySuggestionOther value)  other,}){
final _that = this;
switch (_that) {
case StorySuggestionAccept():
return accept(_that);case StorySuggestionCreate():
return create(_that);case StorySuggestionOther():
return other(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StorySuggestionAccept value)?  accept,TResult? Function( StorySuggestionCreate value)?  create,TResult? Function( StorySuggestionOther value)?  other,}){
final _that = this;
switch (_that) {
case StorySuggestionAccept() when accept != null:
return accept(_that);case StorySuggestionCreate() when create != null:
return create(_that);case StorySuggestionOther() when other != null:
return other(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String storyId)?  accept,TResult Function( String title)?  create,TResult Function()?  other,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StorySuggestionAccept() when accept != null:
return accept(_that.storyId);case StorySuggestionCreate() when create != null:
return create(_that.title);case StorySuggestionOther() when other != null:
return other();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String storyId)  accept,required TResult Function( String title)  create,required TResult Function()  other,}) {final _that = this;
switch (_that) {
case StorySuggestionAccept():
return accept(_that.storyId);case StorySuggestionCreate():
return create(_that.title);case StorySuggestionOther():
return other();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String storyId)?  accept,TResult? Function( String title)?  create,TResult? Function()?  other,}) {final _that = this;
switch (_that) {
case StorySuggestionAccept() when accept != null:
return accept(_that.storyId);case StorySuggestionCreate() when create != null:
return create(_that.title);case StorySuggestionOther() when other != null:
return other();case _:
  return null;

}
}

}

/// @nodoc


class StorySuggestionAccept implements StorySuggestionChoice {
  const StorySuggestionAccept(this.storyId);
  

 final  String storyId;

/// Create a copy of StorySuggestionChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorySuggestionAcceptCopyWith<StorySuggestionAccept> get copyWith => _$StorySuggestionAcceptCopyWithImpl<StorySuggestionAccept>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorySuggestionAccept&&(identical(other.storyId, storyId) || other.storyId == storyId));
}


@override
int get hashCode => Object.hash(runtimeType,storyId);

@override
String toString() {
  return 'StorySuggestionChoice.accept(storyId: $storyId)';
}


}

/// @nodoc
abstract mixin class $StorySuggestionAcceptCopyWith<$Res> implements $StorySuggestionChoiceCopyWith<$Res> {
  factory $StorySuggestionAcceptCopyWith(StorySuggestionAccept value, $Res Function(StorySuggestionAccept) _then) = _$StorySuggestionAcceptCopyWithImpl;
@useResult
$Res call({
 String storyId
});




}
/// @nodoc
class _$StorySuggestionAcceptCopyWithImpl<$Res>
    implements $StorySuggestionAcceptCopyWith<$Res> {
  _$StorySuggestionAcceptCopyWithImpl(this._self, this._then);

  final StorySuggestionAccept _self;
  final $Res Function(StorySuggestionAccept) _then;

/// Create a copy of StorySuggestionChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? storyId = null,}) {
  return _then(StorySuggestionAccept(
null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StorySuggestionCreate implements StorySuggestionChoice {
  const StorySuggestionCreate(this.title);
  

 final  String title;

/// Create a copy of StorySuggestionChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorySuggestionCreateCopyWith<StorySuggestionCreate> get copyWith => _$StorySuggestionCreateCopyWithImpl<StorySuggestionCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorySuggestionCreate&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,title);

@override
String toString() {
  return 'StorySuggestionChoice.create(title: $title)';
}


}

/// @nodoc
abstract mixin class $StorySuggestionCreateCopyWith<$Res> implements $StorySuggestionChoiceCopyWith<$Res> {
  factory $StorySuggestionCreateCopyWith(StorySuggestionCreate value, $Res Function(StorySuggestionCreate) _then) = _$StorySuggestionCreateCopyWithImpl;
@useResult
$Res call({
 String title
});




}
/// @nodoc
class _$StorySuggestionCreateCopyWithImpl<$Res>
    implements $StorySuggestionCreateCopyWith<$Res> {
  _$StorySuggestionCreateCopyWithImpl(this._self, this._then);

  final StorySuggestionCreate _self;
  final $Res Function(StorySuggestionCreate) _then;

/// Create a copy of StorySuggestionChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,}) {
  return _then(StorySuggestionCreate(
null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StorySuggestionOther implements StorySuggestionChoice {
  const StorySuggestionOther();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorySuggestionOther);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StorySuggestionChoice.other()';
}


}




// dart format on
