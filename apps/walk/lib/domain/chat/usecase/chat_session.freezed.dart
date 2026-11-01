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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatPhaseChanged value)?  phase,TResult Function( ChatProgressNote value)?  progress,TResult Function( ChatToolStarted value)?  toolStarted,TResult Function( ChatToolFinished value)?  toolFinished,TResult Function( ChatRoundStarted value)?  roundStarted,TResult Function( ChatText value)?  text,TResult Function( ChatFinished value)?  finished,TResult Function( ChatFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatPhaseChanged() when phase != null:
return phase(_that);case ChatProgressNote() when progress != null:
return progress(_that);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that);case ChatToolFinished() when toolFinished != null:
return toolFinished(_that);case ChatRoundStarted() when roundStarted != null:
return roundStarted(_that);case ChatText() when text != null:
return text(_that);case ChatFinished() when finished != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatPhaseChanged value)  phase,required TResult Function( ChatProgressNote value)  progress,required TResult Function( ChatToolStarted value)  toolStarted,required TResult Function( ChatToolFinished value)  toolFinished,required TResult Function( ChatRoundStarted value)  roundStarted,required TResult Function( ChatText value)  text,required TResult Function( ChatFinished value)  finished,required TResult Function( ChatFailed value)  failed,}){
final _that = this;
switch (_that) {
case ChatPhaseChanged():
return phase(_that);case ChatProgressNote():
return progress(_that);case ChatToolStarted():
return toolStarted(_that);case ChatToolFinished():
return toolFinished(_that);case ChatRoundStarted():
return roundStarted(_that);case ChatText():
return text(_that);case ChatFinished():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatPhaseChanged value)?  phase,TResult? Function( ChatProgressNote value)?  progress,TResult? Function( ChatToolStarted value)?  toolStarted,TResult? Function( ChatToolFinished value)?  toolFinished,TResult? Function( ChatRoundStarted value)?  roundStarted,TResult? Function( ChatText value)?  text,TResult? Function( ChatFinished value)?  finished,TResult? Function( ChatFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ChatPhaseChanged() when phase != null:
return phase(_that);case ChatProgressNote() when progress != null:
return progress(_that);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that);case ChatToolFinished() when toolFinished != null:
return toolFinished(_that);case ChatRoundStarted() when roundStarted != null:
return roundStarted(_that);case ChatText() when text != null:
return text(_that);case ChatFinished() when finished != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ChatPhase phase)?  phase,TResult Function( String note)?  progress,TResult Function( String callId,  String name,  ToolInputSummary? input)?  toolStarted,TResult Function( String callId,  String name,  ToolSummary summary)?  toolFinished,TResult Function( int round)?  roundStarted,TResult Function( String delta)?  text,TResult Function( List<String> citedEntryIds)?  finished,TResult Function( ChatFailure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatPhaseChanged() when phase != null:
return phase(_that.phase);case ChatProgressNote() when progress != null:
return progress(_that.note);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that.callId,_that.name,_that.input);case ChatToolFinished() when toolFinished != null:
return toolFinished(_that.callId,_that.name,_that.summary);case ChatRoundStarted() when roundStarted != null:
return roundStarted(_that.round);case ChatText() when text != null:
return text(_that.delta);case ChatFinished() when finished != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ChatPhase phase)  phase,required TResult Function( String note)  progress,required TResult Function( String callId,  String name,  ToolInputSummary? input)  toolStarted,required TResult Function( String callId,  String name,  ToolSummary summary)  toolFinished,required TResult Function( int round)  roundStarted,required TResult Function( String delta)  text,required TResult Function( List<String> citedEntryIds)  finished,required TResult Function( ChatFailure failure)  failed,}) {final _that = this;
switch (_that) {
case ChatPhaseChanged():
return phase(_that.phase);case ChatProgressNote():
return progress(_that.note);case ChatToolStarted():
return toolStarted(_that.callId,_that.name,_that.input);case ChatToolFinished():
return toolFinished(_that.callId,_that.name,_that.summary);case ChatRoundStarted():
return roundStarted(_that.round);case ChatText():
return text(_that.delta);case ChatFinished():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ChatPhase phase)?  phase,TResult? Function( String note)?  progress,TResult? Function( String callId,  String name,  ToolInputSummary? input)?  toolStarted,TResult? Function( String callId,  String name,  ToolSummary summary)?  toolFinished,TResult? Function( int round)?  roundStarted,TResult? Function( String delta)?  text,TResult? Function( List<String> citedEntryIds)?  finished,TResult? Function( ChatFailure failure)?  failed,}) {final _that = this;
switch (_that) {
case ChatPhaseChanged() when phase != null:
return phase(_that.phase);case ChatProgressNote() when progress != null:
return progress(_that.note);case ChatToolStarted() when toolStarted != null:
return toolStarted(_that.callId,_that.name,_that.input);case ChatToolFinished() when toolFinished != null:
return toolFinished(_that.callId,_that.name,_that.summary);case ChatRoundStarted() when roundStarted != null:
return roundStarted(_that.round);case ChatText() when text != null:
return text(_that.delta);case ChatFinished() when finished != null:
return finished(_that.citedEntryIds);case ChatFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ChatPhaseChanged extends ChatEvent {
  const ChatPhaseChanged(this.phase): super._();
  

 final  ChatPhase phase;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatPhaseChangedCopyWith<ChatPhaseChanged> get copyWith => _$ChatPhaseChangedCopyWithImpl<ChatPhaseChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatPhaseChanged&&(identical(other.phase, phase) || other.phase == phase));
}


@override
int get hashCode => Object.hash(runtimeType,phase);



}

