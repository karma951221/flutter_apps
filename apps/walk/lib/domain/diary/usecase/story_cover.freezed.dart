// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_cover.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryCover {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryCover);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoryCover()';
}


}

/// @nodoc
class $StoryCoverCopyWith<$Res>  {
$StoryCoverCopyWith(StoryCover _, $Res Function(StoryCover) __);
}


/// Adds pattern-matching-related methods to [StoryCover].
extension StoryCoverPatterns on StoryCover {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CoverMedia value)?  media,TResult Function( CoverInitial value)?  initial,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CoverMedia() when media != null:
return media(_that);case CoverInitial() when initial != null:
return initial(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CoverMedia value)  media,required TResult Function( CoverInitial value)  initial,}){
final _that = this;
switch (_that) {
case CoverMedia():
return media(_that);case CoverInitial():
return initial(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CoverMedia value)?  media,TResult? Function( CoverInitial value)?  initial,}){
final _that = this;
switch (_that) {
case CoverMedia() when media != null:
return media(_that);case CoverInitial() when initial != null:
return initial(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EntryMedia media)?  media,TResult Function( String title)?  initial,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CoverMedia() when media != null:
return media(_that.media);case CoverInitial() when initial != null:
return initial(_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EntryMedia media)  media,required TResult Function( String title)  initial,}) {final _that = this;
switch (_that) {
case CoverMedia():
return media(_that.media);case CoverInitial():
return initial(_that.title);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EntryMedia media)?  media,TResult? Function( String title)?  initial,}) {final _that = this;
switch (_that) {
case CoverMedia() when media != null:
return media(_that.media);case CoverInitial() when initial != null:
return initial(_that.title);case _:
  return null;

}
}

}

/// @nodoc


class CoverMedia implements StoryCover {
  const CoverMedia(this.media);
  

 final  EntryMedia media;

/// Create a copy of StoryCover
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoverMediaCopyWith<CoverMedia> get copyWith => _$CoverMediaCopyWithImpl<CoverMedia>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoverMedia&&(identical(other.media, media) || other.media == media));
}


@override
int get hashCode => Object.hash(runtimeType,media);

@override
String toString() {
  return 'StoryCover.media(media: $media)';
}


}

/// @nodoc
abstract mixin class $CoverMediaCopyWith<$Res> implements $StoryCoverCopyWith<$Res> {
  factory $CoverMediaCopyWith(CoverMedia value, $Res Function(CoverMedia) _then) = _$CoverMediaCopyWithImpl;
@useResult
$Res call({
 EntryMedia media
});


$EntryMediaCopyWith<$Res> get media;

}
/// @nodoc
class _$CoverMediaCopyWithImpl<$Res>
    implements $CoverMediaCopyWith<$Res> {
  _$CoverMediaCopyWithImpl(this._self, this._then);

  final CoverMedia _self;
  final $Res Function(CoverMedia) _then;

/// Create a copy of StoryCover
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? media = null,}) {
  return _then(CoverMedia(
null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as EntryMedia,
  ));
}

/// Create a copy of StoryCover
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryMediaCopyWith<$Res> get media {
  
  return $EntryMediaCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}

/// @nodoc


class CoverInitial implements StoryCover {
  const CoverInitial(this.title);
  

 final  String title;

/// Create a copy of StoryCover
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoverInitialCopyWith<CoverInitial> get copyWith => _$CoverInitialCopyWithImpl<CoverInitial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoverInitial&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,title);

@override
String toString() {
  return 'StoryCover.initial(title: $title)';
}


}

/// @nodoc
abstract mixin class $CoverInitialCopyWith<$Res> implements $StoryCoverCopyWith<$Res> {
  factory $CoverInitialCopyWith(CoverInitial value, $Res Function(CoverInitial) _then) = _$CoverInitialCopyWithImpl;
@useResult
$Res call({
 String title
});




}
/// @nodoc
class _$CoverInitialCopyWithImpl<$Res>
    implements $CoverInitialCopyWith<$Res> {
  _$CoverInitialCopyWithImpl(this._self, this._then);

  final CoverInitial _self;
  final $Res Function(CoverInitial) _then;

/// Create a copy of StoryCover
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,}) {
  return _then(CoverInitial(
null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
