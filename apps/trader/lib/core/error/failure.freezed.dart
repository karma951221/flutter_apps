// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {

 String? get message; FailureCode? get failureCode;
/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailureCopyWith<Failure> get copyWith => _$FailureCopyWithImpl<Failure>(this as Failure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure&&(identical(other.message, message) || other.message == message)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,failureCode);

@override
String toString() {
  return 'Failure(message: $message, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $FailureCopyWith<$Res>  {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) _then) = _$FailureCopyWithImpl;
@useResult
$Res call({
 String? message, FailureCode? failureCode
});




}
/// @nodoc
class _$FailureCopyWithImpl<$Res>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._self, this._then);

  final Failure _self;
  final $Res Function(Failure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = freezed,Object? failureCode = freezed,}) {
  return _then(_self.copyWith(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}

}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkFailure value)?  network,TResult Function( AuthFailure value)?  auth,TResult Function( ForbiddenFailure value)?  forbidden,TResult Function( NotFoundFailure value)?  notFound,TResult Function( ValidationFailure value)?  validation,TResult Function( ServerFailure value)?  server,TResult Function( UnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case AuthFailure() when auth != null:
return auth(_that);case ForbiddenFailure() when forbidden != null:
return forbidden(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case ValidationFailure() when validation != null:
return validation(_that);case ServerFailure() when server != null:
return server(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkFailure value)  network,required TResult Function( AuthFailure value)  auth,required TResult Function( ForbiddenFailure value)  forbidden,required TResult Function( NotFoundFailure value)  notFound,required TResult Function( ValidationFailure value)  validation,required TResult Function( ServerFailure value)  server,required TResult Function( UnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure():
return network(_that);case AuthFailure():
return auth(_that);case ForbiddenFailure():
return forbidden(_that);case NotFoundFailure():
return notFound(_that);case ValidationFailure():
return validation(_that);case ServerFailure():
return server(_that);case UnknownFailure():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkFailure value)?  network,TResult? Function( AuthFailure value)?  auth,TResult? Function( ForbiddenFailure value)?  forbidden,TResult? Function( NotFoundFailure value)?  notFound,TResult? Function( ValidationFailure value)?  validation,TResult? Function( ServerFailure value)?  server,TResult? Function( UnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case AuthFailure() when auth != null:
return auth(_that);case ForbiddenFailure() when forbidden != null:
return forbidden(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case ValidationFailure() when validation != null:
return validation(_that);case ServerFailure() when server != null:
return server(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? message,  FailureCode? failureCode)?  network,TResult Function( String? message,  String? code,  FailureCode? failureCode)?  auth,TResult Function( String? message,  FailureCode? failureCode)?  forbidden,TResult Function( String? message,  FailureCode? failureCode)?  notFound,TResult Function( String? message,  String? field,  FailureCode? failureCode)?  validation,TResult Function( String? message,  String? code,  FailureCode? failureCode)?  server,TResult Function( String? message,  FailureCode? failureCode)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that.message,_that.failureCode);case AuthFailure() when auth != null:
return auth(_that.message,_that.code,_that.failureCode);case ForbiddenFailure() when forbidden != null:
return forbidden(_that.message,_that.failureCode);case NotFoundFailure() when notFound != null:
return notFound(_that.message,_that.failureCode);case ValidationFailure() when validation != null:
return validation(_that.message,_that.field,_that.failureCode);case ServerFailure() when server != null:
return server(_that.message,_that.code,_that.failureCode);case UnknownFailure() when unknown != null:
return unknown(_that.message,_that.failureCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? message,  FailureCode? failureCode)  network,required TResult Function( String? message,  String? code,  FailureCode? failureCode)  auth,required TResult Function( String? message,  FailureCode? failureCode)  forbidden,required TResult Function( String? message,  FailureCode? failureCode)  notFound,required TResult Function( String? message,  String? field,  FailureCode? failureCode)  validation,required TResult Function( String? message,  String? code,  FailureCode? failureCode)  server,required TResult Function( String? message,  FailureCode? failureCode)  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure():
return network(_that.message,_that.failureCode);case AuthFailure():
return auth(_that.message,_that.code,_that.failureCode);case ForbiddenFailure():
return forbidden(_that.message,_that.failureCode);case NotFoundFailure():
return notFound(_that.message,_that.failureCode);case ValidationFailure():
return validation(_that.message,_that.field,_that.failureCode);case ServerFailure():
return server(_that.message,_that.code,_that.failureCode);case UnknownFailure():
return unknown(_that.message,_that.failureCode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? message,  FailureCode? failureCode)?  network,TResult? Function( String? message,  String? code,  FailureCode? failureCode)?  auth,TResult? Function( String? message,  FailureCode? failureCode)?  forbidden,TResult? Function( String? message,  FailureCode? failureCode)?  notFound,TResult? Function( String? message,  String? field,  FailureCode? failureCode)?  validation,TResult? Function( String? message,  String? code,  FailureCode? failureCode)?  server,TResult? Function( String? message,  FailureCode? failureCode)?  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that.message,_that.failureCode);case AuthFailure() when auth != null:
return auth(_that.message,_that.code,_that.failureCode);case ForbiddenFailure() when forbidden != null:
return forbidden(_that.message,_that.failureCode);case NotFoundFailure() when notFound != null:
return notFound(_that.message,_that.failureCode);case ValidationFailure() when validation != null:
return validation(_that.message,_that.field,_that.failureCode);case ServerFailure() when server != null:
return server(_that.message,_that.code,_that.failureCode);case UnknownFailure() when unknown != null:
return unknown(_that.message,_that.failureCode);case _:
  return null;

}
}

}