/// @nodoc
abstract mixin class $ChatPhaseChangedCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatPhaseChangedCopyWith(ChatPhaseChanged value, $Res Function(ChatPhaseChanged) _then) = _$ChatPhaseChangedCopyWithImpl;
@useResult
$Res call({
 ChatPhase phase
});




}
/// @nodoc
class _$ChatPhaseChangedCopyWithImpl<$Res>
    implements $ChatPhaseChangedCopyWith<$Res> {
  _$ChatPhaseChangedCopyWithImpl(this._self, this._then);

  final ChatPhaseChanged _self;
  final $Res Function(ChatPhaseChanged) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phase = null,}) {
  return _then(ChatPhaseChanged(
null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChatPhase,
  ));
}


}

/// @nodoc


class ChatProgressNote extends ChatEvent {
  const ChatProgressNote(this.note): super._();
  

 final  String note;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatProgressNoteCopyWith<ChatProgressNote> get copyWith => _$ChatProgressNoteCopyWithImpl<ChatProgressNote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatProgressNote&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,note);



}

/// @nodoc
abstract mixin class $ChatProgressNoteCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatProgressNoteCopyWith(ChatProgressNote value, $Res Function(ChatProgressNote) _then) = _$ChatProgressNoteCopyWithImpl;
@useResult
$Res call({
 String note
});




}
/// @nodoc
class _$ChatProgressNoteCopyWithImpl<$Res>
    implements $ChatProgressNoteCopyWith<$Res> {
  _$ChatProgressNoteCopyWithImpl(this._self, this._then);

  final ChatProgressNote _self;
  final $Res Function(ChatProgressNote) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? note = null,}) {
  return _then(ChatProgressNote(
null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatToolStarted extends ChatEvent {
  const ChatToolStarted({required this.callId, required this.name, this.input}): super._();
  

 final  String callId;
 final  String name;
 final  ToolInputSummary? input;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolStartedCopyWith<ChatToolStarted> get copyWith => _$ChatToolStartedCopyWithImpl<ChatToolStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolStarted&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.name, name) || other.name == name)&&(identical(other.input, input) || other.input == input));
}


