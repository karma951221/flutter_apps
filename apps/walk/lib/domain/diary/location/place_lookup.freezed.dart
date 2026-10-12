// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_lookup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaceLookup {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceLookup);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceLookup()';
}


}

/// @nodoc
class $PlaceLookupCopyWith<$Res>  {
$PlaceLookupCopyWith(PlaceLookup _, $Res Function(PlaceLookup) __);
}


/// Adds pattern-matching-related methods to [PlaceLookup].
extension PlaceLookupPatterns on PlaceLookup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaceNamed value)?  named,TResult Function( PlaceNoName value)?  noName,TResult Function( PlaceOffline value)?  offline,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaceNamed() when named != null:
return named(_that);case PlaceNoName() when noName != null:
return noName(_that);case PlaceOffline() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaceNamed value)  named,required TResult Function( PlaceNoName value)  noName,required TResult Function( PlaceOffline value)  offline,}){
final _that = this;
switch (_that) {
case PlaceNamed():
return named(_that);case PlaceNoName():
return noName(_that);case PlaceOffline():
return offline(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaceNamed value)?  named,TResult? Function( PlaceNoName value)?  noName,TResult? Function( PlaceOffline value)?  offline,}){
final _that = this;
switch (_that) {
case PlaceNamed() when named != null:
return named(_that);case PlaceNoName() when noName != null:
return noName(_that);case PlaceOffline() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name)?  named,TResult Function()?  noName,TResult Function()?  offline,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaceNamed() when named != null:
return named(_that.name);case PlaceNoName() when noName != null:
return noName();case PlaceOffline() when offline != null:
return offline();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name)  named,required TResult Function()  noName,required TResult Function()  offline,}) {final _that = this;
switch (_that) {
case PlaceNamed():
return named(_that.name);case PlaceNoName():
return noName();case PlaceOffline():
return offline();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name)?  named,TResult? Function()?  noName,TResult? Function()?  offline,}) {final _that = this;
switch (_that) {
case PlaceNamed() when named != null:
return named(_that.name);case PlaceNoName() when noName != null:
return noName();case PlaceOffline() when offline != null:
return offline();case _:
  return null;

}
}

}

/// @nodoc


class PlaceNamed implements PlaceLookup {
  const PlaceNamed(this.name);
  

 final  String name;

/// Create a copy of PlaceLookup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceNamedCopyWith<PlaceNamed> get copyWith => _$PlaceNamedCopyWithImpl<PlaceNamed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNamed&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'PlaceLookup.named(name: $name)';
}


}

/// @nodoc
abstract mixin class $PlaceNamedCopyWith<$Res> implements $PlaceLookupCopyWith<$Res> {
  factory $PlaceNamedCopyWith(PlaceNamed value, $Res Function(PlaceNamed) _then) = _$PlaceNamedCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$PlaceNamedCopyWithImpl<$Res>
    implements $PlaceNamedCopyWith<$Res> {
  _$PlaceNamedCopyWithImpl(this._self, this._then);

  final PlaceNamed _self;
  final $Res Function(PlaceNamed) _then;

/// Create a copy of PlaceLookup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(PlaceNamed(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PlaceNoName implements PlaceLookup {
  const PlaceNoName();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNoName);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceLookup.noName()';
}


}




/// @nodoc


class PlaceOffline implements PlaceLookup {
  const PlaceOffline();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaceLookup.offline()';
}


}




// dart format on
