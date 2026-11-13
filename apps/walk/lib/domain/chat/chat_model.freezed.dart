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
mixin _$ChatMessage {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $ChatMessageCopyWith<$Res>  {
$ChatMessageCopyWith(ChatMessage _, $Res Function(ChatMessage) __);
}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserMessage value)?  user,TResult Function( AssistantMessage value)?  assistant,TResult Function( ToolResultsMessage value)?  toolResults,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that);case AssistantMessage() when assistant != null:
return assistant(_that);case ToolResultsMessage() when toolResults != null:
return toolResults(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserMessage value)  user,required TResult Function( AssistantMessage value)  assistant,required TResult Function( ToolResultsMessage value)  toolResults,}){
final _that = this;
switch (_that) {
case UserMessage():
return user(_that);case AssistantMessage():
return assistant(_that);case ToolResultsMessage():
return toolResults(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserMessage value)?  user,TResult? Function( AssistantMessage value)?  assistant,TResult? Function( ToolResultsMessage value)?  toolResults,}){
final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that);case AssistantMessage() when assistant != null:
return assistant(_that);case ToolResultsMessage() when toolResults != null:
return toolResults(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text,  List<ChatAttachment> attachments)?  user,TResult Function( List<AssistantPart> parts,  VendorTurnState? vendorState)?  assistant,TResult Function( List<ToolResultPart> results)?  toolResults,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that.text,_that.attachments);case AssistantMessage() when assistant != null:
return assistant(_that.parts,_that.vendorState);case ToolResultsMessage() when toolResults != null:
return toolResults(_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text,  List<ChatAttachment> attachments)  user,required TResult Function( List<AssistantPart> parts,  VendorTurnState? vendorState)  assistant,required TResult Function( List<ToolResultPart> results)  toolResults,}) {final _that = this;
switch (_that) {
case UserMessage():
return user(_that.text,_that.attachments);case AssistantMessage():
return assistant(_that.parts,_that.vendorState);case ToolResultsMessage():
return toolResults(_that.results);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text,  List<ChatAttachment> attachments)?  user,TResult? Function( List<AssistantPart> parts,  VendorTurnState? vendorState)?  assistant,TResult? Function( List<ToolResultPart> results)?  toolResults,}) {final _that = this;
switch (_that) {
case UserMessage() when user != null:
return user(_that.text,_that.attachments);case AssistantMessage() when assistant != null:
return assistant(_that.parts,_that.vendorState);case ToolResultsMessage() when toolResults != null:
return toolResults(_that.results);case _:
  return null;

}
}

}

/// @nodoc


class UserMessage implements ChatMessage {
  const UserMessage(this.text, {final  List<ChatAttachment> attachments = const <ChatAttachment>[]}): _attachments = attachments;
  

 final  String text;
 final  List<ChatAttachment> _attachments;
@JsonKey() List<ChatAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserMessageCopyWith<UserMessage> get copyWith => _$UserMessageCopyWithImpl<UserMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserMessage&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}


@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_attachments));



}

/// @nodoc
abstract mixin class $UserMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $UserMessageCopyWith(UserMessage value, $Res Function(UserMessage) _then) = _$UserMessageCopyWithImpl;
@useResult
$Res call({
 String text, List<ChatAttachment> attachments
});




}
/// @nodoc
class _$UserMessageCopyWithImpl<$Res>
    implements $UserMessageCopyWith<$Res> {
  _$UserMessageCopyWithImpl(this._self, this._then);

  final UserMessage _self;
  final $Res Function(UserMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,Object? attachments = null,}) {
  return _then(UserMessage(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ChatAttachment>,
  ));
}


}

/// @nodoc


class AssistantMessage implements ChatMessage {
  const AssistantMessage({required final  List<AssistantPart> parts, this.vendorState}): _parts = parts;
  

 final  List<AssistantPart> _parts;
 List<AssistantPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

 final  VendorTurnState? vendorState;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantMessageCopyWith<AssistantMessage> get copyWith => _$AssistantMessageCopyWithImpl<AssistantMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantMessage&&const DeepCollectionEquality().equals(other._parts, _parts)&&(identical(other.vendorState, vendorState) || other.vendorState == vendorState));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_parts),vendorState);



}

