// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileState {

 Profile get profile; String? get photoPath;
/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileStateCopyWith<ProfileState> get copyWith => _$ProfileStateCopyWithImpl<ProfileState>(this as ProfileState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileState&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath));
}


@override
int get hashCode => Object.hash(runtimeType,profile,photoPath);

@override
String toString() {
  return 'ProfileState(profile: $profile, photoPath: $photoPath)';
}


}

/// @nodoc
abstract mixin class $ProfileStateCopyWith<$Res>  {
  factory $ProfileStateCopyWith(ProfileState value, $Res Function(ProfileState) _then) = _$ProfileStateCopyWithImpl;
@useResult
$Res call({
 Profile profile, String? photoPath
});




}
/// @nodoc
class _$ProfileStateCopyWithImpl<$Res>
    implements $ProfileStateCopyWith<$Res> {
  _$ProfileStateCopyWithImpl(this._self, this._then);

  final ProfileState _self;
  final $Res Function(ProfileState) _then;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profile = null,Object? photoPath = freezed,}) {
  return _then(ProfileState(
profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as Profile,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileState].
extension ProfileStatePatterns on ProfileState {
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
mixin _$PhotoEdit {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoEdit);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PhotoEdit()';
}


}

/// @nodoc
class $PhotoEditCopyWith<$Res>  {
$PhotoEditCopyWith(PhotoEdit _, $Res Function(PhotoEdit) __);
}


/// Adds pattern-matching-related methods to [PhotoEdit].
extension PhotoEditPatterns on PhotoEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PhotoKeep value)?  keep,TResult Function( PhotoReplace value)?  replace,TResult Function( PhotoRemove value)?  remove,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PhotoKeep() when keep != null:
return keep(_that);case PhotoReplace() when replace != null:
return replace(_that);case PhotoRemove() when remove != null:
return remove(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PhotoKeep value)  keep,required TResult Function( PhotoReplace value)  replace,required TResult Function( PhotoRemove value)  remove,}){
final _that = this;
switch (_that) {
case PhotoKeep():
return keep(_that);case PhotoReplace():
return replace(_that);case PhotoRemove():
return remove(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PhotoKeep value)?  keep,TResult? Function( PhotoReplace value)?  replace,TResult? Function( PhotoRemove value)?  remove,}){
final _that = this;
switch (_that) {
case PhotoKeep() when keep != null:
return keep(_that);case PhotoReplace() when replace != null:
return replace(_that);case PhotoRemove() when remove != null:
return remove(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  keep,TResult Function( String source)?  replace,TResult Function()?  remove,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PhotoKeep() when keep != null:
return keep();case PhotoReplace() when replace != null:
return replace(_that.source);case PhotoRemove() when remove != null:
return remove();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  keep,required TResult Function( String source)  replace,required TResult Function()  remove,}) {final _that = this;
switch (_that) {
case PhotoKeep():
return keep();case PhotoReplace():
return replace(_that.source);case PhotoRemove():
return remove();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  keep,TResult? Function( String source)?  replace,TResult? Function()?  remove,}) {final _that = this;
switch (_that) {
case PhotoKeep() when keep != null:
return keep();case PhotoReplace() when replace != null:
return replace(_that.source);case PhotoRemove() when remove != null:
return remove();case _:
  return null;

}
}

}

/// @nodoc


class PhotoKeep implements PhotoEdit {
  const PhotoKeep();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoKeep);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PhotoEdit.keep()';
}


}




/// @nodoc


class PhotoReplace implements PhotoEdit {
  const PhotoReplace(this.source);
  

 final  String source;

/// Create a copy of PhotoEdit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoReplaceCopyWith<PhotoReplace> get copyWith => _$PhotoReplaceCopyWithImpl<PhotoReplace>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoReplace&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,source);

@override
String toString() {
  return 'PhotoEdit.replace(source: $source)';
}


}

/// @nodoc
abstract mixin class $PhotoReplaceCopyWith<$Res> implements $PhotoEditCopyWith<$Res> {
  factory $PhotoReplaceCopyWith(PhotoReplace value, $Res Function(PhotoReplace) _then) = _$PhotoReplaceCopyWithImpl;
@useResult
$Res call({
 String source
});




}
/// @nodoc
class _$PhotoReplaceCopyWithImpl<$Res>
    implements $PhotoReplaceCopyWith<$Res> {
  _$PhotoReplaceCopyWithImpl(this._self, this._then);

  final PhotoReplace _self;
  final $Res Function(PhotoReplace) _then;

/// Create a copy of PhotoEdit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,}) {
  return _then(PhotoReplace(
null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PhotoRemove implements PhotoEdit {
  const PhotoRemove();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoRemove);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PhotoEdit.remove()';
}


}




// dart format on
