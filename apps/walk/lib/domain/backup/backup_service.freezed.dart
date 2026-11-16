// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AreaPreview {

 Map<String, int> get counts; int get bytes;
/// Create a copy of AreaPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AreaPreviewCopyWith<AreaPreview> get copyWith => _$AreaPreviewCopyWithImpl<AreaPreview>(this as AreaPreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AreaPreview&&const DeepCollectionEquality().equals(other.counts, counts)&&(identical(other.bytes, bytes) || other.bytes == bytes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(counts),bytes);

@override
String toString() {
  return 'AreaPreview(counts: $counts, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $AreaPreviewCopyWith<$Res>  {
  factory $AreaPreviewCopyWith(AreaPreview value, $Res Function(AreaPreview) _then) = _$AreaPreviewCopyWithImpl;
@useResult
$Res call({
 Map<String, int> counts, int bytes
});




}
/// @nodoc
class _$AreaPreviewCopyWithImpl<$Res>
    implements $AreaPreviewCopyWith<$Res> {
  _$AreaPreviewCopyWithImpl(this._self, this._then);

  final AreaPreview _self;
  final $Res Function(AreaPreview) _then;

/// Create a copy of AreaPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? counts = null,Object? bytes = null,}) {
  return _then(AreaPreview(
counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AreaPreview].
extension AreaPreviewPatterns on AreaPreview {
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
mixin _$InspectedBackup {

 BackupManifest get manifest; Directory get staging; Map<BackupAreaId, AreaAvailability> get areas;
/// Create a copy of InspectedBackup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectedBackupCopyWith<InspectedBackup> get copyWith => _$InspectedBackupCopyWithImpl<InspectedBackup>(this as InspectedBackup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectedBackup&&(identical(other.manifest, manifest) || other.manifest == manifest)&&(identical(other.staging, staging) || other.staging == staging)&&const DeepCollectionEquality().equals(other.areas, areas));
}


@override
int get hashCode => Object.hash(runtimeType,manifest,staging,const DeepCollectionEquality().hash(areas));

@override
String toString() {
  return 'InspectedBackup(manifest: $manifest, staging: $staging, areas: $areas)';
}


}

/// @nodoc
abstract mixin class $InspectedBackupCopyWith<$Res>  {
  factory $InspectedBackupCopyWith(InspectedBackup value, $Res Function(InspectedBackup) _then) = _$InspectedBackupCopyWithImpl;
@useResult
$Res call({
 BackupManifest manifest, Directory staging, Map<BackupAreaId, AreaAvailability> areas
});




}
/// @nodoc
class _$InspectedBackupCopyWithImpl<$Res>
    implements $InspectedBackupCopyWith<$Res> {
  _$InspectedBackupCopyWithImpl(this._self, this._then);

  final InspectedBackup _self;
  final $Res Function(InspectedBackup) _then;

/// Create a copy of InspectedBackup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? manifest = null,Object? staging = null,Object? areas = null,}) {
  return _then(InspectedBackup(
manifest: null == manifest ? _self.manifest : manifest // ignore: cast_nullable_to_non_nullable
as BackupManifest,staging: null == staging ? _self.staging : staging // ignore: cast_nullable_to_non_nullable
as Directory,areas: null == areas ? _self.areas : areas // ignore: cast_nullable_to_non_nullable
as Map<BackupAreaId, AreaAvailability>,
  ));
}

}


/// Adds pattern-matching-related methods to [InspectedBackup].
extension InspectedBackupPatterns on InspectedBackup {
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
