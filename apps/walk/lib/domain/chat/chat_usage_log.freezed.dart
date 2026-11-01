// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_usage_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatUsageRecord {

 DateTime get at; String get questionKey; ChatVendor get vendor; String get model; bool get fastMode; ChatUsagePurpose get purpose; int get round; bool get temporary; int get inputTokens; int get outputTokens; int get cacheReadTokens; int get cacheWriteTokens; int? get reasoningTokens; int get wikiIndexNotes; int get wikiIndexChars; int get readWikiCalls;
/// Create a copy of ChatUsageRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatUsageRecordCopyWith<ChatUsageRecord> get copyWith => _$ChatUsageRecordCopyWithImpl<ChatUsageRecord>(this as ChatUsageRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatUsageRecord&&(identical(other.at, at) || other.at == at)&&(identical(other.questionKey, questionKey) || other.questionKey == questionKey)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.model, model) || other.model == model)&&(identical(other.fastMode, fastMode) || other.fastMode == fastMode)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.round, round) || other.round == round)&&(identical(other.temporary, temporary) || other.temporary == temporary)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens)&&(identical(other.cacheWriteTokens, cacheWriteTokens) || other.cacheWriteTokens == cacheWriteTokens)&&(identical(other.reasoningTokens, reasoningTokens) || other.reasoningTokens == reasoningTokens)&&(identical(other.wikiIndexNotes, wikiIndexNotes) || other.wikiIndexNotes == wikiIndexNotes)&&(identical(other.wikiIndexChars, wikiIndexChars) || other.wikiIndexChars == wikiIndexChars)&&(identical(other.readWikiCalls, readWikiCalls) || other.readWikiCalls == readWikiCalls));
}


@override
int get hashCode => Object.hash(runtimeType,at,questionKey,vendor,model,fastMode,purpose,round,temporary,inputTokens,outputTokens,cacheReadTokens,cacheWriteTokens,reasoningTokens,wikiIndexNotes,wikiIndexChars,readWikiCalls);

@override
String toString() {
  return 'ChatUsageRecord(at: $at, questionKey: $questionKey, vendor: $vendor, model: $model, fastMode: $fastMode, purpose: $purpose, round: $round, temporary: $temporary, inputTokens: $inputTokens, outputTokens: $outputTokens, cacheReadTokens: $cacheReadTokens, cacheWriteTokens: $cacheWriteTokens, reasoningTokens: $reasoningTokens, wikiIndexNotes: $wikiIndexNotes, wikiIndexChars: $wikiIndexChars, readWikiCalls: $readWikiCalls)';
}


}

/// @nodoc
abstract mixin class $ChatUsageRecordCopyWith<$Res>  {
  factory $ChatUsageRecordCopyWith(ChatUsageRecord value, $Res Function(ChatUsageRecord) _then) = _$ChatUsageRecordCopyWithImpl;
@useResult
$Res call({
 DateTime at, String questionKey, ChatVendor vendor, String model, bool fastMode, ChatUsagePurpose purpose, int round, bool temporary, int inputTokens, int outputTokens, int cacheReadTokens, int cacheWriteTokens, int? reasoningTokens, int wikiIndexNotes, int wikiIndexChars, int readWikiCalls
});




}
/// @nodoc
class _$ChatUsageRecordCopyWithImpl<$Res>
    implements $ChatUsageRecordCopyWith<$Res> {
  _$ChatUsageRecordCopyWithImpl(this._self, this._then);

  final ChatUsageRecord _self;
  final $Res Function(ChatUsageRecord) _then;

/// Create a copy of ChatUsageRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? at = null,Object? questionKey = null,Object? vendor = null,Object? model = null,Object? fastMode = null,Object? purpose = null,Object? round = null,Object? temporary = null,Object? inputTokens = null,Object? outputTokens = null,Object? cacheReadTokens = null,Object? cacheWriteTokens = null,Object? reasoningTokens = freezed,Object? wikiIndexNotes = null,Object? wikiIndexChars = null,Object? readWikiCalls = null,}) {
  return _then(ChatUsageRecord(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,questionKey: null == questionKey ? _self.questionKey : questionKey // ignore: cast_nullable_to_non_nullable
as String,vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,fastMode: null == fastMode ? _self.fastMode : fastMode // ignore: cast_nullable_to_non_nullable
as bool,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as ChatUsagePurpose,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,temporary: null == temporary ? _self.temporary : temporary // ignore: cast_nullable_to_non_nullable
as bool,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,cacheReadTokens: null == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int,cacheWriteTokens: null == cacheWriteTokens ? _self.cacheWriteTokens : cacheWriteTokens // ignore: cast_nullable_to_non_nullable
as int,reasoningTokens: freezed == reasoningTokens ? _self.reasoningTokens : reasoningTokens // ignore: cast_nullable_to_non_nullable
as int?,wikiIndexNotes: null == wikiIndexNotes ? _self.wikiIndexNotes : wikiIndexNotes // ignore: cast_nullable_to_non_nullable
as int,wikiIndexChars: null == wikiIndexChars ? _self.wikiIndexChars : wikiIndexChars // ignore: cast_nullable_to_non_nullable
as int,readWikiCalls: null == readWikiCalls ? _self.readWikiCalls : readWikiCalls // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatUsageRecord].
extension ChatUsageRecordPatterns on ChatUsageRecord {
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
