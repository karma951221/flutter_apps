// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModelPickerRow {

 String get id; String get label; DateTime? get createdAt; bool get recommended; bool get isNew; bool get inUse; bool get noImages;
/// Create a copy of ModelPickerRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelPickerRowCopyWith<ModelPickerRow> get copyWith => _$ModelPickerRowCopyWithImpl<ModelPickerRow>(this as ModelPickerRow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelPickerRow&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.recommended, recommended) || other.recommended == recommended)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.inUse, inUse) || other.inUse == inUse)&&(identical(other.noImages, noImages) || other.noImages == noImages));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,createdAt,recommended,isNew,inUse,noImages);

@override
String toString() {
  return 'ModelPickerRow(id: $id, label: $label, createdAt: $createdAt, recommended: $recommended, isNew: $isNew, inUse: $inUse, noImages: $noImages)';
}


}

/// @nodoc
abstract mixin class $ModelPickerRowCopyWith<$Res>  {
  factory $ModelPickerRowCopyWith(ModelPickerRow value, $Res Function(ModelPickerRow) _then) = _$ModelPickerRowCopyWithImpl;
@useResult
$Res call({
 String id, String label, DateTime? createdAt, bool recommended, bool isNew, bool inUse, bool noImages
});




}
/// @nodoc
class _$ModelPickerRowCopyWithImpl<$Res>
    implements $ModelPickerRowCopyWith<$Res> {
  _$ModelPickerRowCopyWithImpl(this._self, this._then);

  final ModelPickerRow _self;
  final $Res Function(ModelPickerRow) _then;

/// Create a copy of ModelPickerRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? createdAt = freezed,Object? recommended = null,Object? isNew = null,Object? inUse = null,Object? noImages = null,}) {
  return _then(ModelPickerRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recommended: null == recommended ? _self.recommended : recommended // ignore: cast_nullable_to_non_nullable
as bool,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,inUse: null == inUse ? _self.inUse : inUse // ignore: cast_nullable_to_non_nullable
as bool,noImages: null == noImages ? _self.noImages : noImages // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelPickerRow].
extension ModelPickerRowPatterns on ModelPickerRow {
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
mixin _$ModelPickerState {

 List<ModelPickerRow> get rows; bool get fastModeAvailable; bool get fastMode; double? get fastModeFactor; ChatVendor get company; bool get changed;
/// Create a copy of ModelPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelPickerStateCopyWith<ModelPickerState> get copyWith => _$ModelPickerStateCopyWithImpl<ModelPickerState>(this as ModelPickerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelPickerState&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.fastModeAvailable, fastModeAvailable) || other.fastModeAvailable == fastModeAvailable)&&(identical(other.fastMode, fastMode) || other.fastMode == fastMode)&&(identical(other.fastModeFactor, fastModeFactor) || other.fastModeFactor == fastModeFactor)&&(identical(other.company, company) || other.company == company)&&(identical(other.changed, changed) || other.changed == changed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),fastModeAvailable,fastMode,fastModeFactor,company,changed);

@override
String toString() {
  return 'ModelPickerState(rows: $rows, fastModeAvailable: $fastModeAvailable, fastMode: $fastMode, fastModeFactor: $fastModeFactor, company: $company, changed: $changed)';
}


}

/// @nodoc
abstract mixin class $ModelPickerStateCopyWith<$Res>  {
  factory $ModelPickerStateCopyWith(ModelPickerState value, $Res Function(ModelPickerState) _then) = _$ModelPickerStateCopyWithImpl;
@useResult
$Res call({
 List<ModelPickerRow> rows, bool fastModeAvailable, bool fastMode, double? fastModeFactor, ChatVendor company, bool changed
});




}
/// @nodoc
class _$ModelPickerStateCopyWithImpl<$Res>
    implements $ModelPickerStateCopyWith<$Res> {
  _$ModelPickerStateCopyWithImpl(this._self, this._then);

  final ModelPickerState _self;
  final $Res Function(ModelPickerState) _then;

/// Create a copy of ModelPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? fastModeAvailable = null,Object? fastMode = null,Object? fastModeFactor = freezed,Object? company = null,Object? changed = null,}) {
  return _then(ModelPickerState(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<ModelPickerRow>,fastModeAvailable: null == fastModeAvailable ? _self.fastModeAvailable : fastModeAvailable // ignore: cast_nullable_to_non_nullable
as bool,fastMode: null == fastMode ? _self.fastMode : fastMode // ignore: cast_nullable_to_non_nullable
as bool,fastModeFactor: freezed == fastModeFactor ? _self.fastModeFactor : fastModeFactor // ignore: cast_nullable_to_non_nullable
as double?,company: null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as ChatVendor,changed: null == changed ? _self.changed : changed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelPickerState].
extension ModelPickerStatePatterns on ModelPickerState {
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
