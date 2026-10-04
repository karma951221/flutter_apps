// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_edit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkEditState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkEditState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkEditState()';
}


}

/// @nodoc
class $WalkEditStateCopyWith<$Res>  {
$WalkEditStateCopyWith(WalkEditState _, $Res Function(WalkEditState) __);
}


/// Adds pattern-matching-related methods to [WalkEditState].
extension WalkEditStatePatterns on WalkEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WalkEditLoading value)?  loading,TResult Function( WalkEditEditing value)?  editing,TResult Function( WalkEditSaved value)?  saved,TResult Function( WalkEditDiscarded value)?  discarded,TResult Function( WalkEditLoadFailure value)?  loadFailure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WalkEditLoading() when loading != null:
return loading(_that);case WalkEditEditing() when editing != null:
return editing(_that);case WalkEditSaved() when saved != null:
return saved(_that);case WalkEditDiscarded() when discarded != null:
return discarded(_that);case WalkEditLoadFailure() when loadFailure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WalkEditLoading value)  loading,required TResult Function( WalkEditEditing value)  editing,required TResult Function( WalkEditSaved value)  saved,required TResult Function( WalkEditDiscarded value)  discarded,required TResult Function( WalkEditLoadFailure value)  loadFailure,}){
final _that = this;
switch (_that) {
case WalkEditLoading():
return loading(_that);case WalkEditEditing():
return editing(_that);case WalkEditSaved():
return saved(_that);case WalkEditDiscarded():
return discarded(_that);case WalkEditLoadFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WalkEditLoading value)?  loading,TResult? Function( WalkEditEditing value)?  editing,TResult? Function( WalkEditSaved value)?  saved,TResult? Function( WalkEditDiscarded value)?  discarded,TResult? Function( WalkEditLoadFailure value)?  loadFailure,}){
final _that = this;
switch (_that) {
case WalkEditLoading() when loading != null:
return loading(_that);case WalkEditEditing() when editing != null:
return editing(_that);case WalkEditSaved() when saved != null:
return saved(_that);case WalkEditDiscarded() when discarded != null:
return discarded(_that);case WalkEditLoadFailure() when loadFailure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( WalkEditForm form,  bool isSaving,  Failure? failure)?  editing,TResult Function( String walkId)?  saved,TResult Function()?  discarded,TResult Function( Failure failure)?  loadFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WalkEditLoading() when loading != null:
return loading();case WalkEditEditing() when editing != null:
return editing(_that.form,_that.isSaving,_that.failure);case WalkEditSaved() when saved != null:
return saved(_that.walkId);case WalkEditDiscarded() when discarded != null:
return discarded();case WalkEditLoadFailure() when loadFailure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( WalkEditForm form,  bool isSaving,  Failure? failure)  editing,required TResult Function( String walkId)  saved,required TResult Function()  discarded,required TResult Function( Failure failure)  loadFailure,}) {final _that = this;
switch (_that) {
case WalkEditLoading():
return loading();case WalkEditEditing():
return editing(_that.form,_that.isSaving,_that.failure);case WalkEditSaved():
return saved(_that.walkId);case WalkEditDiscarded():
return discarded();case WalkEditLoadFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( WalkEditForm form,  bool isSaving,  Failure? failure)?  editing,TResult? Function( String walkId)?  saved,TResult? Function()?  discarded,TResult? Function( Failure failure)?  loadFailure,}) {final _that = this;
switch (_that) {
case WalkEditLoading() when loading != null:
return loading();case WalkEditEditing() when editing != null:
return editing(_that.form,_that.isSaving,_that.failure);case WalkEditSaved() when saved != null:
return saved(_that.walkId);case WalkEditDiscarded() when discarded != null:
return discarded();case WalkEditLoadFailure() when loadFailure != null:
return loadFailure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WalkEditLoading implements WalkEditState {
  const WalkEditLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkEditLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkEditState.loading()';
}


}




/// @nodoc


class WalkEditEditing implements WalkEditState {
  const WalkEditEditing({required this.form, this.isSaving = false, this.failure});
  

 final  WalkEditForm form;
@JsonKey() final  bool isSaving;
 final  Failure? failure;

/// Create a copy of WalkEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkEditEditingCopyWith<WalkEditEditing> get copyWith => _$WalkEditEditingCopyWithImpl<WalkEditEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkEditEditing&&(identical(other.form, form) || other.form == form)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,form,isSaving,failure);

@override
String toString() {
  return 'WalkEditState.editing(form: $form, isSaving: $isSaving, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WalkEditEditingCopyWith<$Res> implements $WalkEditStateCopyWith<$Res> {
  factory $WalkEditEditingCopyWith(WalkEditEditing value, $Res Function(WalkEditEditing) _then) = _$WalkEditEditingCopyWithImpl;
@useResult
$Res call({
 WalkEditForm form, bool isSaving, Failure? failure
});


$WalkEditFormCopyWith<$Res> get form;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$WalkEditEditingCopyWithImpl<$Res>
    implements $WalkEditEditingCopyWith<$Res> {
  _$WalkEditEditingCopyWithImpl(this._self, this._then);

  final WalkEditEditing _self;
  final $Res Function(WalkEditEditing) _then;

/// Create a copy of WalkEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? form = null,Object? isSaving = null,Object? failure = freezed,}) {
  return _then(WalkEditEditing(
form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as WalkEditForm,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of WalkEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalkEditFormCopyWith<$Res> get form {
  
  return $WalkEditFormCopyWith<$Res>(_self.form, (value) {
    return _then(_self.copyWith(form: value));
  });
}/// Create a copy of WalkEditState
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


class WalkEditSaved implements WalkEditState {
  const WalkEditSaved(this.walkId);
  

 final  String walkId;

/// Create a copy of WalkEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkEditSavedCopyWith<WalkEditSaved> get copyWith => _$WalkEditSavedCopyWithImpl<WalkEditSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkEditSaved&&(identical(other.walkId, walkId) || other.walkId == walkId));
}


@override
int get hashCode => Object.hash(runtimeType,walkId);

@override
String toString() {
  return 'WalkEditState.saved(walkId: $walkId)';
}


}

/// @nodoc
abstract mixin class $WalkEditSavedCopyWith<$Res> implements $WalkEditStateCopyWith<$Res> {
  factory $WalkEditSavedCopyWith(WalkEditSaved value, $Res Function(WalkEditSaved) _then) = _$WalkEditSavedCopyWithImpl;
@useResult
$Res call({
 String walkId
});




}
/// @nodoc
class _$WalkEditSavedCopyWithImpl<$Res>
    implements $WalkEditSavedCopyWith<$Res> {
  _$WalkEditSavedCopyWithImpl(this._self, this._then);

  final WalkEditSaved _self;
  final $Res Function(WalkEditSaved) _then;

/// Create a copy of WalkEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? walkId = null,}) {
  return _then(WalkEditSaved(
null == walkId ? _self.walkId : walkId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WalkEditDiscarded implements WalkEditState {
  const WalkEditDiscarded();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkEditDiscarded);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkEditState.discarded()';
}


}




/// @nodoc


class WalkEditLoadFailure implements WalkEditState {
  const WalkEditLoadFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of WalkEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkEditLoadFailureCopyWith<WalkEditLoadFailure> get copyWith => _$WalkEditLoadFailureCopyWithImpl<WalkEditLoadFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkEditLoadFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'WalkEditState.loadFailure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WalkEditLoadFailureCopyWith<$Res> implements $WalkEditStateCopyWith<$Res> {
  factory $WalkEditLoadFailureCopyWith(WalkEditLoadFailure value, $Res Function(WalkEditLoadFailure) _then) = _$WalkEditLoadFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$WalkEditLoadFailureCopyWithImpl<$Res>
    implements $WalkEditLoadFailureCopyWith<$Res> {
  _$WalkEditLoadFailureCopyWithImpl(this._self, this._then);

  final WalkEditLoadFailure _self;
  final $Res Function(WalkEditLoadFailure) _then;

/// Create a copy of WalkEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WalkEditLoadFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of WalkEditState
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
