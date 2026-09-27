// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commute_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommuteSettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteSettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteSettingsState()';
}


}

/// @nodoc
class $CommuteSettingsStateCopyWith<$Res>  {
$CommuteSettingsStateCopyWith(CommuteSettingsState _, $Res Function(CommuteSettingsState) __);
}


/// Adds pattern-matching-related methods to [CommuteSettingsState].
extension CommuteSettingsStatePatterns on CommuteSettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommuteSettingsLoading value)?  loading,TResult Function( CommuteSettingsLoaded value)?  loaded,TResult Function( CommuteSettingsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommuteSettingsLoading() when loading != null:
return loading(_that);case CommuteSettingsLoaded() when loaded != null:
return loaded(_that);case CommuteSettingsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommuteSettingsLoading value)  loading,required TResult Function( CommuteSettingsLoaded value)  loaded,required TResult Function( CommuteSettingsFailure value)  failure,}){
final _that = this;
switch (_that) {
case CommuteSettingsLoading():
return loading(_that);case CommuteSettingsLoaded():
return loaded(_that);case CommuteSettingsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommuteSettingsLoading value)?  loading,TResult? Function( CommuteSettingsLoaded value)?  loaded,TResult? Function( CommuteSettingsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CommuteSettingsLoading() when loading != null:
return loading(_that);case CommuteSettingsLoaded() when loaded != null:
return loaded(_that);case CommuteSettingsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( CommuteSettings settings)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommuteSettingsLoading() when loading != null:
return loading();case CommuteSettingsLoaded() when loaded != null:
return loaded(_that.settings);case CommuteSettingsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( CommuteSettings settings)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CommuteSettingsLoading():
return loading();case CommuteSettingsLoaded():
return loaded(_that.settings);case CommuteSettingsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( CommuteSettings settings)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CommuteSettingsLoading() when loading != null:
return loading();case CommuteSettingsLoaded() when loaded != null:
return loaded(_that.settings);case CommuteSettingsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CommuteSettingsLoading implements CommuteSettingsState {
  const CommuteSettingsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteSettingsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteSettingsState.loading()';
}


}




/// @nodoc


class CommuteSettingsLoaded implements CommuteSettingsState {
  const CommuteSettingsLoaded(this.settings);
  

 final  CommuteSettings settings;

/// Create a copy of CommuteSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteSettingsLoadedCopyWith<CommuteSettingsLoaded> get copyWith => _$CommuteSettingsLoadedCopyWithImpl<CommuteSettingsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteSettingsLoaded&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode => Object.hash(runtimeType,settings);

@override
String toString() {
  return 'CommuteSettingsState.loaded(settings: $settings)';
}


}

/// @nodoc
abstract mixin class $CommuteSettingsLoadedCopyWith<$Res> implements $CommuteSettingsStateCopyWith<$Res> {
  factory $CommuteSettingsLoadedCopyWith(CommuteSettingsLoaded value, $Res Function(CommuteSettingsLoaded) _then) = _$CommuteSettingsLoadedCopyWithImpl;
@useResult
$Res call({
 CommuteSettings settings
});


$CommuteSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$CommuteSettingsLoadedCopyWithImpl<$Res>
    implements $CommuteSettingsLoadedCopyWith<$Res> {
  _$CommuteSettingsLoadedCopyWithImpl(this._self, this._then);

  final CommuteSettingsLoaded _self;
  final $Res Function(CommuteSettingsLoaded) _then;

/// Create a copy of CommuteSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(CommuteSettingsLoaded(
null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CommuteSettings,
  ));
}

/// Create a copy of CommuteSettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommuteSettingsCopyWith<$Res> get settings {
  
  return $CommuteSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc


class CommuteSettingsFailure implements CommuteSettingsState {
  const CommuteSettingsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CommuteSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteSettingsFailureCopyWith<CommuteSettingsFailure> get copyWith => _$CommuteSettingsFailureCopyWithImpl<CommuteSettingsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteSettingsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CommuteSettingsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CommuteSettingsFailureCopyWith<$Res> implements $CommuteSettingsStateCopyWith<$Res> {
  factory $CommuteSettingsFailureCopyWith(CommuteSettingsFailure value, $Res Function(CommuteSettingsFailure) _then) = _$CommuteSettingsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CommuteSettingsFailureCopyWithImpl<$Res>
    implements $CommuteSettingsFailureCopyWith<$Res> {
  _$CommuteSettingsFailureCopyWithImpl(this._self, this._then);

  final CommuteSettingsFailure _self;
  final $Res Function(CommuteSettingsFailure) _then;

/// Create a copy of CommuteSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CommuteSettingsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CommuteSettingsState
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