/// @nodoc


class NetworkFailure implements Failure {
  const NetworkFailure({this.message, this.failureCode});
  

@override final  String? message;
@override final  FailureCode? failureCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkFailureCopyWith<NetworkFailure> get copyWith => _$NetworkFailureCopyWithImpl<NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,failureCode);

@override
String toString() {
  return 'Failure.network(message: $message, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $NetworkFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NetworkFailureCopyWith(NetworkFailure value, $Res Function(NetworkFailure) _then) = _$NetworkFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, FailureCode? failureCode
});




}
/// @nodoc
class _$NetworkFailureCopyWithImpl<$Res>
    implements $NetworkFailureCopyWith<$Res> {
  _$NetworkFailureCopyWithImpl(this._self, this._then);

  final NetworkFailure _self;
  final $Res Function(NetworkFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? failureCode = freezed,}) {
  return _then(NetworkFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}


}

/// @nodoc


class AuthFailure implements Failure {
  const AuthFailure({this.message, this.code, this.failureCode});
  

@override final  String? message;
 final  String? code;
@override final  FailureCode? failureCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthFailureCopyWith<AuthFailure> get copyWith => _$AuthFailureCopyWithImpl<AuthFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.code, code) || other.code == code)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,code,failureCode);

@override
String toString() {
  return 'Failure.auth(message: $message, code: $code, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $AuthFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $AuthFailureCopyWith(AuthFailure value, $Res Function(AuthFailure) _then) = _$AuthFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, String? code, FailureCode? failureCode
});




}
/// @nodoc
class _$AuthFailureCopyWithImpl<$Res>
    implements $AuthFailureCopyWith<$Res> {
  _$AuthFailureCopyWithImpl(this._self, this._then);

  final AuthFailure _self;
  final $Res Function(AuthFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? code = freezed,Object? failureCode = freezed,}) {
  return _then(AuthFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}


}

/// @nodoc


class ForbiddenFailure implements Failure {
  const ForbiddenFailure({this.message, this.failureCode});
  

@override final  String? message;
@override final  FailureCode? failureCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForbiddenFailureCopyWith<ForbiddenFailure> get copyWith => _$ForbiddenFailureCopyWithImpl<ForbiddenFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForbiddenFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,failureCode);

@override
String toString() {
  return 'Failure.forbidden(message: $message, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $ForbiddenFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ForbiddenFailureCopyWith(ForbiddenFailure value, $Res Function(ForbiddenFailure) _then) = _$ForbiddenFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, FailureCode? failureCode
});




}
/// @nodoc
class _$ForbiddenFailureCopyWithImpl<$Res>
    implements $ForbiddenFailureCopyWith<$Res> {
  _$ForbiddenFailureCopyWithImpl(this._self, this._then);

  final ForbiddenFailure _self;
  final $Res Function(ForbiddenFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? failureCode = freezed,}) {
  return _then(ForbiddenFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}


}

