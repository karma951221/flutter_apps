// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_loader.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PickedFile {

 String get name; String get path; int get sizeBytes; String? get workspacePath;
/// Create a copy of PickedFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickedFileCopyWith<PickedFile> get copyWith => _$PickedFileCopyWithImpl<PickedFile>(this as PickedFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickedFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.workspacePath, workspacePath) || other.workspacePath == workspacePath));
}


@override
int get hashCode => Object.hash(runtimeType,name,path,sizeBytes,workspacePath);

@override
String toString() {
  return 'PickedFile(name: $name, path: $path, sizeBytes: $sizeBytes, workspacePath: $workspacePath)';
}


}

/// @nodoc
abstract mixin class $PickedFileCopyWith<$Res>  {
  factory $PickedFileCopyWith(PickedFile value, $Res Function(PickedFile) _then) = _$PickedFileCopyWithImpl;
@useResult
$Res call({
 String name, String path, int sizeBytes, String? workspacePath
});




}
/// @nodoc
class _$PickedFileCopyWithImpl<$Res>
    implements $PickedFileCopyWith<$Res> {
  _$PickedFileCopyWithImpl(this._self, this._then);

  final PickedFile _self;
  final $Res Function(PickedFile) _then;

/// Create a copy of PickedFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? sizeBytes = null,Object? workspacePath = freezed,}) {
  return _then(PickedFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,workspacePath: freezed == workspacePath ? _self.workspacePath : workspacePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PickedFile].
extension PickedFilePatterns on PickedFile {
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
mixin _$AttachmentLoad {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentLoad);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AttachmentLoad()';
}


}

/// @nodoc
class $AttachmentLoadCopyWith<$Res>  {
$AttachmentLoadCopyWith(AttachmentLoad _, $Res Function(AttachmentLoad) __);
}


/// Adds pattern-matching-related methods to [AttachmentLoad].
extension AttachmentLoadPatterns on AttachmentLoad {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AttachmentLoaded value)?  ok,TResult Function( AttachmentRejected value)?  rejected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AttachmentLoaded() when ok != null:
return ok(_that);case AttachmentRejected() when rejected != null:
return rejected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AttachmentLoaded value)  ok,required TResult Function( AttachmentRejected value)  rejected,}){
final _that = this;
switch (_that) {
case AttachmentLoaded():
return ok(_that);case AttachmentRejected():
return rejected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AttachmentLoaded value)?  ok,TResult? Function( AttachmentRejected value)?  rejected,}){
final _that = this;
switch (_that) {
case AttachmentLoaded() when ok != null:
return ok(_that);case AttachmentRejected() when rejected != null:
return rejected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ChatAttachment attachment)?  ok,TResult Function( String name,  AttachmentRejection why)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AttachmentLoaded() when ok != null:
return ok(_that.attachment);case AttachmentRejected() when rejected != null:
return rejected(_that.name,_that.why);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ChatAttachment attachment)  ok,required TResult Function( String name,  AttachmentRejection why)  rejected,}) {final _that = this;
switch (_that) {
case AttachmentLoaded():
return ok(_that.attachment);case AttachmentRejected():
return rejected(_that.name,_that.why);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ChatAttachment attachment)?  ok,TResult? Function( String name,  AttachmentRejection why)?  rejected,}) {final _that = this;
switch (_that) {
case AttachmentLoaded() when ok != null:
return ok(_that.attachment);case AttachmentRejected() when rejected != null:
return rejected(_that.name,_that.why);case _:
  return null;

}
}

}

/// @nodoc


class AttachmentLoaded implements AttachmentLoad {
  const AttachmentLoaded(this.attachment);
  

 final  ChatAttachment attachment;

/// Create a copy of AttachmentLoad
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentLoadedCopyWith<AttachmentLoaded> get copyWith => _$AttachmentLoadedCopyWithImpl<AttachmentLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentLoaded&&(identical(other.attachment, attachment) || other.attachment == attachment));
}


@override
int get hashCode => Object.hash(runtimeType,attachment);

@override
String toString() {
  return 'AttachmentLoad.ok(attachment: $attachment)';
}


}

/// @nodoc
abstract mixin class $AttachmentLoadedCopyWith<$Res> implements $AttachmentLoadCopyWith<$Res> {
  factory $AttachmentLoadedCopyWith(AttachmentLoaded value, $Res Function(AttachmentLoaded) _then) = _$AttachmentLoadedCopyWithImpl;
@useResult
$Res call({
 ChatAttachment attachment
});


$ChatAttachmentCopyWith<$Res> get attachment;

}
/// @nodoc
class _$AttachmentLoadedCopyWithImpl<$Res>
    implements $AttachmentLoadedCopyWith<$Res> {
  _$AttachmentLoadedCopyWithImpl(this._self, this._then);

  final AttachmentLoaded _self;
  final $Res Function(AttachmentLoaded) _then;

/// Create a copy of AttachmentLoad
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attachment = null,}) {
  return _then(AttachmentLoaded(
null == attachment ? _self.attachment : attachment // ignore: cast_nullable_to_non_nullable
as ChatAttachment,
  ));
}

/// Create a copy of AttachmentLoad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatAttachmentCopyWith<$Res> get attachment {
  
  return $ChatAttachmentCopyWith<$Res>(_self.attachment, (value) {
    return _then(_self.copyWith(attachment: value));
  });
}
}

/// @nodoc


class AttachmentRejected implements AttachmentLoad {
  const AttachmentRejected(this.name, this.why);
  

 final  String name;
 final  AttachmentRejection why;

/// Create a copy of AttachmentLoad
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentRejectedCopyWith<AttachmentRejected> get copyWith => _$AttachmentRejectedCopyWithImpl<AttachmentRejected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentRejected&&(identical(other.name, name) || other.name == name)&&(identical(other.why, why) || other.why == why));
}


@override
int get hashCode => Object.hash(runtimeType,name,why);

@override
String toString() {
  return 'AttachmentLoad.rejected(name: $name, why: $why)';
}


}

/// @nodoc
abstract mixin class $AttachmentRejectedCopyWith<$Res> implements $AttachmentLoadCopyWith<$Res> {
  factory $AttachmentRejectedCopyWith(AttachmentRejected value, $Res Function(AttachmentRejected) _then) = _$AttachmentRejectedCopyWithImpl;
@useResult
$Res call({
 String name, AttachmentRejection why
});




}
/// @nodoc
class _$AttachmentRejectedCopyWithImpl<$Res>
    implements $AttachmentRejectedCopyWith<$Res> {
  _$AttachmentRejectedCopyWithImpl(this._self, this._then);

  final AttachmentRejected _self;
  final $Res Function(AttachmentRejected) _then;

/// Create a copy of AttachmentLoad
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? why = null,}) {
  return _then(AttachmentRejected(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as AttachmentRejection,
  ));
}


}

// dart format on
