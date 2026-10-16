// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_import_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackupImportResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupImportResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupImportResult()';
}


}

/// @nodoc
class $BackupImportResultCopyWith<$Res>  {
$BackupImportResultCopyWith(BackupImportResult _, $Res Function(BackupImportResult) __);
}


/// Adds pattern-matching-related methods to [BackupImportResult].
extension BackupImportResultPatterns on BackupImportResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BackupImported value)?  imported,TResult Function( BackupNothingNew value)?  nothingNew,TResult Function( BackupImportCancelled value)?  cancelled,TResult Function( BackupInvalid value)?  invalid,TResult Function( BackupImportFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BackupImported() when imported != null:
return imported(_that);case BackupNothingNew() when nothingNew != null:
return nothingNew(_that);case BackupImportCancelled() when cancelled != null:
return cancelled(_that);case BackupInvalid() when invalid != null:
return invalid(_that);case BackupImportFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BackupImported value)  imported,required TResult Function( BackupNothingNew value)  nothingNew,required TResult Function( BackupImportCancelled value)  cancelled,required TResult Function( BackupInvalid value)  invalid,required TResult Function( BackupImportFailed value)  failed,}){
final _that = this;
switch (_that) {
case BackupImported():
return imported(_that);case BackupNothingNew():
return nothingNew(_that);case BackupImportCancelled():
return cancelled(_that);case BackupInvalid():
return invalid(_that);case BackupImportFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BackupImported value)?  imported,TResult? Function( BackupNothingNew value)?  nothingNew,TResult? Function( BackupImportCancelled value)?  cancelled,TResult? Function( BackupInvalid value)?  invalid,TResult? Function( BackupImportFailed value)?  failed,}){
final _that = this;
switch (_that) {
case BackupImported() when imported != null:
return imported(_that);case BackupNothingNew() when nothingNew != null:
return nothingNew(_that);case BackupImportCancelled() when cancelled != null:
return cancelled(_that);case BackupInvalid() when invalid != null:
return invalid(_that);case BackupImportFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int dogs,  int walks)?  imported,TResult Function()?  nothingNew,TResult Function()?  cancelled,TResult Function()?  invalid,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BackupImported() when imported != null:
return imported(_that.dogs,_that.walks);case BackupNothingNew() when nothingNew != null:
return nothingNew();case BackupImportCancelled() when cancelled != null:
return cancelled();case BackupInvalid() when invalid != null:
return invalid();case BackupImportFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int dogs,  int walks)  imported,required TResult Function()  nothingNew,required TResult Function()  cancelled,required TResult Function()  invalid,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case BackupImported():
return imported(_that.dogs,_that.walks);case BackupNothingNew():
return nothingNew();case BackupImportCancelled():
return cancelled();case BackupInvalid():
return invalid();case BackupImportFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int dogs,  int walks)?  imported,TResult? Function()?  nothingNew,TResult? Function()?  cancelled,TResult? Function()?  invalid,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case BackupImported() when imported != null:
return imported(_that.dogs,_that.walks);case BackupNothingNew() when nothingNew != null:
return nothingNew();case BackupImportCancelled() when cancelled != null:
return cancelled();case BackupInvalid() when invalid != null:
return invalid();case BackupImportFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class BackupImported implements BackupImportResult {
  const BackupImported(this.dogs, this.walks);
  

 final  int dogs;
 final  int walks;

/// Create a copy of BackupImportResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupImportedCopyWith<BackupImported> get copyWith => _$BackupImportedCopyWithImpl<BackupImported>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupImported&&(identical(other.dogs, dogs) || other.dogs == dogs)&&(identical(other.walks, walks) || other.walks == walks));
}


@override
int get hashCode => Object.hash(runtimeType,dogs,walks);

@override
String toString() {
  return 'BackupImportResult.imported(dogs: $dogs, walks: $walks)';
}


}

/// @nodoc
abstract mixin class $BackupImportedCopyWith<$Res> implements $BackupImportResultCopyWith<$Res> {
  factory $BackupImportedCopyWith(BackupImported value, $Res Function(BackupImported) _then) = _$BackupImportedCopyWithImpl;
@useResult
$Res call({
 int dogs, int walks
});




}
/// @nodoc
class _$BackupImportedCopyWithImpl<$Res>
    implements $BackupImportedCopyWith<$Res> {
  _$BackupImportedCopyWithImpl(this._self, this._then);

  final BackupImported _self;
  final $Res Function(BackupImported) _then;

/// Create a copy of BackupImportResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dogs = null,Object? walks = null,}) {
  return _then(BackupImported(
null == dogs ? _self.dogs : dogs // ignore: cast_nullable_to_non_nullable
as int,null == walks ? _self.walks : walks // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class BackupNothingNew implements BackupImportResult {
  const BackupNothingNew();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupNothingNew);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupImportResult.nothingNew()';
}


}




/// @nodoc


class BackupImportCancelled implements BackupImportResult {
  const BackupImportCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupImportCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupImportResult.cancelled()';
}


}




/// @nodoc


class BackupInvalid implements BackupImportResult {
  const BackupInvalid();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupInvalid);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupImportResult.invalid()';
}


}




/// @nodoc


class BackupImportFailed implements BackupImportResult {
  const BackupImportFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of BackupImportResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupImportFailedCopyWith<BackupImportFailed> get copyWith => _$BackupImportFailedCopyWithImpl<BackupImportFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupImportFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'BackupImportResult.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $BackupImportFailedCopyWith<$Res> implements $BackupImportResultCopyWith<$Res> {
  factory $BackupImportFailedCopyWith(BackupImportFailed value, $Res Function(BackupImportFailed) _then) = _$BackupImportFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$BackupImportFailedCopyWithImpl<$Res>
    implements $BackupImportFailedCopyWith<$Res> {
  _$BackupImportFailedCopyWithImpl(this._self, this._then);

  final BackupImportFailed _self;
  final $Res Function(BackupImportFailed) _then;

/// Create a copy of BackupImportResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(BackupImportFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of BackupImportResult
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