/// @nodoc
abstract mixin class $AssistantMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $AssistantMessageCopyWith(AssistantMessage value, $Res Function(AssistantMessage) _then) = _$AssistantMessageCopyWithImpl;
@useResult
$Res call({
 List<AssistantPart> parts, VendorTurnState? vendorState
});




}
/// @nodoc
class _$AssistantMessageCopyWithImpl<$Res>
    implements $AssistantMessageCopyWith<$Res> {
  _$AssistantMessageCopyWithImpl(this._self, this._then);

  final AssistantMessage _self;
  final $Res Function(AssistantMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? parts = null,Object? vendorState = freezed,}) {
  return _then(AssistantMessage(
parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<AssistantPart>,vendorState: freezed == vendorState ? _self.vendorState : vendorState // ignore: cast_nullable_to_non_nullable
as VendorTurnState?,
  ));
}


}

/// @nodoc


class ToolResultsMessage implements ChatMessage {
  const ToolResultsMessage(final  List<ToolResultPart> results): _results = results;
  

 final  List<ToolResultPart> _results;
 List<ToolResultPart> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolResultsMessageCopyWith<ToolResultsMessage> get copyWith => _$ToolResultsMessageCopyWithImpl<ToolResultsMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolResultsMessage&&const DeepCollectionEquality().equals(other._results, _results));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_results));



}

/// @nodoc
abstract mixin class $ToolResultsMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ToolResultsMessageCopyWith(ToolResultsMessage value, $Res Function(ToolResultsMessage) _then) = _$ToolResultsMessageCopyWithImpl;
@useResult
$Res call({
 List<ToolResultPart> results
});




}
/// @nodoc
class _$ToolResultsMessageCopyWithImpl<$Res>
    implements $ToolResultsMessageCopyWith<$Res> {
  _$ToolResultsMessageCopyWithImpl(this._self, this._then);

  final ToolResultsMessage _self;
  final $Res Function(ToolResultsMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? results = null,}) {
  return _then(ToolResultsMessage(
null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<ToolResultPart>,
  ));
}


}

/// @nodoc
mixin _$AssistantPart {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantPart);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $AssistantPartCopyWith<$Res>  {
$AssistantPartCopyWith(AssistantPart _, $Res Function(AssistantPart) __);
}


/// Adds pattern-matching-related methods to [AssistantPart].
extension AssistantPartPatterns on AssistantPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextPart value)?  text,TResult Function( ToolCallPart value)?  toolCall,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that);case ToolCallPart() when toolCall != null:
return toolCall(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextPart value)  text,required TResult Function( ToolCallPart value)  toolCall,}){
final _that = this;
switch (_that) {
case TextPart():
return text(_that);case ToolCallPart():
return toolCall(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextPart value)?  text,TResult? Function( ToolCallPart value)?  toolCall,}){
final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that);case ToolCallPart() when toolCall != null:
return toolCall(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  text,TResult Function( String id,  String name,  Map<String, Object?> input)?  toolCall,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that.text);case ToolCallPart() when toolCall != null:
return toolCall(_that.id,_that.name,_that.input);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  text,required TResult Function( String id,  String name,  Map<String, Object?> input)  toolCall,}) {final _that = this;
switch (_that) {
case TextPart():
return text(_that.text);case ToolCallPart():
return toolCall(_that.id,_that.name,_that.input);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  text,TResult? Function( String id,  String name,  Map<String, Object?> input)?  toolCall,}) {final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that.text);case ToolCallPart() when toolCall != null:
return toolCall(_that.id,_that.name,_that.input);case _:
  return null;

}
}

}

/// @nodoc


class TextPart implements AssistantPart {
  const TextPart(this.text);
  

 final  String text;

/// Create a copy of AssistantPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextPartCopyWith<TextPart> get copyWith => _$TextPartCopyWithImpl<TextPart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextPart&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);



}