@override
int get hashCode => Object.hash(runtimeType,callId,name,input);



}

/// @nodoc
abstract mixin class $ChatToolStartedCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatToolStartedCopyWith(ChatToolStarted value, $Res Function(ChatToolStarted) _then) = _$ChatToolStartedCopyWithImpl;
@useResult
$Res call({
 String callId, String name, ToolInputSummary? input
});


$ToolInputSummaryCopyWith<$Res>? get input;

}
/// @nodoc
class _$ChatToolStartedCopyWithImpl<$Res>
    implements $ChatToolStartedCopyWith<$Res> {
  _$ChatToolStartedCopyWithImpl(this._self, this._then);

  final ChatToolStarted _self;
  final $Res Function(ChatToolStarted) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? callId = null,Object? name = null,Object? input = freezed,}) {
  return _then(ChatToolStarted(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as ToolInputSummary?,
  ));
}

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolInputSummaryCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $ToolInputSummaryCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}

/// @nodoc


class ChatToolFinished extends ChatEvent {
  const ChatToolFinished({required this.callId, required this.name, required this.summary}): super._();
  

 final  String callId;
 final  String name;
 final  ToolSummary summary;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolFinishedCopyWith<ChatToolFinished> get copyWith => _$ChatToolFinishedCopyWithImpl<ChatToolFinished>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolFinished&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.name, name) || other.name == name)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,callId,name,summary);



}

/// @nodoc
abstract mixin class $ChatToolFinishedCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatToolFinishedCopyWith(ChatToolFinished value, $Res Function(ChatToolFinished) _then) = _$ChatToolFinishedCopyWithImpl;
@useResult
$Res call({
 String callId, String name, ToolSummary summary
});


$ToolSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$ChatToolFinishedCopyWithImpl<$Res>
    implements $ChatToolFinishedCopyWith<$Res> {
  _$ChatToolFinishedCopyWithImpl(this._self, this._then);

  final ChatToolFinished _self;
  final $Res Function(ChatToolFinished) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? callId = null,Object? name = null,Object? summary = null,}) {
  return _then(ChatToolFinished(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as ToolSummary,
  ));
}

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolSummaryCopyWith<$Res> get summary {
  
  return $ToolSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class ChatRoundStarted extends ChatEvent {
  const ChatRoundStarted(this.round): super._();
  

 final  int round;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoundStartedCopyWith<ChatRoundStarted> get copyWith => _$ChatRoundStartedCopyWithImpl<ChatRoundStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoundStarted&&(identical(other.round, round) || other.round == round));
}


@override
int get hashCode => Object.hash(runtimeType,round);



}

