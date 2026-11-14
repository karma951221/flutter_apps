// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatProgressStep {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatProgressStep);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $ChatProgressStepCopyWith<$Res>  {
$ChatProgressStepCopyWith(ChatProgressStep _, $Res Function(ChatProgressStep) __);
}


/// Adds pattern-matching-related methods to [ChatProgressStep].
extension ChatProgressStepPatterns on ChatProgressStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StepSending value)?  sending,TResult Function( StepThinking value)?  thinking,TResult Function( StepNote value)?  note,TResult Function( StepTool value)?  tool,TResult Function( StepWriting value)?  writing,TResult Function( StepStopped value)?  stopped,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StepSending() when sending != null:
return sending(_that);case StepThinking() when thinking != null:
return thinking(_that);case StepNote() when note != null:
return note(_that);case StepTool() when tool != null:
return tool(_that);case StepWriting() when writing != null:
return writing(_that);case StepStopped() when stopped != null:
return stopped(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StepSending value)  sending,required TResult Function( StepThinking value)  thinking,required TResult Function( StepNote value)  note,required TResult Function( StepTool value)  tool,required TResult Function( StepWriting value)  writing,required TResult Function( StepStopped value)  stopped,}){
final _that = this;
switch (_that) {
case StepSending():
return sending(_that);case StepThinking():
return thinking(_that);case StepNote():
return note(_that);case StepTool():
return tool(_that);case StepWriting():
return writing(_that);case StepStopped():
return stopped(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StepSending value)?  sending,TResult? Function( StepThinking value)?  thinking,TResult? Function( StepNote value)?  note,TResult? Function( StepTool value)?  tool,TResult? Function( StepWriting value)?  writing,TResult? Function( StepStopped value)?  stopped,}){
final _that = this;
switch (_that) {
case StepSending() when sending != null:
return sending(_that);case StepThinking() when thinking != null:
return thinking(_that);case StepNote() when note != null:
return note(_that);case StepTool() when tool != null:
return tool(_that);case StepWriting() when writing != null:
return writing(_that);case StepStopped() when stopped != null:
return stopped(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  sending,TResult Function()?  thinking,TResult Function( String text)?  note,TResult Function( String callId,  ChatToolKind kind,  ToolInputSummary? input,  ToolSummary? result,  bool awaitingApproval)?  tool,TResult Function()?  writing,TResult Function()?  stopped,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StepSending() when sending != null:
return sending();case StepThinking() when thinking != null:
return thinking();case StepNote() when note != null:
return note(_that.text);case StepTool() when tool != null:
return tool(_that.callId,_that.kind,_that.input,_that.result,_that.awaitingApproval);case StepWriting() when writing != null:
return writing();case StepStopped() when stopped != null:
return stopped();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  sending,required TResult Function()  thinking,required TResult Function( String text)  note,required TResult Function( String callId,  ChatToolKind kind,  ToolInputSummary? input,  ToolSummary? result,  bool awaitingApproval)  tool,required TResult Function()  writing,required TResult Function()  stopped,}) {final _that = this;
switch (_that) {
case StepSending():
return sending();case StepThinking():
return thinking();case StepNote():
return note(_that.text);case StepTool():
return tool(_that.callId,_that.kind,_that.input,_that.result,_that.awaitingApproval);case StepWriting():
return writing();case StepStopped():
return stopped();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  sending,TResult? Function()?  thinking,TResult? Function( String text)?  note,TResult? Function( String callId,  ChatToolKind kind,  ToolInputSummary? input,  ToolSummary? result,  bool awaitingApproval)?  tool,TResult? Function()?  writing,TResult? Function()?  stopped,}) {final _that = this;
switch (_that) {
case StepSending() when sending != null:
return sending();case StepThinking() when thinking != null:
return thinking();case StepNote() when note != null:
return note(_that.text);case StepTool() when tool != null:
return tool(_that.callId,_that.kind,_that.input,_that.result,_that.awaitingApproval);case StepWriting() when writing != null:
return writing();case StepStopped() when stopped != null:
return stopped();case _:
  return null;

}
}

}

/// @nodoc