/// @nodoc
abstract mixin class $TextPartCopyWith<$Res> implements $AssistantPartCopyWith<$Res> {
  factory $TextPartCopyWith(TextPart value, $Res Function(TextPart) _then) = _$TextPartCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$TextPartCopyWithImpl<$Res>
    implements $TextPartCopyWith<$Res> {
  _$TextPartCopyWithImpl(this._self, this._then);

  final TextPart _self;
  final $Res Function(TextPart) _then;

/// Create a copy of AssistantPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(TextPart(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ToolCallPart implements AssistantPart {
  const ToolCallPart({required this.id, required this.name, required final  Map<String, Object?> input}): _input = input;
  

 final  String id;
 final  String name;
 final  Map<String, Object?> _input;
 Map<String, Object?> get input {
  if (_input is EqualUnmodifiableMapView) return _input;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_input);
}


/// Create a copy of AssistantPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallPartCopyWith<ToolCallPart> get copyWith => _$ToolCallPartCopyWithImpl<ToolCallPart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCallPart&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._input, _input));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_input));



}

/// @nodoc
abstract mixin class $ToolCallPartCopyWith<$Res> implements $AssistantPartCopyWith<$Res> {
  factory $ToolCallPartCopyWith(ToolCallPart value, $Res Function(ToolCallPart) _then) = _$ToolCallPartCopyWithImpl;
@useResult
$Res call({
 String id, String name, Map<String, Object?> input
});




}
/// @nodoc
class _$ToolCallPartCopyWithImpl<$Res>
    implements $ToolCallPartCopyWith<$Res> {
  _$ToolCallPartCopyWithImpl(this._self, this._then);

  final ToolCallPart _self;
  final $Res Function(ToolCallPart) _then;

/// Create a copy of AssistantPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? input = null,}) {
  return _then(ToolCallPart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self._input : input // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

/// @nodoc
mixin _$ToolResultPart {

 String get callId; String get json; bool get isError; List<ToolImage> get images;
/// Create a copy of ToolResultPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolResultPartCopyWith<ToolResultPart> get copyWith => _$ToolResultPartCopyWithImpl<ToolResultPart>(this as ToolResultPart, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolResultPart&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.json, json) || other.json == json)&&(identical(other.isError, isError) || other.isError == isError)&&const DeepCollectionEquality().equals(other.images, images));
}


@override
int get hashCode => Object.hash(runtimeType,callId,json,isError,const DeepCollectionEquality().hash(images));



}

/// @nodoc
abstract mixin class $ToolResultPartCopyWith<$Res>  {
  factory $ToolResultPartCopyWith(ToolResultPart value, $Res Function(ToolResultPart) _then) = _$ToolResultPartCopyWithImpl;
@useResult
$Res call({
 String callId, String json, bool isError, List<ToolImage> images
});




}
/// @nodoc
class _$ToolResultPartCopyWithImpl<$Res>
    implements $ToolResultPartCopyWith<$Res> {
  _$ToolResultPartCopyWithImpl(this._self, this._then);

  final ToolResultPart _self;
  final $Res Function(ToolResultPart) _then;

/// Create a copy of ToolResultPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callId = null,Object? json = null,Object? isError = null,Object? images = null,}) {
  return _then(ToolResultPart(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,json: null == json ? _self.json : json // ignore: cast_nullable_to_non_nullable
as String,isError: null == isError ? _self.isError : isError // ignore: cast_nullable_to_non_nullable
as bool,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ToolImage>,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolResultPart].
extension ToolResultPartPatterns on ToolResultPart {
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
mixin _$ToolSpec {

 String get name; String get description; Map<String, Object?> get parameters;
/// Create a copy of ToolSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolSpecCopyWith<ToolSpec> get copyWith => _$ToolSpecCopyWithImpl<ToolSpec>(this as ToolSpec, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolSpec&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.parameters, parameters));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,const DeepCollectionEquality().hash(parameters));

@override
String toString() {
  return 'ToolSpec(name: $name, description: $description, parameters: $parameters)';
}


}

/// @nodoc
abstract mixin class $ToolSpecCopyWith<$Res>  {
  factory $ToolSpecCopyWith(ToolSpec value, $Res Function(ToolSpec) _then) = _$ToolSpecCopyWithImpl;
@useResult
$Res call({
 String name, String description, Map<String, Object?> parameters
});




}
/// @nodoc
class _$ToolSpecCopyWithImpl<$Res>
    implements $ToolSpecCopyWith<$Res> {
  _$ToolSpecCopyWithImpl(this._self, this._then);

  final ToolSpec _self;
  final $Res Function(ToolSpec) _then;

/// Create a copy of ToolSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? parameters = null,}) {
  return _then(ToolSpec(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,parameters: null == parameters ? _self.parameters : parameters // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolSpec].
extension ToolSpecPatterns on ToolSpec {
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
mixin _$TokenUsage {

 int get inputTokens; int get outputTokens; int get cacheReadTokens; int get cacheWriteTokens; int? get reasoningTokens;
/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<TokenUsage> get copyWith => _$TokenUsageCopyWithImpl<TokenUsage>(this as TokenUsage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenUsage&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens)&&(identical(other.cacheWriteTokens, cacheWriteTokens) || other.cacheWriteTokens == cacheWriteTokens)&&(identical(other.reasoningTokens, reasoningTokens) || other.reasoningTokens == reasoningTokens));
}


@override
int get hashCode => Object.hash(runtimeType,inputTokens,outputTokens,cacheReadTokens,cacheWriteTokens,reasoningTokens);

@override
String toString() {
  return 'TokenUsage(inputTokens: $inputTokens, outputTokens: $outputTokens, cacheReadTokens: $cacheReadTokens, cacheWriteTokens: $cacheWriteTokens, reasoningTokens: $reasoningTokens)';
}


}

/// @nodoc
abstract mixin class $TokenUsageCopyWith<$Res>  {
  factory $TokenUsageCopyWith(TokenUsage value, $Res Function(TokenUsage) _then) = _$TokenUsageCopyWithImpl;
@useResult
$Res call({
 int inputTokens, int outputTokens, int cacheReadTokens, int cacheWriteTokens, int? reasoningTokens
});




}
/// @nodoc
class _$TokenUsageCopyWithImpl<$Res>
    implements $TokenUsageCopyWith<$Res> {
  _$TokenUsageCopyWithImpl(this._self, this._then);

  final TokenUsage _self;
  final $Res Function(TokenUsage) _then;

/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inputTokens = null,Object? outputTokens = null,Object? cacheReadTokens = null,Object? cacheWriteTokens = null,Object? reasoningTokens = freezed,}) {
  return _then(TokenUsage(
inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,cacheReadTokens: null == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int,cacheWriteTokens: null == cacheWriteTokens ? _self.cacheWriteTokens : cacheWriteTokens // ignore: cast_nullable_to_non_nullable
as int,reasoningTokens: freezed == reasoningTokens ? _self.reasoningTokens : reasoningTokens // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenUsage].
extension TokenUsagePatterns on TokenUsage {
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
mixin _$ModelEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelEvent);
}


@override
int get hashCode => runtimeType.hashCode;



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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ModelTextDelta value)?  textDelta,TResult Function( ModelThinking value)?  thinking,TResult Function( ModelProgress value)?  progress,TResult Function( ModelToolCallStarted value)?  toolCallStarted,TResult Function( ModelToolCallReady value)?  toolCallReady,TResult Function( ModelWebSearch value)?  webSearch,TResult Function( ModelCompleted value)?  completed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that);case ModelThinking() when thinking != null:
return thinking(_that);case ModelProgress() when progress != null:
return progress(_that);case ModelToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that);case ModelToolCallReady() when toolCallReady != null:
return toolCallReady(_that);case ModelWebSearch() when webSearch != null:
return webSearch(_that);case ModelCompleted() when completed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ModelTextDelta value)  textDelta,required TResult Function( ModelThinking value)  thinking,required TResult Function( ModelProgress value)  progress,required TResult Function( ModelToolCallStarted value)  toolCallStarted,required TResult Function( ModelToolCallReady value)  toolCallReady,required TResult Function( ModelWebSearch value)  webSearch,required TResult Function( ModelCompleted value)  completed,}){
final _that = this;
switch (_that) {
case ModelTextDelta():
return textDelta(_that);case ModelThinking():
return thinking(_that);case ModelProgress():
return progress(_that);case ModelToolCallStarted():
return toolCallStarted(_that);case ModelToolCallReady():
return toolCallReady(_that);case ModelWebSearch():
return webSearch(_that);case ModelCompleted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ModelTextDelta value)?  textDelta,TResult? Function( ModelThinking value)?  thinking,TResult? Function( ModelProgress value)?  progress,TResult? Function( ModelToolCallStarted value)?  toolCallStarted,TResult? Function( ModelToolCallReady value)?  toolCallReady,TResult? Function( ModelWebSearch value)?  webSearch,TResult? Function( ModelCompleted value)?  completed,}){
final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that);case ModelThinking() when thinking != null:
return thinking(_that);case ModelProgress() when progress != null:
return progress(_that);case ModelToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that);case ModelToolCallReady() when toolCallReady != null:
return toolCallReady(_that);case ModelWebSearch() when webSearch != null:
return webSearch(_that);case ModelCompleted() when completed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  textDelta,TResult Function()?  thinking,TResult Function( String text)?  progress,TResult Function( String id,  String name)?  toolCallStarted,TResult Function( String id,  String name,  Map<String, Object?> input)?  toolCallReady,TResult Function( String id,  String? query)?  webSearch,TResult Function( AssistantMessage message,  StopKind stop,  TokenUsage? usage)?  completed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that.text);case ModelThinking() when thinking != null:
return thinking();case ModelProgress() when progress != null:
return progress(_that.text);case ModelToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that.id,_that.name);case ModelToolCallReady() when toolCallReady != null:
return toolCallReady(_that.id,_that.name,_that.input);case ModelWebSearch() when webSearch != null:
return webSearch(_that.id,_that.query);case ModelCompleted() when completed != null:
return completed(_that.message,_that.stop,_that.usage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  textDelta,required TResult Function()  thinking,required TResult Function( String text)  progress,required TResult Function( String id,  String name)  toolCallStarted,required TResult Function( String id,  String name,  Map<String, Object?> input)  toolCallReady,required TResult Function( String id,  String? query)  webSearch,required TResult Function( AssistantMessage message,  StopKind stop,  TokenUsage? usage)  completed,}) {final _that = this;
switch (_that) {
case ModelTextDelta():
return textDelta(_that.text);case ModelThinking():
return thinking();case ModelProgress():
return progress(_that.text);case ModelToolCallStarted():
return toolCallStarted(_that.id,_that.name);case ModelToolCallReady():
return toolCallReady(_that.id,_that.name,_that.input);case ModelWebSearch():
return webSearch(_that.id,_that.query);case ModelCompleted():
return completed(_that.message,_that.stop,_that.usage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  textDelta,TResult? Function()?  thinking,TResult? Function( String text)?  progress,TResult? Function( String id,  String name)?  toolCallStarted,TResult? Function( String id,  String name,  Map<String, Object?> input)?  toolCallReady,TResult? Function( String id,  String? query)?  webSearch,TResult? Function( AssistantMessage message,  StopKind stop,  TokenUsage? usage)?  completed,}) {final _that = this;
switch (_that) {
case ModelTextDelta() when textDelta != null:
return textDelta(_that.text);case ModelThinking() when thinking != null:
return thinking();case ModelProgress() when progress != null:
return progress(_that.text);case ModelToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that.id,_that.name);case ModelToolCallReady() when toolCallReady != null:
return toolCallReady(_that.id,_that.name,_that.input);case ModelWebSearch() when webSearch != null:
return webSearch(_that.id,_that.query);case ModelCompleted() when completed != null:
return completed(_that.message,_that.stop,_that.usage);case _:
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


class ModelThinking implements ModelEvent {
  const ModelThinking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelThinking);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class ModelProgress implements ModelEvent {
  const ModelProgress(this.text);
  

 final  String text;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelProgressCopyWith<ModelProgress> get copyWith => _$ModelProgressCopyWithImpl<ModelProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelProgress&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);



}

/// @nodoc
abstract mixin class $ModelProgressCopyWith<$Res> implements $ModelEventCopyWith<$Res> {
  factory $ModelProgressCopyWith(ModelProgress value, $Res Function(ModelProgress) _then) = _$ModelProgressCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ModelProgressCopyWithImpl<$Res>
    implements $ModelProgressCopyWith<$Res> {
  _$ModelProgressCopyWithImpl(this._self, this._then);

  final ModelProgress _self;
  final $Res Function(ModelProgress) _then;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(ModelProgress(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ModelToolCallStarted implements ModelEvent {
  const ModelToolCallStarted({required this.id, required this.name});
  

 final  String id;
 final  String name;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelToolCallStartedCopyWith<ModelToolCallStarted> get copyWith => _$ModelToolCallStartedCopyWithImpl<ModelToolCallStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelToolCallStarted&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,id,name);



}

/// @nodoc
abstract mixin class $ModelToolCallStartedCopyWith<$Res> implements $ModelEventCopyWith<$Res> {
  factory $ModelToolCallStartedCopyWith(ModelToolCallStarted value, $Res Function(ModelToolCallStarted) _then) = _$ModelToolCallStartedCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$ModelToolCallStartedCopyWithImpl<$Res>
    implements $ModelToolCallStartedCopyWith<$Res> {
  _$ModelToolCallStartedCopyWithImpl(this._self, this._then);

  final ModelToolCallStarted _self;
  final $Res Function(ModelToolCallStarted) _then;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(ModelToolCallStarted(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ModelToolCallReady implements ModelEvent {
  const ModelToolCallReady({required this.id, required this.name, required final  Map<String, Object?> input}): _input = input;
  

 final  String id;
 final  String name;
 final  Map<String, Object?> _input;
 Map<String, Object?> get input {
  if (_input is EqualUnmodifiableMapView) return _input;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_input);
}


/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelToolCallReadyCopyWith<ModelToolCallReady> get copyWith => _$ModelToolCallReadyCopyWithImpl<ModelToolCallReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelToolCallReady&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._input, _input));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_input));



}

/// @nodoc
abstract mixin class $ModelToolCallReadyCopyWith<$Res> implements $ModelEventCopyWith<$Res> {
  factory $ModelToolCallReadyCopyWith(ModelToolCallReady value, $Res Function(ModelToolCallReady) _then) = _$ModelToolCallReadyCopyWithImpl;
@useResult
$Res call({
 String id, String name, Map<String, Object?> input
});




}
/// @nodoc
class _$ModelToolCallReadyCopyWithImpl<$Res>
    implements $ModelToolCallReadyCopyWith<$Res> {
  _$ModelToolCallReadyCopyWithImpl(this._self, this._then);

  final ModelToolCallReady _self;
  final $Res Function(ModelToolCallReady) _then;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? input = null,}) {
  return _then(ModelToolCallReady(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self._input : input // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

/// @nodoc


class ModelWebSearch implements ModelEvent {
  const ModelWebSearch({required this.id, this.query});
  

 final  String id;
 final  String? query;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelWebSearchCopyWith<ModelWebSearch> get copyWith => _$ModelWebSearchCopyWithImpl<ModelWebSearch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelWebSearch&&(identical(other.id, id) || other.id == id)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,id,query);



}

/// @nodoc
abstract mixin class $ModelWebSearchCopyWith<$Res> implements $ModelEventCopyWith<$Res> {
  factory $ModelWebSearchCopyWith(ModelWebSearch value, $Res Function(ModelWebSearch) _then) = _$ModelWebSearchCopyWithImpl;
@useResult
$Res call({
 String id, String? query
});




}
/// @nodoc
class _$ModelWebSearchCopyWithImpl<$Res>
    implements $ModelWebSearchCopyWith<$Res> {
  _$ModelWebSearchCopyWithImpl(this._self, this._then);

  final ModelWebSearch _self;
  final $Res Function(ModelWebSearch) _then;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? query = freezed,}) {
  return _then(ModelWebSearch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ModelCompleted implements ModelEvent {
  const ModelCompleted({required this.message, required this.stop, required this.usage});
  

 final  AssistantMessage message;
 final  StopKind stop;
 final  TokenUsage? usage;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelCompletedCopyWith<ModelCompleted> get copyWith => _$ModelCompletedCopyWithImpl<ModelCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelCompleted&&const DeepCollectionEquality().equals(other.message, message)&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(message),stop,usage);



}

/// @nodoc
abstract mixin class $ModelCompletedCopyWith<$Res> implements $ModelEventCopyWith<$Res> {
  factory $ModelCompletedCopyWith(ModelCompleted value, $Res Function(ModelCompleted) _then) = _$ModelCompletedCopyWithImpl;
@useResult
$Res call({
 AssistantMessage message, StopKind stop, TokenUsage? usage
});


$TokenUsageCopyWith<$Res>? get usage;

}
/// @nodoc
class _$ModelCompletedCopyWithImpl<$Res>
    implements $ModelCompletedCopyWith<$Res> {
  _$ModelCompletedCopyWithImpl(this._self, this._then);

  final ModelCompleted _self;
  final $Res Function(ModelCompleted) _then;

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? stop = null,Object? usage = freezed,}) {
  return _then(ModelCompleted(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as AssistantMessage,stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as StopKind,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage?,
  ));
}

/// Create a copy of ModelEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $TokenUsageCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

/// @nodoc
mixin _$ModelInfo {

 String get id; String get displayName; DateTime? get createdAt; bool? get supportsTools; bool? get supportsImages; bool get supportsFastMode; List<String> get aliases;
/// Create a copy of ModelInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelInfoCopyWith<ModelInfo> get copyWith => _$ModelInfoCopyWithImpl<ModelInfo>(this as ModelInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.supportsTools, supportsTools) || other.supportsTools == supportsTools)&&(identical(other.supportsImages, supportsImages) || other.supportsImages == supportsImages)&&(identical(other.supportsFastMode, supportsFastMode) || other.supportsFastMode == supportsFastMode)&&const DeepCollectionEquality().equals(other.aliases, aliases));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,createdAt,supportsTools,supportsImages,supportsFastMode,const DeepCollectionEquality().hash(aliases));

@override
String toString() {
  return 'ModelInfo(id: $id, displayName: $displayName, createdAt: $createdAt, supportsTools: $supportsTools, supportsImages: $supportsImages, supportsFastMode: $supportsFastMode, aliases: $aliases)';
}


}

/// @nodoc
abstract mixin class $ModelInfoCopyWith<$Res>  {
  factory $ModelInfoCopyWith(ModelInfo value, $Res Function(ModelInfo) _then) = _$ModelInfoCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, DateTime? createdAt, bool? supportsTools, bool? supportsImages, bool supportsFastMode, List<String> aliases
});




}
/// @nodoc
class _$ModelInfoCopyWithImpl<$Res>
    implements $ModelInfoCopyWith<$Res> {
  _$ModelInfoCopyWithImpl(this._self, this._then);

  final ModelInfo _self;
  final $Res Function(ModelInfo) _then;

/// Create a copy of ModelInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? createdAt = freezed,Object? supportsTools = freezed,Object? supportsImages = freezed,Object? supportsFastMode = null,Object? aliases = null,}) {
  return _then(ModelInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,supportsTools: freezed == supportsTools ? _self.supportsTools : supportsTools // ignore: cast_nullable_to_non_nullable
as bool?,supportsImages: freezed == supportsImages ? _self.supportsImages : supportsImages // ignore: cast_nullable_to_non_nullable
as bool?,supportsFastMode: null == supportsFastMode ? _self.supportsFastMode : supportsFastMode // ignore: cast_nullable_to_non_nullable
as bool,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelInfo].
extension ModelInfoPatterns on ModelInfo {
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
mixin _$ModelListResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelListResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelListResult()';
}


}

/// @nodoc
class $ModelListResultCopyWith<$Res>  {
$ModelListResultCopyWith(ModelListResult _, $Res Function(ModelListResult) __);
}


/// Adds pattern-matching-related methods to [ModelListResult].
extension ModelListResultPatterns on ModelListResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ModelListOk value)?  ok,TResult Function( ModelListInvalidKey value)?  invalidKey,TResult Function( ModelListUnreachable value)?  unreachable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ModelListOk() when ok != null:
return ok(_that);case ModelListInvalidKey() when invalidKey != null:
return invalidKey(_that);case ModelListUnreachable() when unreachable != null:
return unreachable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ModelListOk value)  ok,required TResult Function( ModelListInvalidKey value)  invalidKey,required TResult Function( ModelListUnreachable value)  unreachable,}){
final _that = this;
switch (_that) {
case ModelListOk():
return ok(_that);case ModelListInvalidKey():
return invalidKey(_that);case ModelListUnreachable():
return unreachable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ModelListOk value)?  ok,TResult? Function( ModelListInvalidKey value)?  invalidKey,TResult? Function( ModelListUnreachable value)?  unreachable,}){
final _that = this;
switch (_that) {
case ModelListOk() when ok != null:
return ok(_that);case ModelListInvalidKey() when invalidKey != null:
return invalidKey(_that);case ModelListUnreachable() when unreachable != null:
return unreachable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<ModelInfo> models)?  ok,TResult Function()?  invalidKey,TResult Function()?  unreachable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ModelListOk() when ok != null:
return ok(_that.models);case ModelListInvalidKey() when invalidKey != null:
return invalidKey();case ModelListUnreachable() when unreachable != null:
return unreachable();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<ModelInfo> models)  ok,required TResult Function()  invalidKey,required TResult Function()  unreachable,}) {final _that = this;
switch (_that) {
case ModelListOk():
return ok(_that.models);case ModelListInvalidKey():
return invalidKey();case ModelListUnreachable():
return unreachable();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<ModelInfo> models)?  ok,TResult? Function()?  invalidKey,TResult? Function()?  unreachable,}) {final _that = this;
switch (_that) {
case ModelListOk() when ok != null:
return ok(_that.models);case ModelListInvalidKey() when invalidKey != null:
return invalidKey();case ModelListUnreachable() when unreachable != null:
return unreachable();case _:
  return null;

}
}

}