/// @nodoc


class NotFoundFailure implements Failure {
  const NotFoundFailure({this.message, this.failureCode});
  

@override final  String? message;
@override final  FailureCode? failureCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotFoundFailureCopyWith<NotFoundFailure> get copyWith => _$NotFoundFailureCopyWithImpl<NotFoundFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,failureCode);

@override
String toString() {
  return 'Failure.notFound(message: $message, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $NotFoundFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NotFoundFailureCopyWith(NotFoundFailure value, $Res Function(NotFoundFailure) _then) = _$NotFoundFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, FailureCode? failureCode
});




}
/// @nodoc
class _$NotFoundFailureCopyWithImpl<$Res>
    implements $NotFoundFailureCopyWith<$Res> {
  _$NotFoundFailureCopyWithImpl(this._self, this._then);

  final NotFoundFailure _self;
  final $Res Function(NotFoundFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? failureCode = freezed,}) {
  return _then(NotFoundFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}


}

/// @nodoc


class ValidationFailure implements Failure {
  const ValidationFailure({this.message, this.field, this.failureCode});
  

@override final  String? message;
 final  String? field;
@override final  FailureCode? failureCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationFailureCopyWith<ValidationFailure> get copyWith => _$ValidationFailureCopyWithImpl<ValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.field, field) || other.field == field)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,field,failureCode);

@override
String toString() {
  return 'Failure.validation(message: $message, field: $field, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $ValidationFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ValidationFailureCopyWith(ValidationFailure value, $Res Function(ValidationFailure) _then) = _$ValidationFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, String? field, FailureCode? failureCode
});




}
/// @nodoc
class _$ValidationFailureCopyWithImpl<$Res>
    implements $ValidationFailureCopyWith<$Res> {
  _$ValidationFailureCopyWithImpl(this._self, this._then);

  final ValidationFailure _self;
  final $Res Function(ValidationFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? field = freezed,Object? failureCode = freezed,}) {
  return _then(ValidationFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,field: freezed == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}


}

/// @nodoc


class ServerFailure implements Failure {
  const ServerFailure({this.message, this.code, this.failureCode});
  

@override final  String? message;
 final  String? code;
@override final  FailureCode? failureCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerFailureCopyWith<ServerFailure> get copyWith => _$ServerFailureCopyWithImpl<ServerFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.code, code) || other.code == code)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,code,failureCode);

@override
String toString() {
  return 'Failure.server(message: $message, code: $code, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $ServerFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ServerFailureCopyWith(ServerFailure value, $Res Function(ServerFailure) _then) = _$ServerFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, String? code, FailureCode? failureCode
});




}
/// @nodoc
class _$ServerFailureCopyWithImpl<$Res>
    implements $ServerFailureCopyWith<$Res> {
  _$ServerFailureCopyWithImpl(this._self, this._then);

  final ServerFailure _self;
  final $Res Function(ServerFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? code = freezed,Object? failureCode = freezed,}) {
  return _then(ServerFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}


}

/// @nodoc


class UnknownFailure implements Failure {
  const UnknownFailure({this.message, this.failureCode});
  

@override final  String? message;
@override final  FailureCode? failureCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownFailureCopyWith<UnknownFailure> get copyWith => _$UnknownFailureCopyWithImpl<UnknownFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}


@override
int get hashCode => Object.hash(runtimeType,message,failureCode);

@override
String toString() {
  return 'Failure.unknown(message: $message, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $UnknownFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnknownFailureCopyWith(UnknownFailure value, $Res Function(UnknownFailure) _then) = _$UnknownFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message, FailureCode? failureCode
});




}
/// @nodoc
class _$UnknownFailureCopyWithImpl<$Res>
    implements $UnknownFailureCopyWith<$Res> {
  _$UnknownFailureCopyWithImpl(this._self, this._then);

  final UnknownFailure _self;
  final $Res Function(UnknownFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? failureCode = freezed,}) {
  return _then(UnknownFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as FailureCode?,
  ));
}


}

// dart format on
