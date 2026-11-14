// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'write_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WritePlan {

 String get path; String get name;
/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WritePlanCopyWith<WritePlan> get copyWith => _$WritePlanCopyWithImpl<WritePlan>(this as WritePlan, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WritePlan&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,path,name);



}

/// @nodoc
abstract mixin class $WritePlanCopyWith<$Res>  {
  factory $WritePlanCopyWith(WritePlan value, $Res Function(WritePlan) _then) = _$WritePlanCopyWithImpl;
@useResult
$Res call({
 String path, String name
});




}
/// @nodoc
class _$WritePlanCopyWithImpl<$Res>
    implements $WritePlanCopyWith<$Res> {
  _$WritePlanCopyWithImpl(this._self, this._then);

  final WritePlan _self;
  final $Res Function(WritePlan) _then;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WritePlan].
extension WritePlanPatterns on WritePlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WriteCreate value)?  create,TResult Function( WriteOverwrite value)?  overwrite,TResult Function( WriteEdit value)?  edit,TResult Function( WriteDelete value)?  delete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WriteCreate() when create != null:
return create(_that);case WriteOverwrite() when overwrite != null:
return overwrite(_that);case WriteEdit() when edit != null:
return edit(_that);case WriteDelete() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WriteCreate value)  create,required TResult Function( WriteOverwrite value)  overwrite,required TResult Function( WriteEdit value)  edit,required TResult Function( WriteDelete value)  delete,}){
final _that = this;
switch (_that) {
case WriteCreate():
return create(_that);case WriteOverwrite():
return overwrite(_that);case WriteEdit():
return edit(_that);case WriteDelete():
return delete(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WriteCreate value)?  create,TResult? Function( WriteOverwrite value)?  overwrite,TResult? Function( WriteEdit value)?  edit,TResult? Function( WriteDelete value)?  delete,}){
final _that = this;
switch (_that) {
case WriteCreate() when create != null:
return create(_that);case WriteOverwrite() when overwrite != null:
return overwrite(_that);case WriteEdit() when edit != null:
return edit(_that);case WriteDelete() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String path,  String name,  String content)?  create,TResult Function( String path,  String name,  String content,  String previous)?  overwrite,TResult Function( String path,  String name,  String oldText,  String newText,  String previous,  String content)?  edit,TResult Function( String path,  String name,  String previous,  int sizeBytes)?  delete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WriteCreate() when create != null:
return create(_that.path,_that.name,_that.content);case WriteOverwrite() when overwrite != null:
return overwrite(_that.path,_that.name,_that.content,_that.previous);case WriteEdit() when edit != null:
return edit(_that.path,_that.name,_that.oldText,_that.newText,_that.previous,_that.content);case WriteDelete() when delete != null:
return delete(_that.path,_that.name,_that.previous,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String path,  String name,  String content)  create,required TResult Function( String path,  String name,  String content,  String previous)  overwrite,required TResult Function( String path,  String name,  String oldText,  String newText,  String previous,  String content)  edit,required TResult Function( String path,  String name,  String previous,  int sizeBytes)  delete,}) {final _that = this;
switch (_that) {
case WriteCreate():
return create(_that.path,_that.name,_that.content);case WriteOverwrite():
return overwrite(_that.path,_that.name,_that.content,_that.previous);case WriteEdit():
return edit(_that.path,_that.name,_that.oldText,_that.newText,_that.previous,_that.content);case WriteDelete():
return delete(_that.path,_that.name,_that.previous,_that.sizeBytes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String path,  String name,  String content)?  create,TResult? Function( String path,  String name,  String content,  String previous)?  overwrite,TResult? Function( String path,  String name,  String oldText,  String newText,  String previous,  String content)?  edit,TResult? Function( String path,  String name,  String previous,  int sizeBytes)?  delete,}) {final _that = this;
switch (_that) {
case WriteCreate() when create != null:
return create(_that.path,_that.name,_that.content);case WriteOverwrite() when overwrite != null:
return overwrite(_that.path,_that.name,_that.content,_that.previous);case WriteEdit() when edit != null:
return edit(_that.path,_that.name,_that.oldText,_that.newText,_that.previous,_that.content);case WriteDelete() when delete != null:
return delete(_that.path,_that.name,_that.previous,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc


class WriteCreate extends WritePlan {
  const WriteCreate({required this.path, required this.name, required this.content}): super._();
  

@override final  String path;
@override final  String name;
 final  String content;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriteCreateCopyWith<WriteCreate> get copyWith => _$WriteCreateCopyWithImpl<WriteCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriteCreate&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,content);



}

/// @nodoc
abstract mixin class $WriteCreateCopyWith<$Res> implements $WritePlanCopyWith<$Res> {
  factory $WriteCreateCopyWith(WriteCreate value, $Res Function(WriteCreate) _then) = _$WriteCreateCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, String content
});




}
/// @nodoc
class _$WriteCreateCopyWithImpl<$Res>
    implements $WriteCreateCopyWith<$Res> {
  _$WriteCreateCopyWithImpl(this._self, this._then);

  final WriteCreate _self;
  final $Res Function(WriteCreate) _then;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? content = null,}) {
  return _then(WriteCreate(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WriteOverwrite extends WritePlan {
  const WriteOverwrite({required this.path, required this.name, required this.content, required this.previous}): super._();
  

@override final  String path;
@override final  String name;
 final  String content;
 final  String previous;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriteOverwriteCopyWith<WriteOverwrite> get copyWith => _$WriteOverwriteCopyWithImpl<WriteOverwrite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriteOverwrite&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.previous, previous) || other.previous == previous));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,content,previous);



}

