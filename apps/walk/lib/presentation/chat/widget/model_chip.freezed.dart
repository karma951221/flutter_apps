// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_chip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModelChipData {

 ChatVendor get vendor; String get label; bool get fastMode; bool get hasNewer;
/// Create a copy of ModelChipData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelChipDataCopyWith<ModelChipData> get copyWith => _$ModelChipDataCopyWithImpl<ModelChipData>(this as ModelChipData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelChipData&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.label, label) || other.label == label)&&(identical(other.fastMode, fastMode) || other.fastMode == fastMode)&&(identical(other.hasNewer, hasNewer) || other.hasNewer == hasNewer));
}


@override
int get hashCode => Object.hash(runtimeType,vendor,label,fastMode,hasNewer);

@override
String toString() {
  return 'ModelChipData(vendor: $vendor, label: $label, fastMode: $fastMode, hasNewer: $hasNewer)';
}


}

/// @nodoc
abstract mixin class $ModelChipDataCopyWith<$Res>  {
  factory $ModelChipDataCopyWith(ModelChipData value, $Res Function(ModelChipData) _then) = _$ModelChipDataCopyWithImpl;
@useResult
$Res call({
 ChatVendor vendor, String label, bool fastMode, bool hasNewer
});




}
/// @nodoc
class _$ModelChipDataCopyWithImpl<$Res>
    implements $ModelChipDataCopyWith<$Res> {
  _$ModelChipDataCopyWithImpl(this._self, this._then);

  final ModelChipData _self;
  final $Res Function(ModelChipData) _then;

/// Create a copy of ModelChipData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vendor = null,Object? label = null,Object? fastMode = null,Object? hasNewer = null,}) {
  return _then(ModelChipData(
vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,fastMode: null == fastMode ? _self.fastMode : fastMode // ignore: cast_nullable_to_non_nullable
as bool,hasNewer: null == hasNewer ? _self.hasNewer : hasNewer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelChipData].
extension ModelChipDataPatterns on ModelChipData {
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