class StepSending extends ChatProgressStep {
  const StepSending(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepSending);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class StepThinking extends ChatProgressStep {
  const StepThinking(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepThinking);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class StepNote extends ChatProgressStep {
  const StepNote(this.text): super._();
  

 final  String text;

/// Create a copy of ChatProgressStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepNoteCopyWith<StepNote> get copyWith => _$StepNoteCopyWithImpl<StepNote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepNote&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);



}

/// @nodoc
abstract mixin class $StepNoteCopyWith<$Res> implements $ChatProgressStepCopyWith<$Res> {
  factory $StepNoteCopyWith(StepNote value, $Res Function(StepNote) _then) = _$StepNoteCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$StepNoteCopyWithImpl<$Res>
    implements $StepNoteCopyWith<$Res> {
  _$StepNoteCopyWithImpl(this._self, this._then);

  final StepNote _self;
  final $Res Function(StepNote) _then;

/// Create a copy of ChatProgressStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(StepNote(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StepTool extends ChatProgressStep {
  const StepTool({required this.callId, required this.kind, this.input, this.result, this.awaitingApproval = false}): super._();
  

 final  String callId;
 final  ChatToolKind kind;
 final  ToolInputSummary? input;
 final  ToolSummary? result;
@JsonKey() final  bool awaitingApproval;

/// Create a copy of ChatProgressStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepToolCopyWith<StepTool> get copyWith => _$StepToolCopyWithImpl<StepTool>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepTool&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.input, input) || other.input == input)&&(identical(other.result, result) || other.result == result)&&(identical(other.awaitingApproval, awaitingApproval) || other.awaitingApproval == awaitingApproval));
}


@override
int get hashCode => Object.hash(runtimeType,callId,kind,input,result,awaitingApproval);



}

/// @nodoc
abstract mixin class $StepToolCopyWith<$Res> implements $ChatProgressStepCopyWith<$Res> {
  factory $StepToolCopyWith(StepTool value, $Res Function(StepTool) _then) = _$StepToolCopyWithImpl;
@useResult
$Res call({
 String callId, ChatToolKind kind, ToolInputSummary? input, ToolSummary? result, bool awaitingApproval
});


$ToolInputSummaryCopyWith<$Res>? get input;$ToolSummaryCopyWith<$Res>? get result;

}
/// @nodoc
class _$StepToolCopyWithImpl<$Res>
    implements $StepToolCopyWith<$Res> {
  _$StepToolCopyWithImpl(this._self, this._then);

  final StepTool _self;
  final $Res Function(StepTool) _then;

/// Create a copy of ChatProgressStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? callId = null,Object? kind = null,Object? input = freezed,Object? result = freezed,Object? awaitingApproval = null,}) {
  return _then(StepTool(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ChatToolKind,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as ToolInputSummary?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ToolSummary?,awaitingApproval: null == awaitingApproval ? _self.awaitingApproval : awaitingApproval // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChatProgressStep
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
}/// Create a copy of ChatProgressStep
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolSummaryCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ToolSummaryCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class StepWriting extends ChatProgressStep {
  const StepWriting(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepWriting);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class StepStopped extends ChatProgressStep {
  const StepStopped(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepStopped);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc
mixin _$ChatProgress {

 List<ChatProgressStep> get steps; DateTime get startedAt; int get elapsedSeconds; bool get running;
/// Create a copy of ChatProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatProgressCopyWith<ChatProgress> get copyWith => _$ChatProgressCopyWithImpl<ChatProgress>(this as ChatProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatProgress&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(steps),startedAt,elapsedSeconds,running);

@override
String toString() {
  return 'ChatProgress(steps: $steps, startedAt: $startedAt, elapsedSeconds: $elapsedSeconds, running: $running)';
}


}

/// @nodoc
abstract mixin class $ChatProgressCopyWith<$Res>  {
  factory $ChatProgressCopyWith(ChatProgress value, $Res Function(ChatProgress) _then) = _$ChatProgressCopyWithImpl;
@useResult
$Res call({
 DateTime startedAt, List<ChatProgressStep> steps, int elapsedSeconds, bool running
});




}
/// @nodoc
class _$ChatProgressCopyWithImpl<$Res>
    implements $ChatProgressCopyWith<$Res> {
  _$ChatProgressCopyWithImpl(this._self, this._then);

  final ChatProgress _self;
  final $Res Function(ChatProgress) _then;

/// Create a copy of ChatProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startedAt = null,Object? steps = null,Object? elapsedSeconds = null,Object? running = null,}) {
  return _then(ChatProgress(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<ChatProgressStep>,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatProgress].
extension ChatProgressPatterns on ChatProgress {
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
