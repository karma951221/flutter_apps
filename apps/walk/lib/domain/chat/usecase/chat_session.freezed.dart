// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatEvent()';
}


}

/// @nodoc
class $ChatEventCopyWith<$Res>  {
$ChatEventCopyWith(ChatEvent _, $Res Function(ChatEvent) __);
}


/// Adds pattern-matching-related methods to [ChatEvent].
extension ChatEventPatterns on ChatEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatText value)?  text,TResult Function( ChatToolStarted value)?  toolStarted,TResult Function( ChatFinished value)?  finished,TResult Function( ChatFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatText() when text != null:
return text(_that);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that);case ChatFinished() when finished != null:
return finished(_that);case ChatFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatText value)  text,required TResult Function( ChatToolStarted value)  toolStarted,required TResult Function( ChatFinished value)  finished,required TResult Function( ChatFailed value)  failed,}){
final _that = this;
switch (_that) {
case ChatText():
return text(_that);case ChatToolStarted():
return toolStarted(_that);case ChatFinished():
return finished(_that);case ChatFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatText value)?  text,TResult? Function( ChatToolStarted value)?  toolStarted,TResult? Function( ChatFinished value)?  finished,TResult? Function( ChatFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ChatText() when text != null:
return text(_that);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that);case ChatFinished() when finished != null:
return finished(_that);case ChatFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String delta)?  text,TResult Function( String toolName)?  toolStarted,TResult Function( List<String> citedEntryIds)?  finished,TResult Function( ChatFailure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatText() when text != null:
return text(_that.delta);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that.toolName);case ChatFinished() when finished != null:
return finished(_that.citedEntryIds);case ChatFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String delta)  text,required TResult Function( String toolName)  toolStarted,required TResult Function( List<String> citedEntryIds)  finished,required TResult Function( ChatFailure failure)  failed,}) {final _that = this;
switch (_that) {
case ChatText():
return text(_that.delta);case ChatToolStarted():
return toolStarted(_that.toolName);case ChatFinished():
return finished(_that.citedEntryIds);case ChatFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String delta)?  text,TResult? Function( String toolName)?  toolStarted,TResult? Function( List<String> citedEntryIds)?  finished,TResult? Function( ChatFailure failure)?  failed,}) {final _that = this;
switch (_that) {
case ChatText() when text != null:
return text(_that.delta);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that.toolName);case ChatFinished() when finished != null:
return finished(_that.citedEntryIds);case ChatFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ChatText implements ChatEvent {
  const ChatText(this.delta);
  

 final  String delta;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTextCopyWith<ChatText> get copyWith => _$ChatTextCopyWithImpl<ChatText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatText&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode => Object.hash(runtimeType,delta);

@override
String toString() {
  return 'ChatEvent.text(delta: $delta)';
}


}

/// @nodoc
abstract mixin class $ChatTextCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatTextCopyWith(ChatText value, $Res Function(ChatText) _then) = _$ChatTextCopyWithImpl;
@useResult
$Res call({
 String delta
});




}
/// @nodoc
class _$ChatTextCopyWithImpl<$Res>
    implements $ChatTextCopyWith<$Res> {
  _$ChatTextCopyWithImpl(this._self, this._then);

  final ChatText _self;
  final $Res Function(ChatText) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? delta = null,}) {
  return _then(ChatText(
null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatToolStarted implements ChatEvent {
  const ChatToolStarted(this.toolName);
  

 final  String toolName;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolStartedCopyWith<ChatToolStarted> get copyWith => _$ChatToolStartedCopyWithImpl<ChatToolStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolStarted&&(identical(other.toolName, toolName) || other.toolName == toolName));
}


@override
int get hashCode => Object.hash(runtimeType,toolName);

@override
String toString() {
  return 'ChatEvent.toolStarted(toolName: $toolName)';
}


}

/// @nodoc
abstract mixin class $ChatToolStartedCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatToolStartedCopyWith(ChatToolStarted value, $Res Function(ChatToolStarted) _then) = _$ChatToolStartedCopyWithImpl;
@useResult
$Res call({
 String toolName
});




}
/// @nodoc
class _$ChatToolStartedCopyWithImpl<$Res>
    implements $ChatToolStartedCopyWith<$Res> {
  _$ChatToolStartedCopyWithImpl(this._self, this._then);

  final ChatToolStarted _self;
  final $Res Function(ChatToolStarted) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? toolName = null,}) {
  return _then(ChatToolStarted(
null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatFinished implements ChatEvent {
  const ChatFinished({required final  List<String> citedEntryIds}): _citedEntryIds = citedEntryIds;
  

 final  List<String> _citedEntryIds;
 List<String> get citedEntryIds {
  if (_citedEntryIds is EqualUnmodifiableListView) return _citedEntryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citedEntryIds);
}


/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatFinishedCopyWith<ChatFinished> get copyWith => _$ChatFinishedCopyWithImpl<ChatFinished>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatFinished&&const DeepCollectionEquality().equals(other._citedEntryIds, _citedEntryIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_citedEntryIds));

@override
String toString() {
  return 'ChatEvent.finished(citedEntryIds: $citedEntryIds)';
}


}

/// @nodoc
abstract mixin class $ChatFinishedCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatFinishedCopyWith(ChatFinished value, $Res Function(ChatFinished) _then) = _$ChatFinishedCopyWithImpl;
@useResult
$Res call({
 List<String> citedEntryIds
});




}
/// @nodoc
class _$ChatFinishedCopyWithImpl<$Res>
    implements $ChatFinishedCopyWith<$Res> {
  _$ChatFinishedCopyWithImpl(this._self, this._then);

  final ChatFinished _self;
  final $Res Function(ChatFinished) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? citedEntryIds = null,}) {
  return _then(ChatFinished(
citedEntryIds: null == citedEntryIds ? _self._citedEntryIds : citedEntryIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class ChatFailed implements ChatEvent {
  const ChatFailed(this.failure);
  

 final  ChatFailure failure;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatFailedCopyWith<ChatFailed> get copyWith => _$ChatFailedCopyWithImpl<ChatFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ChatEvent.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ChatFailedCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatFailedCopyWith(ChatFailed value, $Res Function(ChatFailed) _then) = _$ChatFailedCopyWithImpl;
@useResult
$Res call({
 ChatFailure failure
});




}
/// @nodoc
class _$ChatFailedCopyWithImpl<$Res>
    implements $ChatFailedCopyWith<$Res> {
  _$ChatFailedCopyWithImpl(this._self, this._then);

  final ChatFailed _self;
  final $Res Function(ChatFailed) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ChatFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ChatFailure,
  ));
}


}

// dart format on
