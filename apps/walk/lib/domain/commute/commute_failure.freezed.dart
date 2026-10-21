// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commute_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommuteFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteFailure()';
}


}

/// @nodoc
class $CommuteFailureCopyWith<$Res>  {
$CommuteFailureCopyWith(CommuteFailure _, $Res Function(CommuteFailure) __);
}


/// Adds pattern-matching-related methods to [CommuteFailure].
extension CommuteFailurePatterns on CommuteFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommuteMissingPlaces value)?  missingPlaces,TResult Function( CommuteMissingKey value)?  missingKey,TResult Function( CommuteNetwork value)?  network,TResult Function( CommuteNoRoute value)?  noRoute,TResult Function( CommuteServer value)?  server,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommuteMissingPlaces() when missingPlaces != null:
return missingPlaces(_that);case CommuteMissingKey() when missingKey != null:
return missingKey(_that);case CommuteNetwork() when network != null:
return network(_that);case CommuteNoRoute() when noRoute != null:
return noRoute(_that);case CommuteServer() when server != null:
return server(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommuteMissingPlaces value)  missingPlaces,required TResult Function( CommuteMissingKey value)  missingKey,required TResult Function( CommuteNetwork value)  network,required TResult Function( CommuteNoRoute value)  noRoute,required TResult Function( CommuteServer value)  server,}){
final _that = this;
switch (_that) {
case CommuteMissingPlaces():
return missingPlaces(_that);case CommuteMissingKey():
return missingKey(_that);case CommuteNetwork():
return network(_that);case CommuteNoRoute():
return noRoute(_that);case CommuteServer():
return server(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommuteMissingPlaces value)?  missingPlaces,TResult? Function( CommuteMissingKey value)?  missingKey,TResult? Function( CommuteNetwork value)?  network,TResult? Function( CommuteNoRoute value)?  noRoute,TResult? Function( CommuteServer value)?  server,}){
final _that = this;
switch (_that) {
case CommuteMissingPlaces() when missingPlaces != null:
return missingPlaces(_that);case CommuteMissingKey() when missingKey != null:
return missingKey(_that);case CommuteNetwork() when network != null:
return network(_that);case CommuteNoRoute() when noRoute != null:
return noRoute(_that);case CommuteServer() when server != null:
return server(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  missingPlaces,TResult Function()?  missingKey,TResult Function()?  network,TResult Function()?  noRoute,TResult Function( String message)?  server,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommuteMissingPlaces() when missingPlaces != null:
return missingPlaces();case CommuteMissingKey() when missingKey != null:
return missingKey();case CommuteNetwork() when network != null:
return network();case CommuteNoRoute() when noRoute != null:
return noRoute();case CommuteServer() when server != null:
return server(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  missingPlaces,required TResult Function()  missingKey,required TResult Function()  network,required TResult Function()  noRoute,required TResult Function( String message)  server,}) {final _that = this;
switch (_that) {
case CommuteMissingPlaces():
return missingPlaces();case CommuteMissingKey():
return missingKey();case CommuteNetwork():
return network();case CommuteNoRoute():
return noRoute();case CommuteServer():
return server(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  missingPlaces,TResult? Function()?  missingKey,TResult? Function()?  network,TResult? Function()?  noRoute,TResult? Function( String message)?  server,}) {final _that = this;
switch (_that) {
case CommuteMissingPlaces() when missingPlaces != null:
return missingPlaces();case CommuteMissingKey() when missingKey != null:
return missingKey();case CommuteNetwork() when network != null:
return network();case CommuteNoRoute() when noRoute != null:
return noRoute();case CommuteServer() when server != null:
return server(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class CommuteMissingPlaces implements CommuteFailure {
  const CommuteMissingPlaces();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteMissingPlaces);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteFailure.missingPlaces()';
}


}




/// @nodoc


class CommuteMissingKey implements CommuteFailure {
  const CommuteMissingKey();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteMissingKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteFailure.missingKey()';
}


}




/// @nodoc


class CommuteNetwork implements CommuteFailure {
  const CommuteNetwork();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteNetwork);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteFailure.network()';
}


}




/// @nodoc


class CommuteNoRoute implements CommuteFailure {
  const CommuteNoRoute();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteNoRoute);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteFailure.noRoute()';
}


}




/// @nodoc


class CommuteServer implements CommuteFailure {
  const CommuteServer(this.message);
  

 final  String message;

/// Create a copy of CommuteFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteServerCopyWith<CommuteServer> get copyWith => _$CommuteServerCopyWithImpl<CommuteServer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteServer&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CommuteFailure.server(message: $message)';
}


}

/// @nodoc
abstract mixin class $CommuteServerCopyWith<$Res> implements $CommuteFailureCopyWith<$Res> {
  factory $CommuteServerCopyWith(CommuteServer value, $Res Function(CommuteServer) _then) = _$CommuteServerCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CommuteServerCopyWithImpl<$Res>
    implements $CommuteServerCopyWith<$Res> {
  _$CommuteServerCopyWithImpl(this._self, this._then);

  final CommuteServer _self;
  final $Res Function(CommuteServer) _then;

/// Create a copy of CommuteFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CommuteServer(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
