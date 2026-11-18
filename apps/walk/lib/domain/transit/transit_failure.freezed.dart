// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransitFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransitFailure()';
}


}

/// @nodoc
class $TransitFailureCopyWith<$Res>  {
$TransitFailureCopyWith(TransitFailure _, $Res Function(TransitFailure) __);
}


/// Adds pattern-matching-related methods to [TransitFailure].
extension TransitFailurePatterns on TransitFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TransitMissingKey value)?  missingKey,TResult Function( TransitKeyRejected value)?  keyRejected,TResult Function( TransitQuotaExceeded value)?  quotaExceeded,TResult Function( TransitNetwork value)?  network,TResult Function( TransitNoRoute value)?  noRoute,TResult Function( TransitTooClose value)?  tooClose,TResult Function( TransitServer value)?  server,TResult Function( TransitUnexpected value)?  unexpected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TransitMissingKey() when missingKey != null:
return missingKey(_that);case TransitKeyRejected() when keyRejected != null:
return keyRejected(_that);case TransitQuotaExceeded() when quotaExceeded != null:
return quotaExceeded(_that);case TransitNetwork() when network != null:
return network(_that);case TransitNoRoute() when noRoute != null:
return noRoute(_that);case TransitTooClose() when tooClose != null:
return tooClose(_that);case TransitServer() when server != null:
return server(_that);case TransitUnexpected() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TransitMissingKey value)  missingKey,required TResult Function( TransitKeyRejected value)  keyRejected,required TResult Function( TransitQuotaExceeded value)  quotaExceeded,required TResult Function( TransitNetwork value)  network,required TResult Function( TransitNoRoute value)  noRoute,required TResult Function( TransitTooClose value)  tooClose,required TResult Function( TransitServer value)  server,required TResult Function( TransitUnexpected value)  unexpected,}){
final _that = this;
switch (_that) {
case TransitMissingKey():
return missingKey(_that);case TransitKeyRejected():
return keyRejected(_that);case TransitQuotaExceeded():
return quotaExceeded(_that);case TransitNetwork():
return network(_that);case TransitNoRoute():
return noRoute(_that);case TransitTooClose():
return tooClose(_that);case TransitServer():
return server(_that);case TransitUnexpected():
return unexpected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TransitMissingKey value)?  missingKey,TResult? Function( TransitKeyRejected value)?  keyRejected,TResult? Function( TransitQuotaExceeded value)?  quotaExceeded,TResult? Function( TransitNetwork value)?  network,TResult? Function( TransitNoRoute value)?  noRoute,TResult? Function( TransitTooClose value)?  tooClose,TResult? Function( TransitServer value)?  server,TResult? Function( TransitUnexpected value)?  unexpected,}){
final _that = this;
switch (_that) {
case TransitMissingKey() when missingKey != null:
return missingKey(_that);case TransitKeyRejected() when keyRejected != null:
return keyRejected(_that);case TransitQuotaExceeded() when quotaExceeded != null:
return quotaExceeded(_that);case TransitNetwork() when network != null:
return network(_that);case TransitNoRoute() when noRoute != null:
return noRoute(_that);case TransitTooClose() when tooClose != null:
return tooClose(_that);case TransitServer() when server != null:
return server(_that);case TransitUnexpected() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  missingKey,TResult Function( String message)?  keyRejected,TResult Function( String detail)?  quotaExceeded,TResult Function( String detail)?  network,TResult Function()?  noRoute,TResult Function()?  tooClose,TResult Function( String message)?  server,TResult Function( String detail)?  unexpected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransitMissingKey() when missingKey != null:
return missingKey();case TransitKeyRejected() when keyRejected != null:
return keyRejected(_that.message);case TransitQuotaExceeded() when quotaExceeded != null:
return quotaExceeded(_that.detail);case TransitNetwork() when network != null:
return network(_that.detail);case TransitNoRoute() when noRoute != null:
return noRoute();case TransitTooClose() when tooClose != null:
return tooClose();case TransitServer() when server != null:
return server(_that.message);case TransitUnexpected() when unexpected != null:
return unexpected(_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  missingKey,required TResult Function( String message)  keyRejected,required TResult Function( String detail)  quotaExceeded,required TResult Function( String detail)  network,required TResult Function()  noRoute,required TResult Function()  tooClose,required TResult Function( String message)  server,required TResult Function( String detail)  unexpected,}) {final _that = this;
switch (_that) {
case TransitMissingKey():
return missingKey();case TransitKeyRejected():
return keyRejected(_that.message);case TransitQuotaExceeded():
return quotaExceeded(_that.detail);case TransitNetwork():
return network(_that.detail);case TransitNoRoute():
return noRoute();case TransitTooClose():
return tooClose();case TransitServer():
return server(_that.message);case TransitUnexpected():
return unexpected(_that.detail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  missingKey,TResult? Function( String message)?  keyRejected,TResult? Function( String detail)?  quotaExceeded,TResult? Function( String detail)?  network,TResult? Function()?  noRoute,TResult? Function()?  tooClose,TResult? Function( String message)?  server,TResult? Function( String detail)?  unexpected,}) {final _that = this;
switch (_that) {
case TransitMissingKey() when missingKey != null:
return missingKey();case TransitKeyRejected() when keyRejected != null:
return keyRejected(_that.message);case TransitQuotaExceeded() when quotaExceeded != null:
return quotaExceeded(_that.detail);case TransitNetwork() when network != null:
return network(_that.detail);case TransitNoRoute() when noRoute != null:
return noRoute();case TransitTooClose() when tooClose != null:
return tooClose();case TransitServer() when server != null:
return server(_that.message);case TransitUnexpected() when unexpected != null:
return unexpected(_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class TransitMissingKey implements TransitFailure {
  const TransitMissingKey();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitMissingKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransitFailure.missingKey()';
}


}




/// @nodoc


class TransitKeyRejected implements TransitFailure {
  const TransitKeyRejected(this.message);
  

 final  String message;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitKeyRejectedCopyWith<TransitKeyRejected> get copyWith => _$TransitKeyRejectedCopyWithImpl<TransitKeyRejected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitKeyRejected&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TransitFailure.keyRejected(message: $message)';
}


}

/// @nodoc
abstract mixin class $TransitKeyRejectedCopyWith<$Res> implements $TransitFailureCopyWith<$Res> {
  factory $TransitKeyRejectedCopyWith(TransitKeyRejected value, $Res Function(TransitKeyRejected) _then) = _$TransitKeyRejectedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$TransitKeyRejectedCopyWithImpl<$Res>
    implements $TransitKeyRejectedCopyWith<$Res> {
  _$TransitKeyRejectedCopyWithImpl(this._self, this._then);

  final TransitKeyRejected _self;
  final $Res Function(TransitKeyRejected) _then;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(TransitKeyRejected(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransitQuotaExceeded implements TransitFailure {
  const TransitQuotaExceeded([this.detail = '']);
  

@JsonKey() final  String detail;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitQuotaExceededCopyWith<TransitQuotaExceeded> get copyWith => _$TransitQuotaExceededCopyWithImpl<TransitQuotaExceeded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitQuotaExceeded&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'TransitFailure.quotaExceeded(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $TransitQuotaExceededCopyWith<$Res> implements $TransitFailureCopyWith<$Res> {
  factory $TransitQuotaExceededCopyWith(TransitQuotaExceeded value, $Res Function(TransitQuotaExceeded) _then) = _$TransitQuotaExceededCopyWithImpl;
@useResult
$Res call({
 String detail
});




}
/// @nodoc
class _$TransitQuotaExceededCopyWithImpl<$Res>
    implements $TransitQuotaExceededCopyWith<$Res> {
  _$TransitQuotaExceededCopyWithImpl(this._self, this._then);

  final TransitQuotaExceeded _self;
  final $Res Function(TransitQuotaExceeded) _then;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = null,}) {
  return _then(TransitQuotaExceeded(
null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransitNetwork implements TransitFailure {
  const TransitNetwork([this.detail = '']);
  

@JsonKey() final  String detail;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitNetworkCopyWith<TransitNetwork> get copyWith => _$TransitNetworkCopyWithImpl<TransitNetwork>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitNetwork&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'TransitFailure.network(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $TransitNetworkCopyWith<$Res> implements $TransitFailureCopyWith<$Res> {
  factory $TransitNetworkCopyWith(TransitNetwork value, $Res Function(TransitNetwork) _then) = _$TransitNetworkCopyWithImpl;
@useResult
$Res call({
 String detail
});




}
/// @nodoc
class _$TransitNetworkCopyWithImpl<$Res>
    implements $TransitNetworkCopyWith<$Res> {
  _$TransitNetworkCopyWithImpl(this._self, this._then);

  final TransitNetwork _self;
  final $Res Function(TransitNetwork) _then;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = null,}) {
  return _then(TransitNetwork(
null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransitNoRoute implements TransitFailure {
  const TransitNoRoute();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitNoRoute);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransitFailure.noRoute()';
}


}




/// @nodoc


class TransitTooClose implements TransitFailure {
  const TransitTooClose();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitTooClose);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransitFailure.tooClose()';
}


}




/// @nodoc


class TransitServer implements TransitFailure {
  const TransitServer(this.message);
  

 final  String message;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitServerCopyWith<TransitServer> get copyWith => _$TransitServerCopyWithImpl<TransitServer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitServer&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TransitFailure.server(message: $message)';
}


}

/// @nodoc
abstract mixin class $TransitServerCopyWith<$Res> implements $TransitFailureCopyWith<$Res> {
  factory $TransitServerCopyWith(TransitServer value, $Res Function(TransitServer) _then) = _$TransitServerCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$TransitServerCopyWithImpl<$Res>
    implements $TransitServerCopyWith<$Res> {
  _$TransitServerCopyWithImpl(this._self, this._then);

  final TransitServer _self;
  final $Res Function(TransitServer) _then;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(TransitServer(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransitUnexpected implements TransitFailure {
  const TransitUnexpected(this.detail);
  

 final  String detail;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitUnexpectedCopyWith<TransitUnexpected> get copyWith => _$TransitUnexpectedCopyWithImpl<TransitUnexpected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitUnexpected&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'TransitFailure.unexpected(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $TransitUnexpectedCopyWith<$Res> implements $TransitFailureCopyWith<$Res> {
  factory $TransitUnexpectedCopyWith(TransitUnexpected value, $Res Function(TransitUnexpected) _then) = _$TransitUnexpectedCopyWithImpl;
@useResult
$Res call({
 String detail
});




}
/// @nodoc
class _$TransitUnexpectedCopyWithImpl<$Res>
    implements $TransitUnexpectedCopyWith<$Res> {
  _$TransitUnexpectedCopyWithImpl(this._self, this._then);

  final TransitUnexpected _self;
  final $Res Function(TransitUnexpected) _then;

/// Create a copy of TransitFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = null,}) {
  return _then(TransitUnexpected(
null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
