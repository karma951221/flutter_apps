// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthStarted value)?  started,TResult Function( AuthUserChanged value)?  userChanged,TResult Function( AuthUserRefreshRequested value)?  userRefreshRequested,TResult Function( AuthSignOutRequested value)?  signOutRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started(_that);case AuthUserChanged() when userChanged != null:
return userChanged(_that);case AuthUserRefreshRequested() when userRefreshRequested != null:
return userRefreshRequested(_that);case AuthSignOutRequested() when signOutRequested != null:
return signOutRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthStarted value)  started,required TResult Function( AuthUserChanged value)  userChanged,required TResult Function( AuthUserRefreshRequested value)  userRefreshRequested,required TResult Function( AuthSignOutRequested value)  signOutRequested,}){
final _that = this;
switch (_that) {
case AuthStarted():
return started(_that);case AuthUserChanged():
return userChanged(_that);case AuthUserRefreshRequested():
return userRefreshRequested(_that);case AuthSignOutRequested():
return signOutRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthStarted value)?  started,TResult? Function( AuthUserChanged value)?  userChanged,TResult? Function( AuthUserRefreshRequested value)?  userRefreshRequested,TResult? Function( AuthSignOutRequested value)?  signOutRequested,}){
final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started(_that);case AuthUserChanged() when userChanged != null:
return userChanged(_that);case AuthUserRefreshRequested() when userRefreshRequested != null:
return userRefreshRequested(_that);case AuthSignOutRequested() when signOutRequested != null:
return signOutRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( AppUser? user)?  userChanged,TResult Function()?  userRefreshRequested,TResult Function()?  signOutRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started();case AuthUserChanged() when userChanged != null:
return userChanged(_that.user);case AuthUserRefreshRequested() when userRefreshRequested != null:
return userRefreshRequested();case AuthSignOutRequested() when signOutRequested != null:
return signOutRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( AppUser? user)  userChanged,required TResult Function()  userRefreshRequested,required TResult Function()  signOutRequested,}) {final _that = this;
switch (_that) {
case AuthStarted():
return started();case AuthUserChanged():
return userChanged(_that.user);case AuthUserRefreshRequested():
return userRefreshRequested();case AuthSignOutRequested():
return signOutRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( AppUser? user)?  userChanged,TResult? Function()?  userRefreshRequested,TResult? Function()?  signOutRequested,}) {final _that = this;
switch (_that) {
case AuthStarted() when started != null:
return started();case AuthUserChanged() when userChanged != null:
return userChanged(_that.user);case AuthUserRefreshRequested() when userRefreshRequested != null:
return userRefreshRequested();case AuthSignOutRequested() when signOutRequested != null:
return signOutRequested();case _:
  return null;

}
}

}

/// @nodoc


class AuthStarted implements AuthEvent {
  const AuthStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.started()';
}


}




/// @nodoc


class AuthUserChanged implements AuthEvent {
  const AuthUserChanged(this.user);
  

 final  AppUser? user;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserChangedCopyWith<AuthUserChanged> get copyWith => _$AuthUserChangedCopyWithImpl<AuthUserChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUserChanged&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthEvent.userChanged(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthUserChangedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthUserChangedCopyWith(AuthUserChanged value, $Res Function(AuthUserChanged) _then) = _$AuthUserChangedCopyWithImpl;
@useResult
$Res call({
 AppUser? user
});


$AppUserCopyWith<$Res>? get user;

}
/// @nodoc
class _$AuthUserChangedCopyWithImpl<$Res>
    implements $AuthUserChangedCopyWith<$Res> {
  _$AuthUserChangedCopyWithImpl(this._self, this._then);

  final AuthUserChanged _self;
  final $Res Function(AuthUserChanged) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = freezed,}) {
  return _then(AuthUserChanged(
freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AppUser?,
  ));
}

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AppUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class AuthUserRefreshRequested implements AuthEvent {
  const AuthUserRefreshRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUserRefreshRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.userRefreshRequested()';
}


}




/// @nodoc


class AuthSignOutRequested implements AuthEvent {
  const AuthSignOutRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSignOutRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signOutRequested()';
}


}




// dart format on