/// @nodoc


class ModelListOk implements ModelListResult {
  const ModelListOk(final  List<ModelInfo> models): _models = models;
  

 final  List<ModelInfo> _models;
 List<ModelInfo> get models {
  if (_models is EqualUnmodifiableListView) return _models;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_models);
}


/// Create a copy of ModelListResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelListOkCopyWith<ModelListOk> get copyWith => _$ModelListOkCopyWithImpl<ModelListOk>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelListOk&&const DeepCollectionEquality().equals(other._models, _models));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_models));

@override
String toString() {
  return 'ModelListResult.ok(models: $models)';
}


}

/// @nodoc
abstract mixin class $ModelListOkCopyWith<$Res> implements $ModelListResultCopyWith<$Res> {
  factory $ModelListOkCopyWith(ModelListOk value, $Res Function(ModelListOk) _then) = _$ModelListOkCopyWithImpl;
@useResult
$Res call({
 List<ModelInfo> models
});




}
/// @nodoc
class _$ModelListOkCopyWithImpl<$Res>
    implements $ModelListOkCopyWith<$Res> {
  _$ModelListOkCopyWithImpl(this._self, this._then);

  final ModelListOk _self;
  final $Res Function(ModelListOk) _then;

/// Create a copy of ModelListResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? models = null,}) {
  return _then(ModelListOk(
null == models ? _self._models : models // ignore: cast_nullable_to_non_nullable
as List<ModelInfo>,
  ));
}


}

/// @nodoc


class ModelListInvalidKey implements ModelListResult {
  const ModelListInvalidKey();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelListInvalidKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelListResult.invalidKey()';
}


}




/// @nodoc


class ModelListUnreachable implements ModelListResult {
  const ModelListUnreachable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelListUnreachable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelListResult.unreachable()';
}


}




// dart format on
