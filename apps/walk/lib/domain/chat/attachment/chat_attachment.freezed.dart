// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatAttachment {

 String get name; String? get workspacePath;
/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatAttachmentCopyWith<ChatAttachment> get copyWith => _$ChatAttachmentCopyWithImpl<ChatAttachment>(this as ChatAttachment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAttachment&&(identical(other.name, name) || other.name == name)&&(identical(other.workspacePath, workspacePath) || other.workspacePath == workspacePath));
}


@override
int get hashCode => Object.hash(runtimeType,name,workspacePath);



}

/// @nodoc
abstract mixin class $ChatAttachmentCopyWith<$Res>  {
  factory $ChatAttachmentCopyWith(ChatAttachment value, $Res Function(ChatAttachment) _then) = _$ChatAttachmentCopyWithImpl;
@useResult
$Res call({
 String name, String? workspacePath
});




}
/// @nodoc
class _$ChatAttachmentCopyWithImpl<$Res>
    implements $ChatAttachmentCopyWith<$Res> {
  _$ChatAttachmentCopyWithImpl(this._self, this._then);

  final ChatAttachment _self;
  final $Res Function(ChatAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? workspacePath = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,workspacePath: freezed == workspacePath ? _self.workspacePath : workspacePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatAttachment].
extension ChatAttachmentPatterns on ChatAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ImageAttachment value)?  image,TResult Function( PdfAttachment value)?  pdf,TResult Function( TextAttachment value)?  text,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ImageAttachment() when image != null:
return image(_that);case PdfAttachment() when pdf != null:
return pdf(_that);case TextAttachment() when text != null:
return text(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ImageAttachment value)  image,required TResult Function( PdfAttachment value)  pdf,required TResult Function( TextAttachment value)  text,}){
final _that = this;
switch (_that) {
case ImageAttachment():
return image(_that);case PdfAttachment():
return pdf(_that);case TextAttachment():
return text(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ImageAttachment value)?  image,TResult? Function( PdfAttachment value)?  pdf,TResult? Function( TextAttachment value)?  text,}){
final _that = this;
switch (_that) {
case ImageAttachment() when image != null:
return image(_that);case PdfAttachment() when pdf != null:
return pdf(_that);case TextAttachment() when text != null:
return text(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name,  String mediaType,  Uint8List bytes,  String? workspacePath)?  image,TResult Function( String name,  Uint8List bytes,  String? workspacePath)?  pdf,TResult Function( String name,  String text,  String? workspacePath)?  text,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ImageAttachment() when image != null:
return image(_that.name,_that.mediaType,_that.bytes,_that.workspacePath);case PdfAttachment() when pdf != null:
return pdf(_that.name,_that.bytes,_that.workspacePath);case TextAttachment() when text != null:
return text(_that.name,_that.text,_that.workspacePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name,  String mediaType,  Uint8List bytes,  String? workspacePath)  image,required TResult Function( String name,  Uint8List bytes,  String? workspacePath)  pdf,required TResult Function( String name,  String text,  String? workspacePath)  text,}) {final _that = this;
switch (_that) {
case ImageAttachment():
return image(_that.name,_that.mediaType,_that.bytes,_that.workspacePath);case PdfAttachment():
return pdf(_that.name,_that.bytes,_that.workspacePath);case TextAttachment():
return text(_that.name,_that.text,_that.workspacePath);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name,  String mediaType,  Uint8List bytes,  String? workspacePath)?  image,TResult? Function( String name,  Uint8List bytes,  String? workspacePath)?  pdf,TResult? Function( String name,  String text,  String? workspacePath)?  text,}) {final _that = this;
switch (_that) {
case ImageAttachment() when image != null:
return image(_that.name,_that.mediaType,_that.bytes,_that.workspacePath);case PdfAttachment() when pdf != null:
return pdf(_that.name,_that.bytes,_that.workspacePath);case TextAttachment() when text != null:
return text(_that.name,_that.text,_that.workspacePath);case _:
  return null;

}
}

}

/// @nodoc


class ImageAttachment implements ChatAttachment {
  const ImageAttachment({required this.name, required this.mediaType, required this.bytes, this.workspacePath});
  

@override final  String name;
 final  String mediaType;
 final  Uint8List bytes;
@override final  String? workspacePath;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageAttachmentCopyWith<ImageAttachment> get copyWith => _$ImageAttachmentCopyWithImpl<ImageAttachment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageAttachment&&(identical(other.name, name) || other.name == name)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.workspacePath, workspacePath) || other.workspacePath == workspacePath));
}


@override
int get hashCode => Object.hash(runtimeType,name,mediaType,const DeepCollectionEquality().hash(bytes),workspacePath);



}