/// @nodoc
abstract mixin class $WriteOverwriteCopyWith<$Res> implements $WritePlanCopyWith<$Res> {
  factory $WriteOverwriteCopyWith(WriteOverwrite value, $Res Function(WriteOverwrite) _then) = _$WriteOverwriteCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, String content, String previous
});




}
/// @nodoc
class _$WriteOverwriteCopyWithImpl<$Res>
    implements $WriteOverwriteCopyWith<$Res> {
  _$WriteOverwriteCopyWithImpl(this._self, this._then);

  final WriteOverwrite _self;
  final $Res Function(WriteOverwrite) _then;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? content = null,Object? previous = null,}) {
  return _then(WriteOverwrite(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,previous: null == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WriteEdit extends WritePlan {
  const WriteEdit({required this.path, required this.name, required this.oldText, required this.newText, required this.previous, required this.content}): super._();
  

@override final  String path;
@override final  String name;
 final  String oldText;
 final  String newText;
 final  String previous;
 final  String content;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriteEditCopyWith<WriteEdit> get copyWith => _$WriteEditCopyWithImpl<WriteEdit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriteEdit&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.oldText, oldText) || other.oldText == oldText)&&(identical(other.newText, newText) || other.newText == newText)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,oldText,newText,previous,content);



}

/// @nodoc
abstract mixin class $WriteEditCopyWith<$Res> implements $WritePlanCopyWith<$Res> {
  factory $WriteEditCopyWith(WriteEdit value, $Res Function(WriteEdit) _then) = _$WriteEditCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, String oldText, String newText, String previous, String content
});




}
/// @nodoc
class _$WriteEditCopyWithImpl<$Res>
    implements $WriteEditCopyWith<$Res> {
  _$WriteEditCopyWithImpl(this._self, this._then);

  final WriteEdit _self;
  final $Res Function(WriteEdit) _then;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? oldText = null,Object? newText = null,Object? previous = null,Object? content = null,}) {
  return _then(WriteEdit(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,oldText: null == oldText ? _self.oldText : oldText // ignore: cast_nullable_to_non_nullable
as String,newText: null == newText ? _self.newText : newText // ignore: cast_nullable_to_non_nullable
as String,previous: null == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WriteDelete extends WritePlan {
  const WriteDelete({required this.path, required this.name, required this.previous, required this.sizeBytes}): super._();
  

@override final  String path;
@override final  String name;
 final  String previous;
 final  int sizeBytes;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriteDeleteCopyWith<WriteDelete> get copyWith => _$WriteDeleteCopyWithImpl<WriteDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriteDelete&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,previous,sizeBytes);



}

/// @nodoc
abstract mixin class $WriteDeleteCopyWith<$Res> implements $WritePlanCopyWith<$Res> {
  factory $WriteDeleteCopyWith(WriteDelete value, $Res Function(WriteDelete) _then) = _$WriteDeleteCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, String previous, int sizeBytes
});




}
/// @nodoc
class _$WriteDeleteCopyWithImpl<$Res>
    implements $WriteDeleteCopyWith<$Res> {
  _$WriteDeleteCopyWithImpl(this._self, this._then);

  final WriteDelete _self;
  final $Res Function(WriteDelete) _then;

/// Create a copy of WritePlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? previous = null,Object? sizeBytes = null,}) {
  return _then(WriteDelete(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,previous: null == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