/// @nodoc
abstract mixin class $ChatRoundStartedCopyWith<$Res> implements $ChatEventCopyWith<$Res> {
  factory $ChatRoundStartedCopyWith(ChatRoundStarted value, $Res Function(ChatRoundStarted) _then) = _$ChatRoundStartedCopyWithImpl;
@useResult
$Res call({
 int round
});




}
/// @nodoc
class _$ChatRoundStartedCopyWithImpl<$Res>
    implements $ChatRoundStartedCopyWith<$Res> {
  _$ChatRoundStartedCopyWithImpl(this._self, this._then);

  final ChatRoundStarted _self;
  final $Res Function(ChatRoundStarted) _then;

/// Create a copy of ChatEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? round = null,}) {
  return _then(ChatRoundStarted(
null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ChatText extends ChatEvent {
  const ChatText(this.delta): super._();
  

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


class ChatFinished extends ChatEvent {
  const ChatFinished({required final  List<String> citedEntryIds}): _citedEntryIds = citedEntryIds,super._();
  

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


class ChatFailed extends ChatEvent {
  const ChatFailed(this.failure): super._();
  

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

/// @nodoc
mixin _$ChatStopResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStopResult);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $ChatStopResultCopyWith<$Res>  {
$ChatStopResultCopyWith(ChatStopResult _, $Res Function(ChatStopResult) __);
}


/// Adds pattern-matching-related methods to [ChatStopResult].
extension ChatStopResultPatterns on ChatStopResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatStopIdle value)?  idle,TResult Function( ChatStopKept value)?  kept,TResult Function( ChatStopDropped value)?  dropped,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatStopIdle() when idle != null:
return idle(_that);case ChatStopKept() when kept != null:
return kept(_that);case ChatStopDropped() when dropped != null:
return dropped(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatStopIdle value)  idle,required TResult Function( ChatStopKept value)  kept,required TResult Function( ChatStopDropped value)  dropped,}){
final _that = this;
switch (_that) {
case ChatStopIdle():
return idle(_that);case ChatStopKept():
return kept(_that);case ChatStopDropped():
return dropped(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatStopIdle value)?  idle,TResult? Function( ChatStopKept value)?  kept,TResult? Function( ChatStopDropped value)?  dropped,}){
final _that = this;
switch (_that) {
case ChatStopIdle() when idle != null:
return idle(_that);case ChatStopKept() when kept != null:
return kept(_that);case ChatStopDropped() when dropped != null:
return dropped(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( String text,  List<String> citedEntryIds)?  kept,TResult Function()?  dropped,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatStopIdle() when idle != null:
return idle();case ChatStopKept() when kept != null:
return kept(_that.text,_that.citedEntryIds);case ChatStopDropped() when dropped != null:
return dropped();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( String text,  List<String> citedEntryIds)  kept,required TResult Function()  dropped,}) {final _that = this;
switch (_that) {
case ChatStopIdle():
return idle();case ChatStopKept():
return kept(_that.text,_that.citedEntryIds);case ChatStopDropped():
return dropped();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( String text,  List<String> citedEntryIds)?  kept,TResult? Function()?  dropped,}) {final _that = this;
switch (_that) {
case ChatStopIdle() when idle != null:
return idle();case ChatStopKept() when kept != null:
return kept(_that.text,_that.citedEntryIds);case ChatStopDropped() when dropped != null:
return dropped();case _:
  return null;

}
}

}

/// @nodoc


class ChatStopIdle implements ChatStopResult {
  const ChatStopIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStopIdle);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class ChatStopKept implements ChatStopResult {
  const ChatStopKept({required this.text, required final  List<String> citedEntryIds}): _citedEntryIds = citedEntryIds;
  

 final  String text;
 final  List<String> _citedEntryIds;
 List<String> get citedEntryIds {
  if (_citedEntryIds is EqualUnmodifiableListView) return _citedEntryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citedEntryIds);
}


/// Create a copy of ChatStopResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStopKeptCopyWith<ChatStopKept> get copyWith => _$ChatStopKeptCopyWithImpl<ChatStopKept>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStopKept&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._citedEntryIds, _citedEntryIds));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_citedEntryIds));



}

/// @nodoc
abstract mixin class $ChatStopKeptCopyWith<$Res> implements $ChatStopResultCopyWith<$Res> {
  factory $ChatStopKeptCopyWith(ChatStopKept value, $Res Function(ChatStopKept) _then) = _$ChatStopKeptCopyWithImpl;
@useResult
$Res call({
 String text, List<String> citedEntryIds
});




}
/// @nodoc
class _$ChatStopKeptCopyWithImpl<$Res>
    implements $ChatStopKeptCopyWith<$Res> {
  _$ChatStopKeptCopyWithImpl(this._self, this._then);

  final ChatStopKept _self;
  final $Res Function(ChatStopKept) _then;

/// Create a copy of ChatStopResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,Object? citedEntryIds = null,}) {
  return _then(ChatStopKept(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,citedEntryIds: null == citedEntryIds ? _self._citedEntryIds : citedEntryIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class ChatStopDropped implements ChatStopResult {
  const ChatStopDropped();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStopDropped);
}


@override
int get hashCode => runtimeType.hashCode;



}




// dart format on
