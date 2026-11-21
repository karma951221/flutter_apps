// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'answer_segments.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AnswerSegment {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswerSegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AnswerSegment()';
}


}

/// @nodoc
class $AnswerSegmentCopyWith<$Res>  {
$AnswerSegmentCopyWith(AnswerSegment _, $Res Function(AnswerSegment) __);
}


/// Adds pattern-matching-related methods to [AnswerSegment].
extension AnswerSegmentPatterns on AnswerSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarkdownSegment value)?  markdown,TResult Function( SvgSegment value)?  svg,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarkdownSegment() when markdown != null:
return markdown(_that);case SvgSegment() when svg != null:
return svg(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarkdownSegment value)  markdown,required TResult Function( SvgSegment value)  svg,}){
final _that = this;
switch (_that) {
case MarkdownSegment():
return markdown(_that);case SvgSegment():
return svg(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarkdownSegment value)?  markdown,TResult? Function( SvgSegment value)?  svg,}){
final _that = this;
switch (_that) {
case MarkdownSegment() when markdown != null:
return markdown(_that);case SvgSegment() when svg != null:
return svg(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  markdown,TResult Function( String svg,  String source)?  svg,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarkdownSegment() when markdown != null:
return markdown(_that.text);case SvgSegment() when svg != null:
return svg(_that.svg,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  markdown,required TResult Function( String svg,  String source)  svg,}) {final _that = this;
switch (_that) {
case MarkdownSegment():
return markdown(_that.text);case SvgSegment():
return svg(_that.svg,_that.source);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  markdown,TResult? Function( String svg,  String source)?  svg,}) {final _that = this;
switch (_that) {
case MarkdownSegment() when markdown != null:
return markdown(_that.text);case SvgSegment() when svg != null:
return svg(_that.svg,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class MarkdownSegment implements AnswerSegment {
  const MarkdownSegment(this.text);
  

 final  String text;

/// Create a copy of AnswerSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownSegmentCopyWith<MarkdownSegment> get copyWith => _$MarkdownSegmentCopyWithImpl<MarkdownSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownSegment&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'AnswerSegment.markdown(text: $text)';
}


}

/// @nodoc
abstract mixin class $MarkdownSegmentCopyWith<$Res> implements $AnswerSegmentCopyWith<$Res> {
  factory $MarkdownSegmentCopyWith(MarkdownSegment value, $Res Function(MarkdownSegment) _then) = _$MarkdownSegmentCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$MarkdownSegmentCopyWithImpl<$Res>
    implements $MarkdownSegmentCopyWith<$Res> {
  _$MarkdownSegmentCopyWithImpl(this._self, this._then);

  final MarkdownSegment _self;
  final $Res Function(MarkdownSegment) _then;

/// Create a copy of AnswerSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(MarkdownSegment(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SvgSegment implements AnswerSegment {
  const SvgSegment({required this.svg, required this.source});
  

 final  String svg;
 final  String source;

/// Create a copy of AnswerSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SvgSegmentCopyWith<SvgSegment> get copyWith => _$SvgSegmentCopyWithImpl<SvgSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SvgSegment&&(identical(other.svg, svg) || other.svg == svg)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,svg,source);

@override
String toString() {
  return 'AnswerSegment.svg(svg: $svg, source: $source)';
}


}

/// @nodoc
abstract mixin class $SvgSegmentCopyWith<$Res> implements $AnswerSegmentCopyWith<$Res> {
  factory $SvgSegmentCopyWith(SvgSegment value, $Res Function(SvgSegment) _then) = _$SvgSegmentCopyWithImpl;
@useResult
$Res call({
 String svg, String source
});




}
/// @nodoc
class _$SvgSegmentCopyWithImpl<$Res>
    implements $SvgSegmentCopyWith<$Res> {
  _$SvgSegmentCopyWithImpl(this._self, this._then);

  final SvgSegment _self;
  final $Res Function(SvgSegment) _then;

/// Create a copy of AnswerSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? svg = null,Object? source = null,}) {
  return _then(SvgSegment(
svg: null == svg ? _self.svg : svg // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
