// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dog_edit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DogEditState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogEditState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DogEditState()';
}


}

/// @nodoc
class $DogEditStateCopyWith<$Res>  {
$DogEditStateCopyWith(DogEditState _, $Res Function(DogEditState) __);
}


/// Adds pattern-matching-related methods to [DogEditState].
extension DogEditStatePatterns on DogEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DogEditLoading value)?  loading,TResult Function( DogEditEditing value)?  editing,TResult Function( DogEditSaved value)?  saved,TResult Function( DogEditDeleted value)?  deleted,TResult Function( DogEditLoadFailure value)?  loadFailure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DogEditLoading() when loading != null:
return loading(_that);case DogEditEditing() when editing != null:
return editing(_that);case DogEditSaved() when saved != null:
return saved(_that);case DogEditDeleted() when deleted != null:
return deleted(_that);case DogEditLoadFailure() when loadFailure != null:
return loadFailure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DogEditLoading value)  loading,required TResult Function( DogEditEditing value)  editing,required TResult Function( DogEditSaved value)  saved,required TResult Function( DogEditDeleted value)  deleted,required TResult Function( DogEditLoadFailure value)  loadFailure,}){
final _that = this;
switch (_that) {
case DogEditLoading():
return loading(_that);case DogEditEditing():
return editing(_that);case DogEditSaved():
return saved(_that);case DogEditDeleted():
return deleted(_that);case DogEditLoadFailure():
return loadFailure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DogEditLoading value)?  loading,TResult? Function( DogEditEditing value)?  editing,TResult? Function( DogEditSaved value)?  saved,TResult? Function( DogEditDeleted value)?  deleted,TResult? Function( DogEditLoadFailure value)?  loadFailure,}){
final _that = this;
switch (_that) {
case DogEditLoading() when loading != null:
return loading(_that);case DogEditEditing() when editing != null:
return editing(_that);case DogEditSaved() when saved != null:
return saved(_that);case DogEditDeleted() when deleted != null:
return deleted(_that);case DogEditLoadFailure() when loadFailure != null:
return loadFailure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( DogForm form,  bool isSaving,  Failure? failure)?  editing,TResult Function( Dog dog)?  saved,TResult Function()?  deleted,TResult Function( Failure failure)?  loadFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DogEditLoading() when loading != null:
return loading();case DogEditEditing() when editing != null:
return editing(_that.form,_that.isSaving,_that.failure);case DogEditSaved() when saved != null:
return saved(_that.dog);case DogEditDeleted() when deleted != null:
return deleted();case DogEditLoadFailure() when loadFailure != null:
return loadFailure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( DogForm form,  bool isSaving,  Failure? failure)  editing,required TResult Function( Dog dog)  saved,required TResult Function()  deleted,required TResult Function( Failure failure)  loadFailure,}) {final _that = this;
switch (_that) {
case DogEditLoading():
return loading();case DogEditEditing():
return editing(_that.form,_that.isSaving,_that.failure);case DogEditSaved():
return saved(_that.dog);case DogEditDeleted():
return deleted();case DogEditLoadFailure():
return loadFailure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( DogForm form,  bool isSaving,  Failure? failure)?  editing,TResult? Function( Dog dog)?  saved,TResult? Function()?  deleted,TResult? Function( Failure failure)?  loadFailure,}) {final _that = this;
switch (_that) {
case DogEditLoading() when loading != null:
return loading();case DogEditEditing() when editing != null:
return editing(_that.form,_that.isSaving,_that.failure);case DogEditSaved() when saved != null:
return saved(_that.dog);case DogEditDeleted() when deleted != null:
return deleted();case DogEditLoadFailure() when loadFailure != null:
return loadFailure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DogEditLoading implements DogEditState {
  const DogEditLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogEditLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DogEditState.loading()';
}


}




/// @nodoc


class DogEditEditing implements DogEditState {
  const DogEditEditing({required this.form, this.isSaving = false, this.failure});
  

 final  DogForm form;
@JsonKey() final  bool isSaving;
 final  Failure? failure;

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DogEditEditingCopyWith<DogEditEditing> get copyWith => _$DogEditEditingCopyWithImpl<DogEditEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogEditEditing&&(identical(other.form, form) || other.form == form)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,form,isSaving,failure);

@override
String toString() {
  return 'DogEditState.editing(form: $form, isSaving: $isSaving, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DogEditEditingCopyWith<$Res> implements $DogEditStateCopyWith<$Res> {
  factory $DogEditEditingCopyWith(DogEditEditing value, $Res Function(DogEditEditing) _then) = _$DogEditEditingCopyWithImpl;
@useResult
$Res call({
 DogForm form, bool isSaving, Failure? failure
});


$DogFormCopyWith<$Res> get form;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$DogEditEditingCopyWithImpl<$Res>
    implements $DogEditEditingCopyWith<$Res> {
  _$DogEditEditingCopyWithImpl(this._self, this._then);

  final DogEditEditing _self;
  final $Res Function(DogEditEditing) _then;

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? form = null,Object? isSaving = null,Object? failure = freezed,}) {
  return _then(DogEditEditing(
form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as DogForm,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DogFormCopyWith<$Res> get form {
  
  return $DogFormCopyWith<$Res>(_self.form, (value) {
    return _then(_self.copyWith(form: value));
  });
}/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class DogEditSaved implements DogEditState {
  const DogEditSaved(this.dog);
  

 final  Dog dog;

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DogEditSavedCopyWith<DogEditSaved> get copyWith => _$DogEditSavedCopyWithImpl<DogEditSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogEditSaved&&(identical(other.dog, dog) || other.dog == dog));
}


@override
int get hashCode => Object.hash(runtimeType,dog);

@override
String toString() {
  return 'DogEditState.saved(dog: $dog)';
}


}

/// @nodoc
abstract mixin class $DogEditSavedCopyWith<$Res> implements $DogEditStateCopyWith<$Res> {
  factory $DogEditSavedCopyWith(DogEditSaved value, $Res Function(DogEditSaved) _then) = _$DogEditSavedCopyWithImpl;
@useResult
$Res call({
 Dog dog
});


$DogCopyWith<$Res> get dog;

}
/// @nodoc
class _$DogEditSavedCopyWithImpl<$Res>
    implements $DogEditSavedCopyWith<$Res> {
  _$DogEditSavedCopyWithImpl(this._self, this._then);

  final DogEditSaved _self;
  final $Res Function(DogEditSaved) _then;

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dog = null,}) {
  return _then(DogEditSaved(
null == dog ? _self.dog : dog // ignore: cast_nullable_to_non_nullable
as Dog,
  ));
}

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DogCopyWith<$Res> get dog {
  
  return $DogCopyWith<$Res>(_self.dog, (value) {
    return _then(_self.copyWith(dog: value));
  });
}
}

/// @nodoc


class DogEditDeleted implements DogEditState {
  const DogEditDeleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogEditDeleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DogEditState.deleted()';
}


}




/// @nodoc


class DogEditLoadFailure implements DogEditState {
  const DogEditLoadFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DogEditLoadFailureCopyWith<DogEditLoadFailure> get copyWith => _$DogEditLoadFailureCopyWithImpl<DogEditLoadFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DogEditLoadFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DogEditState.loadFailure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DogEditLoadFailureCopyWith<$Res> implements $DogEditStateCopyWith<$Res> {
  factory $DogEditLoadFailureCopyWith(DogEditLoadFailure value, $Res Function(DogEditLoadFailure) _then) = _$DogEditLoadFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DogEditLoadFailureCopyWithImpl<$Res>
    implements $DogEditLoadFailureCopyWith<$Res> {
  _$DogEditLoadFailureCopyWithImpl(this._self, this._then);

  final DogEditLoadFailure _self;
  final $Res Function(DogEditLoadFailure) _then;

/// Create a copy of DogEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DogEditLoadFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DogEditState
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
