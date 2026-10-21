// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_viewer_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ViewerSource {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ViewerSource);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ViewerSource()';
}


}

/// @nodoc
class $ViewerSourceCopyWith<$Res>  {
$ViewerSourceCopyWith(ViewerSource _, $Res Function(ViewerSource) __);
}


/// Adds pattern-matching-related methods to [ViewerSource].
extension ViewerSourcePatterns on ViewerSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StoriesSource value)?  stories,TResult Function( FilterSource value)?  filter,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StoriesSource() when stories != null:
return stories(_that);case FilterSource() when filter != null:
return filter(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StoriesSource value)  stories,required TResult Function( FilterSource value)  filter,}){
final _that = this;
switch (_that) {
case StoriesSource():
return stories(_that);case FilterSource():
return filter(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StoriesSource value)?  stories,TResult? Function( FilterSource value)?  filter,}){
final _that = this;
switch (_that) {
case StoriesSource() when stories != null:
return stories(_that);case FilterSource() when filter != null:
return filter(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<String> storyIds)?  stories,TResult Function( EntryFilter filter,  String title)?  filter,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StoriesSource() when stories != null:
return stories(_that.storyIds);case FilterSource() when filter != null:
return filter(_that.filter,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<String> storyIds)  stories,required TResult Function( EntryFilter filter,  String title)  filter,}) {final _that = this;
switch (_that) {
case StoriesSource():
return stories(_that.storyIds);case FilterSource():
return filter(_that.filter,_that.title);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<String> storyIds)?  stories,TResult? Function( EntryFilter filter,  String title)?  filter,}) {final _that = this;
switch (_that) {
case StoriesSource() when stories != null:
return stories(_that.storyIds);case FilterSource() when filter != null:
return filter(_that.filter,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class StoriesSource implements ViewerSource {
  const StoriesSource(final  List<String> storyIds): _storyIds = storyIds;
  

 final  List<String> _storyIds;
 List<String> get storyIds {
  if (_storyIds is EqualUnmodifiableListView) return _storyIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_storyIds);
}


/// Create a copy of ViewerSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoriesSourceCopyWith<StoriesSource> get copyWith => _$StoriesSourceCopyWithImpl<StoriesSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoriesSource&&const DeepCollectionEquality().equals(other._storyIds, _storyIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_storyIds));

@override
String toString() {
  return 'ViewerSource.stories(storyIds: $storyIds)';
}


}

/// @nodoc
abstract mixin class $StoriesSourceCopyWith<$Res> implements $ViewerSourceCopyWith<$Res> {
  factory $StoriesSourceCopyWith(StoriesSource value, $Res Function(StoriesSource) _then) = _$StoriesSourceCopyWithImpl;
@useResult
$Res call({
 List<String> storyIds
});




}
/// @nodoc
class _$StoriesSourceCopyWithImpl<$Res>
    implements $StoriesSourceCopyWith<$Res> {
  _$StoriesSourceCopyWithImpl(this._self, this._then);

  final StoriesSource _self;
  final $Res Function(StoriesSource) _then;

/// Create a copy of ViewerSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? storyIds = null,}) {
  return _then(StoriesSource(
null == storyIds ? _self._storyIds : storyIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class FilterSource implements ViewerSource {
  const FilterSource(this.filter, this.title);
  

 final  EntryFilter filter;
 final  String title;

/// Create a copy of ViewerSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterSourceCopyWith<FilterSource> get copyWith => _$FilterSourceCopyWithImpl<FilterSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilterSource&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,filter,title);

@override
String toString() {
  return 'ViewerSource.filter(filter: $filter, title: $title)';
}


}

/// @nodoc
abstract mixin class $FilterSourceCopyWith<$Res> implements $ViewerSourceCopyWith<$Res> {
  factory $FilterSourceCopyWith(FilterSource value, $Res Function(FilterSource) _then) = _$FilterSourceCopyWithImpl;
@useResult
$Res call({
 EntryFilter filter, String title
});


$EntryFilterCopyWith<$Res> get filter;

}
/// @nodoc
class _$FilterSourceCopyWithImpl<$Res>
    implements $FilterSourceCopyWith<$Res> {
  _$FilterSourceCopyWithImpl(this._self, this._then);

  final FilterSource _self;
  final $Res Function(FilterSource) _then;

/// Create a copy of ViewerSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filter = null,Object? title = null,}) {
  return _then(FilterSource(
null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as EntryFilter,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ViewerSource
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryFilterCopyWith<$Res> get filter {
  
  return $EntryFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}

// dart format on
