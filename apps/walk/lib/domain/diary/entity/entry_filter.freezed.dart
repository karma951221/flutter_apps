// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entry_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EntryFilter {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryFilter);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EntryFilter()';
}


}

/// @nodoc
class $EntryFilterCopyWith<$Res>  {
$EntryFilterCopyWith(EntryFilter _, $Res Function(EntryFilter) __);
}


/// Adds pattern-matching-related methods to [EntryFilter].
extension EntryFilterPatterns on EntryFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AllEntries value)?  all,TResult Function( StoryEntries value)?  story,TResult Function( TagEntries value)?  tag,TResult Function( PlaceEntries value)?  place,TResult Function( BodyEntries value)?  body,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AllEntries() when all != null:
return all(_that);case StoryEntries() when story != null:
return story(_that);case TagEntries() when tag != null:
return tag(_that);case PlaceEntries() when place != null:
return place(_that);case BodyEntries() when body != null:
return body(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AllEntries value)  all,required TResult Function( StoryEntries value)  story,required TResult Function( TagEntries value)  tag,required TResult Function( PlaceEntries value)  place,required TResult Function( BodyEntries value)  body,}){
final _that = this;
switch (_that) {
case AllEntries():
return all(_that);case StoryEntries():
return story(_that);case TagEntries():
return tag(_that);case PlaceEntries():
return place(_that);case BodyEntries():
return body(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AllEntries value)?  all,TResult? Function( StoryEntries value)?  story,TResult? Function( TagEntries value)?  tag,TResult? Function( PlaceEntries value)?  place,TResult? Function( BodyEntries value)?  body,}){
final _that = this;
switch (_that) {
case AllEntries() when all != null:
return all(_that);case StoryEntries() when story != null:
return story(_that);case TagEntries() when tag != null:
return tag(_that);case PlaceEntries() when place != null:
return place(_that);case BodyEntries() when body != null:
return body(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  all,TResult Function( String storyId)?  story,TResult Function( String name)?  tag,TResult Function( String name)?  place,TResult Function( String query)?  body,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AllEntries() when all != null:
return all();case StoryEntries() when story != null:
return story(_that.storyId);case TagEntries() when tag != null:
return tag(_that.name);case PlaceEntries() when place != null:
return place(_that.name);case BodyEntries() when body != null:
return body(_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  all,required TResult Function( String storyId)  story,required TResult Function( String name)  tag,required TResult Function( String name)  place,required TResult Function( String query)  body,}) {final _that = this;
switch (_that) {
case AllEntries():
return all();case StoryEntries():
return story(_that.storyId);case TagEntries():
return tag(_that.name);case PlaceEntries():
return place(_that.name);case BodyEntries():
return body(_that.query);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  all,TResult? Function( String storyId)?  story,TResult? Function( String name)?  tag,TResult? Function( String name)?  place,TResult? Function( String query)?  body,}) {final _that = this;
switch (_that) {
case AllEntries() when all != null:
return all();case StoryEntries() when story != null:
return story(_that.storyId);case TagEntries() when tag != null:
return tag(_that.name);case PlaceEntries() when place != null:
return place(_that.name);case BodyEntries() when body != null:
return body(_that.query);case _:
  return null;

}
}

}

/// @nodoc


class AllEntries implements EntryFilter {
  const AllEntries();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllEntries);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EntryFilter.all()';
}


}




/// @nodoc


class StoryEntries implements EntryFilter {
  const StoryEntries(this.storyId);
  

 final  String storyId;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryEntriesCopyWith<StoryEntries> get copyWith => _$StoryEntriesCopyWithImpl<StoryEntries>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryEntries&&(identical(other.storyId, storyId) || other.storyId == storyId));
}


@override
int get hashCode => Object.hash(runtimeType,storyId);

@override
String toString() {
  return 'EntryFilter.story(storyId: $storyId)';
}


}

/// @nodoc
abstract mixin class $StoryEntriesCopyWith<$Res> implements $EntryFilterCopyWith<$Res> {
  factory $StoryEntriesCopyWith(StoryEntries value, $Res Function(StoryEntries) _then) = _$StoryEntriesCopyWithImpl;
@useResult
$Res call({
 String storyId
});




}
/// @nodoc
class _$StoryEntriesCopyWithImpl<$Res>
    implements $StoryEntriesCopyWith<$Res> {
  _$StoryEntriesCopyWithImpl(this._self, this._then);

  final StoryEntries _self;
  final $Res Function(StoryEntries) _then;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? storyId = null,}) {
  return _then(StoryEntries(
null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TagEntries implements EntryFilter {
  const TagEntries(this.name);
  

 final  String name;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagEntriesCopyWith<TagEntries> get copyWith => _$TagEntriesCopyWithImpl<TagEntries>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagEntries&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'EntryFilter.tag(name: $name)';
}


}

/// @nodoc
abstract mixin class $TagEntriesCopyWith<$Res> implements $EntryFilterCopyWith<$Res> {
  factory $TagEntriesCopyWith(TagEntries value, $Res Function(TagEntries) _then) = _$TagEntriesCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$TagEntriesCopyWithImpl<$Res>
    implements $TagEntriesCopyWith<$Res> {
  _$TagEntriesCopyWithImpl(this._self, this._then);

  final TagEntries _self;
  final $Res Function(TagEntries) _then;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(TagEntries(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PlaceEntries implements EntryFilter {
  const PlaceEntries(this.name);
  

 final  String name;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceEntriesCopyWith<PlaceEntries> get copyWith => _$PlaceEntriesCopyWithImpl<PlaceEntries>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceEntries&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'EntryFilter.place(name: $name)';
}


}

/// @nodoc
abstract mixin class $PlaceEntriesCopyWith<$Res> implements $EntryFilterCopyWith<$Res> {
  factory $PlaceEntriesCopyWith(PlaceEntries value, $Res Function(PlaceEntries) _then) = _$PlaceEntriesCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$PlaceEntriesCopyWithImpl<$Res>
    implements $PlaceEntriesCopyWith<$Res> {
  _$PlaceEntriesCopyWithImpl(this._self, this._then);

  final PlaceEntries _self;
  final $Res Function(PlaceEntries) _then;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(PlaceEntries(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BodyEntries implements EntryFilter {
  const BodyEntries(this.query);
  

 final  String query;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BodyEntriesCopyWith<BodyEntries> get copyWith => _$BodyEntriesCopyWithImpl<BodyEntries>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BodyEntries&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'EntryFilter.body(query: $query)';
}


}

/// @nodoc
abstract mixin class $BodyEntriesCopyWith<$Res> implements $EntryFilterCopyWith<$Res> {
  factory $BodyEntriesCopyWith(BodyEntries value, $Res Function(BodyEntries) _then) = _$BodyEntriesCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$BodyEntriesCopyWithImpl<$Res>
    implements $BodyEntriesCopyWith<$Res> {
  _$BodyEntriesCopyWithImpl(this._self, this._then);

  final BodyEntries _self;
  final $Res Function(BodyEntries) _then;

/// Create a copy of EntryFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(BodyEntries(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
