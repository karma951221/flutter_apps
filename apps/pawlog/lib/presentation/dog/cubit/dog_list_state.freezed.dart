// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dog_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DogListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DogListState()';
}


}

/// @nodoc
class $DogListStateCopyWith<$Res>  {
$DogListStateCopyWith(DogListState _, $Res Function(DogListState) __);
}


/// Adds pattern-matching-related methods to [DogListState].
extension DogListStatePatterns on DogListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DogListLoading value)?  loading,TResult Function( DogListLoaded value)?  loaded,TResult Function( DogListFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DogListLoading() when loading != null:
return loading(_that);case DogListLoaded() when loaded != null:
return loaded(_that);case DogListFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DogListLoading value)  loading,required TResult Function( DogListLoaded value)  loaded,required TResult Function( DogListFailure value)  failure,}){
final _that = this;
switch (_that) {
case DogListLoading():
return loading(_that);case DogListLoaded():
return loaded(_that);case DogListFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DogListLoading value)?  loading,TResult? Function( DogListLoaded value)?  loaded,TResult? Function( DogListFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DogListLoading() when loading != null:
return loading(_that);case DogListLoaded() when loaded != null:
return loaded(_that);case DogListFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Dog> dogs)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DogListLoading() when loading != null:
return loading();case DogListLoaded() when loaded != null:
return loaded(_that.dogs);case DogListFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Dog> dogs)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case DogListLoading():
return loading();case DogListLoaded():
return loaded(_that.dogs);case DogListFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Dog> dogs)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case DogListLoading() when loading != null:
return loading();case DogListLoaded() when loaded != null:
return loaded(_that.dogs);case DogListFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DogListLoading implements DogListState {
  const DogListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DogListState.loading()';
}


}




/// @nodoc


class DogListLoaded implements DogListState {
  const DogListLoaded(final  List<Dog> dogs): _dogs = dogs;
  

 final  List<Dog> _dogs;
 List<Dog> get dogs {
  if (_dogs is EqualUnmodifiableListView) return _dogs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dogs);
}


/// Create a copy of DogListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DogListLoadedCopyWith<DogListLoaded> get copyWith => _$DogListLoadedCopyWithImpl<DogListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogListLoaded&&const DeepCollectionEquality().equals(other._dogs, _dogs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_dogs));

@override
String toString() {
  return 'DogListState.loaded(dogs: $dogs)';
}


}

/// @nodoc
abstract mixin class $DogListLoadedCopyWith<$Res> implements $DogListStateCopyWith<$Res> {
  factory $DogListLoadedCopyWith(DogListLoaded value, $Res Function(DogListLoaded) _then) = _$DogListLoadedCopyWithImpl;
@useResult
$Res call({
 List<Dog> dogs
});




}
/// @nodoc
class _$DogListLoadedCopyWithImpl<$Res>
    implements $DogListLoadedCopyWith<$Res> {
  _$DogListLoadedCopyWithImpl(this._self, this._then);

  final DogListLoaded _self;
  final $Res Function(DogListLoaded) _then;

/// Create a copy of DogListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dogs = null,}) {
  return _then(DogListLoaded(
null == dogs ? _self._dogs : dogs // ignore: cast_nullable_to_non_nullable
as List<Dog>,
  ));
}


}

/// @nodoc


class DogListFailure implements DogListState {
  const DogListFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DogListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DogListFailureCopyWith<DogListFailure> get copyWith => _$DogListFailureCopyWithImpl<DogListFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogListFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DogListState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DogListFailureCopyWith<$Res> implements $DogListStateCopyWith<$Res> {
  factory $DogListFailureCopyWith(DogListFailure value, $Res Function(DogListFailure) _then) = _$DogListFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DogListFailureCopyWithImpl<$Res>
    implements $DogListFailureCopyWith<$Res> {
  _$DogListFailureCopyWithImpl(this._self, this._then);

  final DogListFailure _self;
  final $Res Function(DogListFailure) _then;

/// Create a copy of DogListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DogListFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DogListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
