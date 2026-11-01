// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_usage_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatUsageTotals {

 int get questions; int get inputTokens; int get outputTokens; int get cacheReadTokens;
/// Create a copy of ChatUsageTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatUsageTotalsCopyWith<ChatUsageTotals> get copyWith => _$ChatUsageTotalsCopyWithImpl<ChatUsageTotals>(this as ChatUsageTotals, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatUsageTotals&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens));
}


@override
int get hashCode => Object.hash(runtimeType,questions,inputTokens,outputTokens,cacheReadTokens);

@override
String toString() {
  return 'ChatUsageTotals(questions: $questions, inputTokens: $inputTokens, outputTokens: $outputTokens, cacheReadTokens: $cacheReadTokens)';
}


}

/// @nodoc
abstract mixin class $ChatUsageTotalsCopyWith<$Res>  {
  factory $ChatUsageTotalsCopyWith(ChatUsageTotals value, $Res Function(ChatUsageTotals) _then) = _$ChatUsageTotalsCopyWithImpl;
@useResult
$Res call({
 int questions, int inputTokens, int outputTokens, int cacheReadTokens
});




}
/// @nodoc
class _$ChatUsageTotalsCopyWithImpl<$Res>
    implements $ChatUsageTotalsCopyWith<$Res> {
  _$ChatUsageTotalsCopyWithImpl(this._self, this._then);

  final ChatUsageTotals _self;
  final $Res Function(ChatUsageTotals) _then;

/// Create a copy of ChatUsageTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questions = null,Object? inputTokens = null,Object? outputTokens = null,Object? cacheReadTokens = null,}) {
  return _then(ChatUsageTotals(
questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,cacheReadTokens: null == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatUsageTotals].
extension ChatUsageTotalsPatterns on ChatUsageTotals {
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
mixin _$ChatUsageModelRow {

 ChatVendor get vendor; String get model; ChatUsagePurpose get purpose; int get questions; int get inputTokens; int get outputTokens;
/// Create a copy of ChatUsageModelRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatUsageModelRowCopyWith<ChatUsageModelRow> get copyWith => _$ChatUsageModelRowCopyWithImpl<ChatUsageModelRow>(this as ChatUsageModelRow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatUsageModelRow&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.model, model) || other.model == model)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens));
}


@override
int get hashCode => Object.hash(runtimeType,vendor,model,purpose,questions,inputTokens,outputTokens);

@override
String toString() {
  return 'ChatUsageModelRow(vendor: $vendor, model: $model, purpose: $purpose, questions: $questions, inputTokens: $inputTokens, outputTokens: $outputTokens)';
}


}

/// @nodoc
abstract mixin class $ChatUsageModelRowCopyWith<$Res>  {
  factory $ChatUsageModelRowCopyWith(ChatUsageModelRow value, $Res Function(ChatUsageModelRow) _then) = _$ChatUsageModelRowCopyWithImpl;
@useResult
$Res call({
 ChatVendor vendor, String model, ChatUsagePurpose purpose, int questions, int inputTokens, int outputTokens
});




}
/// @nodoc
class _$ChatUsageModelRowCopyWithImpl<$Res>
    implements $ChatUsageModelRowCopyWith<$Res> {
  _$ChatUsageModelRowCopyWithImpl(this._self, this._then);

  final ChatUsageModelRow _self;
  final $Res Function(ChatUsageModelRow) _then;

/// Create a copy of ChatUsageModelRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vendor = null,Object? model = null,Object? purpose = null,Object? questions = null,Object? inputTokens = null,Object? outputTokens = null,}) {
  return _then(ChatUsageModelRow(
vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as ChatUsagePurpose,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatUsageModelRow].
extension ChatUsageModelRowPatterns on ChatUsageModelRow {
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
mixin _$ChatUsageMonth {

 int get year; int get month; ChatUsageTotals get totals; List<ChatUsageModelRow> get rows;
/// Create a copy of ChatUsageMonth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatUsageMonthCopyWith<ChatUsageMonth> get copyWith => _$ChatUsageMonthCopyWithImpl<ChatUsageMonth>(this as ChatUsageMonth, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatUsageMonth&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.totals, totals) || other.totals == totals)&&const DeepCollectionEquality().equals(other.rows, rows));
}


@override
int get hashCode => Object.hash(runtimeType,year,month,totals,const DeepCollectionEquality().hash(rows));

@override
String toString() {
  return 'ChatUsageMonth(year: $year, month: $month, totals: $totals, rows: $rows)';
}


}

/// @nodoc
abstract mixin class $ChatUsageMonthCopyWith<$Res>  {
  factory $ChatUsageMonthCopyWith(ChatUsageMonth value, $Res Function(ChatUsageMonth) _then) = _$ChatUsageMonthCopyWithImpl;
@useResult
$Res call({
 int year, int month, ChatUsageTotals totals, List<ChatUsageModelRow> rows
});




}
/// @nodoc
class _$ChatUsageMonthCopyWithImpl<$Res>
    implements $ChatUsageMonthCopyWith<$Res> {
  _$ChatUsageMonthCopyWithImpl(this._self, this._then);

  final ChatUsageMonth _self;
  final $Res Function(ChatUsageMonth) _then;

/// Create a copy of ChatUsageMonth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? month = null,Object? totals = null,Object? rows = null,}) {
  return _then(ChatUsageMonth(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as ChatUsageTotals,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<ChatUsageModelRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatUsageMonth].
extension ChatUsageMonthPatterns on ChatUsageMonth {
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