/// @nodoc
abstract mixin class $ImageAttachmentCopyWith<$Res> implements $ChatAttachmentCopyWith<$Res> {
  factory $ImageAttachmentCopyWith(ImageAttachment value, $Res Function(ImageAttachment) _then) = _$ImageAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String name, String mediaType, Uint8List bytes, String? workspacePath
});




}
/// @nodoc
class _$ImageAttachmentCopyWithImpl<$Res>
    implements $ImageAttachmentCopyWith<$Res> {
  _$ImageAttachmentCopyWithImpl(this._self, this._then);

  final ImageAttachment _self;
  final $Res Function(ImageAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? mediaType = null,Object? bytes = null,Object? workspacePath = freezed,}) {
  return _then(ImageAttachment(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,workspacePath: freezed == workspacePath ? _self.workspacePath : workspacePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PdfAttachment implements ChatAttachment {
  const PdfAttachment({required this.name, required this.bytes, this.workspacePath});
  

@override final  String name;
 final  Uint8List bytes;
@override final  String? workspacePath;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfAttachmentCopyWith<PdfAttachment> get copyWith => _$PdfAttachmentCopyWithImpl<PdfAttachment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfAttachment&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.workspacePath, workspacePath) || other.workspacePath == workspacePath));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(bytes),workspacePath);



}

/// @nodoc
abstract mixin class $PdfAttachmentCopyWith<$Res> implements $ChatAttachmentCopyWith<$Res> {
  factory $PdfAttachmentCopyWith(PdfAttachment value, $Res Function(PdfAttachment) _then) = _$PdfAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String name, Uint8List bytes, String? workspacePath
});




}
/// @nodoc
class _$PdfAttachmentCopyWithImpl<$Res>
    implements $PdfAttachmentCopyWith<$Res> {
  _$PdfAttachmentCopyWithImpl(this._self, this._then);

  final PdfAttachment _self;
  final $Res Function(PdfAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? bytes = null,Object? workspacePath = freezed,}) {
  return _then(PdfAttachment(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,workspacePath: freezed == workspacePath ? _self.workspacePath : workspacePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class TextAttachment implements ChatAttachment {
  const TextAttachment({required this.name, required this.text, this.workspacePath});
  

@override final  String name;
 final  String text;
@override final  String? workspacePath;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextAttachmentCopyWith<TextAttachment> get copyWith => _$TextAttachmentCopyWithImpl<TextAttachment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextAttachment&&(identical(other.name, name) || other.name == name)&&(identical(other.text, text) || other.text == text)&&(identical(other.workspacePath, workspacePath) || other.workspacePath == workspacePath));
}


@override
int get hashCode => Object.hash(runtimeType,name,text,workspacePath);



}

/// @nodoc
abstract mixin class $TextAttachmentCopyWith<$Res> implements $ChatAttachmentCopyWith<$Res> {
  factory $TextAttachmentCopyWith(TextAttachment value, $Res Function(TextAttachment) _then) = _$TextAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String name, String text, String? workspacePath
});




}
/// @nodoc
class _$TextAttachmentCopyWithImpl<$Res>
    implements $TextAttachmentCopyWith<$Res> {
  _$TextAttachmentCopyWithImpl(this._self, this._then);

  final TextAttachment _self;
  final $Res Function(TextAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? text = null,Object? workspacePath = freezed,}) {
  return _then(TextAttachment(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,workspacePath: freezed == workspacePath ? _self.workspacePath : workspacePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatAttachmentRef {

 String get name; AttachmentKind get kind; String? get workspacePath;
/// Create a copy of ChatAttachmentRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatAttachmentRefCopyWith<ChatAttachmentRef> get copyWith => _$ChatAttachmentRefCopyWithImpl<ChatAttachmentRef>(this as ChatAttachmentRef, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAttachmentRef&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.workspacePath, workspacePath) || other.workspacePath == workspacePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,kind,workspacePath);

@override
String toString() {
  return 'ChatAttachmentRef(name: $name, kind: $kind, workspacePath: $workspacePath)';
}


}

/// @nodoc
abstract mixin class $ChatAttachmentRefCopyWith<$Res>  {
  factory $ChatAttachmentRefCopyWith(ChatAttachmentRef value, $Res Function(ChatAttachmentRef) _then) = _$ChatAttachmentRefCopyWithImpl;
@useResult
$Res call({
 String name, AttachmentKind kind, String? workspacePath
});




}
/// @nodoc
class _$ChatAttachmentRefCopyWithImpl<$Res>
    implements $ChatAttachmentRefCopyWith<$Res> {
  _$ChatAttachmentRefCopyWithImpl(this._self, this._then);

  final ChatAttachmentRef _self;
  final $Res Function(ChatAttachmentRef) _then;

/// Create a copy of ChatAttachmentRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? kind = null,Object? workspacePath = freezed,}) {
  return _then(ChatAttachmentRef(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttachmentKind,workspacePath: freezed == workspacePath ? _self.workspacePath : workspacePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatAttachmentRef].
extension ChatAttachmentRefPatterns on ChatAttachmentRef {
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
