// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModelEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelEvent()';
}


}

/// @nodoc
class $ModelEventCopyWith<$Res>  {
$ModelEventCopyWith(ModelEvent _, $Res Function(ModelEvent) __);
}


/// Adds pattern-matching-related methods to [ModelEvent].
extension ModelEventPatterns on ModelEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ModelTextDelta value)?  textDelta,TResult Function( ModelCompleted value)?  completed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that);case ModelCompleted() when completed != null:
return completed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ModelTextDelta value)  textDelta,required TResult Function( ModelCompleted value)  completed,}){
final _that = this;
switch (_that) {
case ModelTextDelta():
return textDelta(_that);case ModelCompleted():
return completed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ModelTextDelta value)?  textDelta,TResult? Function( ModelCompleted value)?  completed,}){
final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that);case ModelCompleted() when completed != null:
return completed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  textDelta,TResult Function( List<Map<String, Object?>> content,  String stopReason)?  completed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that.text);case ModelCompleted() when completed != null:
return completed(_that.content,_that.stopReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  textDelta,required TResult Function( List<Map<String, Object?>> content,  String stopReason)  completed,}) {final _that = this;
switch (_that) {
case ModelTextDelta():
return textDelta(_that.text);case ModelCompleted():
return completed(_that.content,_that.stopReason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  textDelta,TResult? Function( List<Map<String, Object?>> content,  String stopReason)?  completed,}) {final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that.text);case ModelCompleted() when completed != null:
return completed(_that.content,_that.stopReason);case _:
  return null;

}
}

}

/// @nodoc


class ModelTextDelta implements ModelEvent {
  const ModelTextDelta(this.text);
  

 final  String text;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelTextDeltaCopyWith<ModelTextDelta> get copyWith => _$ModelTextDeltaCopyWithImpl<ModelTextDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelTextDelta&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ModelEvent.textDelta(text: $text)';
}


}

/// @nodoc
abstract mixin class $ModelTextDeltaCopyWith<$Res> implements $ModelEventCopyWith<$Res> {
  factory $ModelTextDeltaCopyWith(ModelTextDelta value, $Res Function(ModelTextDelta) _then) = _$ModelTextDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ModelTextDeltaCopyWithImpl<$Res>
    implements $ModelTextDeltaCopyWith<$Res> {
  _$ModelTextDeltaCopyWithImpl(this._self, this._then);

  final ModelTextDelta _self;
  final $Res Function(ModelTextDelta) _then;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(ModelTextDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ModelCompleted implements ModelEvent {
  const ModelCompleted({required final  List<Map<String, Object?>> content, required this.stopReason}): _content = content;
  

 final  List<Map<String, Object?>> _content;
 List<Map<String, Object?>> get content {
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_content);
}

 final  String stopReason;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelCompletedCopyWith<ModelCompleted> get copyWith => _$ModelCompletedCopyWithImpl<ModelCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelCompleted&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.stopReason, stopReason) || other.stopReason == stopReason));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_content),stopReason);

@override
String toString() {
  return 'ModelEvent.completed(content: $content, stopReason: $stopReason)';
}


}

/// @nodoc
abstract mixin class $ModelCompletedCopyWith<$Res> implements $ModelEventCopyWith<$Res> {
  factory $ModelCompletedCopyWith(ModelCompleted value, $Res Function(ModelCompleted) _then) = _$ModelCompletedCopyWithImpl;
@useResult
$Res call({
 List<Map<String, Object?>> content, String stopReason
});




}
/// @nodoc
class _$ModelCompletedCopyWithImpl<$Res>
    implements $ModelCompletedCopyWith<$Res> {
  _$ModelCompletedCopyWithImpl(this._self, this._then);

  final ModelCompleted _self;
  final $Res Function(ModelCompleted) _then;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? content = null,Object? stopReason = null,}) {
  return _then(ModelCompleted(
content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,stopReason: null == stopReason ? _self.stopReason : stopReason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
