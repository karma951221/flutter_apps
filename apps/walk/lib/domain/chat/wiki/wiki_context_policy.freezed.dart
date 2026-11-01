// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wiki_context_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WikiContext {

 String? get systemSection; List<ToolSpec> get tools; int get indexNotes; int get indexChars;
/// Create a copy of WikiContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiContextCopyWith<WikiContext> get copyWith => _$WikiContextCopyWithImpl<WikiContext>(this as WikiContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiContext&&(identical(other.systemSection, systemSection) || other.systemSection == systemSection)&&const DeepCollectionEquality().equals(other.tools, tools)&&(identical(other.indexNotes, indexNotes) || other.indexNotes == indexNotes)&&(identical(other.indexChars, indexChars) || other.indexChars == indexChars));
}


@override
int get hashCode => Object.hash(runtimeType,systemSection,const DeepCollectionEquality().hash(tools),indexNotes,indexChars);



}

/// @nodoc
abstract mixin class $WikiContextCopyWith<$Res>  {
  factory $WikiContextCopyWith(WikiContext value, $Res Function(WikiContext) _then) = _$WikiContextCopyWithImpl;
@useResult
$Res call({
 String? systemSection, List<ToolSpec> tools, int indexNotes, int indexChars
});




}
/// @nodoc
class _$WikiContextCopyWithImpl<$Res>
    implements $WikiContextCopyWith<$Res> {
  _$WikiContextCopyWithImpl(this._self, this._then);

  final WikiContext _self;
  final $Res Function(WikiContext) _then;

/// Create a copy of WikiContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? systemSection = freezed,Object? tools = null,Object? indexNotes = null,Object? indexChars = null,}) {
  return _then(WikiContext(
systemSection: freezed == systemSection ? _self.systemSection : systemSection // ignore: cast_nullable_to_non_nullable
as String?,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<ToolSpec>,indexNotes: null == indexNotes ? _self.indexNotes : indexNotes // ignore: cast_nullable_to_non_nullable
as int,indexChars: null == indexChars ? _self.indexChars : indexChars // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WikiContext].
extension WikiContextPatterns on WikiContext {
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
