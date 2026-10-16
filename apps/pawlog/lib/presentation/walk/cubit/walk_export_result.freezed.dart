// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_export_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkExportResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkExportResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkExportResult()';
}


}

/// @nodoc
class $WalkExportResultCopyWith<$Res>  {
$WalkExportResultCopyWith(WalkExportResult _, $Res Function(WalkExportResult) __);
}


/// Adds pattern-matching-related methods to [WalkExportResult].
extension WalkExportResultPatterns on WalkExportResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WalkExportShared value)?  shared,TResult Function( WalkExportNoRoute value)?  noRoute,TResult Function( WalkExportFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WalkExportShared() when shared != null:
return shared(_that);case WalkExportNoRoute() when noRoute != null:
return noRoute(_that);case WalkExportFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WalkExportShared value)  shared,required TResult Function( WalkExportNoRoute value)  noRoute,required TResult Function( WalkExportFailed value)  failed,}){
final _that = this;
switch (_that) {
case WalkExportShared():
return shared(_that);case WalkExportNoRoute():
return noRoute(_that);case WalkExportFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WalkExportShared value)?  shared,TResult? Function( WalkExportNoRoute value)?  noRoute,TResult? Function( WalkExportFailed value)?  failed,}){
final _that = this;
switch (_that) {
case WalkExportShared() when shared != null:
return shared(_that);case WalkExportNoRoute() when noRoute != null:
return noRoute(_that);case WalkExportFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  shared,TResult Function()?  noRoute,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WalkExportShared() when shared != null:
return shared();case WalkExportNoRoute() when noRoute != null:
return noRoute();case WalkExportFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  shared,required TResult Function()  noRoute,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case WalkExportShared():
return shared();case WalkExportNoRoute():
return noRoute();case WalkExportFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  shared,TResult? Function()?  noRoute,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case WalkExportShared() when shared != null:
return shared();case WalkExportNoRoute() when noRoute != null:
return noRoute();case WalkExportFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WalkExportShared implements WalkExportResult {
  const WalkExportShared();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkExportShared);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkExportResult.shared()';
}


}




/// @nodoc


class WalkExportNoRoute implements WalkExportResult {
  const WalkExportNoRoute();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkExportNoRoute);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkExportResult.noRoute()';
}


}




/// @nodoc


class WalkExportFailed implements WalkExportResult {
  const WalkExportFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of WalkExportResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkExportFailedCopyWith<WalkExportFailed> get copyWith => _$WalkExportFailedCopyWithImpl<WalkExportFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkExportFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'WalkExportResult.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WalkExportFailedCopyWith<$Res> implements $WalkExportResultCopyWith<$Res> {
  factory $WalkExportFailedCopyWith(WalkExportFailed value, $Res Function(WalkExportFailed) _then) = _$WalkExportFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$WalkExportFailedCopyWithImpl<$Res>
    implements $WalkExportFailedCopyWith<$Res> {
  _$WalkExportFailedCopyWithImpl(this._self, this._then);

  final WalkExportFailed _self;
  final $Res Function(WalkExportFailed) _then;

/// Create a copy of WalkExportResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WalkExportFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of WalkExportResult
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
