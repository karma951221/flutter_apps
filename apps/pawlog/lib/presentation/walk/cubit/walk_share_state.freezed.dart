// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_share_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkShareState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkShareState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkShareState()';
}


}

/// @nodoc
class $WalkShareStateCopyWith<$Res>  {
$WalkShareStateCopyWith(WalkShareState _, $Res Function(WalkShareState) __);
}


/// Adds pattern-matching-related methods to [WalkShareState].
extension WalkShareStatePatterns on WalkShareState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WalkShareChecking value)?  checking,TResult Function( WalkShareHidden value)?  hidden,TResult Function( WalkShareReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WalkShareChecking() when checking != null:
return checking(_that);case WalkShareHidden() when hidden != null:
return hidden(_that);case WalkShareReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WalkShareChecking value)  checking,required TResult Function( WalkShareHidden value)  hidden,required TResult Function( WalkShareReady value)  ready,}){
final _that = this;
switch (_that) {
case WalkShareChecking():
return checking(_that);case WalkShareHidden():
return hidden(_that);case WalkShareReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WalkShareChecking value)?  checking,TResult? Function( WalkShareHidden value)?  hidden,TResult? Function( WalkShareReady value)?  ready,}){
final _that = this;
switch (_that) {
case WalkShareChecking() when checking != null:
return checking(_that);case WalkShareHidden() when hidden != null:
return hidden(_that);case WalkShareReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  checking,TResult Function()?  hidden,TResult Function( bool shared,  bool busy)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WalkShareChecking() when checking != null:
return checking();case WalkShareHidden() when hidden != null:
return hidden();case WalkShareReady() when ready != null:
return ready(_that.shared,_that.busy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  checking,required TResult Function()  hidden,required TResult Function( bool shared,  bool busy)  ready,}) {final _that = this;
switch (_that) {
case WalkShareChecking():
return checking();case WalkShareHidden():
return hidden();case WalkShareReady():
return ready(_that.shared,_that.busy);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  checking,TResult? Function()?  hidden,TResult? Function( bool shared,  bool busy)?  ready,}) {final _that = this;
switch (_that) {
case WalkShareChecking() when checking != null:
return checking();case WalkShareHidden() when hidden != null:
return hidden();case WalkShareReady() when ready != null:
return ready(_that.shared,_that.busy);case _:
  return null;

}
}

}

/// @nodoc


class WalkShareChecking implements WalkShareState {
  const WalkShareChecking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkShareChecking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkShareState.checking()';
}


}




/// @nodoc


class WalkShareHidden implements WalkShareState {
  const WalkShareHidden();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkShareHidden);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkShareState.hidden()';
}


}




/// @nodoc


class WalkShareReady implements WalkShareState {
  const WalkShareReady({required this.shared, this.busy = false});
  

 final  bool shared;
@JsonKey() final  bool busy;

/// Create a copy of WalkShareState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkShareReadyCopyWith<WalkShareReady> get copyWith => _$WalkShareReadyCopyWithImpl<WalkShareReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkShareReady&&(identical(other.shared, shared) || other.shared == shared)&&(identical(other.busy, busy) || other.busy == busy));
}


@override
int get hashCode => Object.hash(runtimeType,shared,busy);

@override
String toString() {
  return 'WalkShareState.ready(shared: $shared, busy: $busy)';
}


}

/// @nodoc
abstract mixin class $WalkShareReadyCopyWith<$Res> implements $WalkShareStateCopyWith<$Res> {
  factory $WalkShareReadyCopyWith(WalkShareReady value, $Res Function(WalkShareReady) _then) = _$WalkShareReadyCopyWithImpl;
@useResult
$Res call({
 bool shared, bool busy
});




}
/// @nodoc
class _$WalkShareReadyCopyWithImpl<$Res>
    implements $WalkShareReadyCopyWith<$Res> {
  _$WalkShareReadyCopyWithImpl(this._self, this._then);

  final WalkShareReady _self;
  final $Res Function(WalkShareReady) _then;

/// Create a copy of WalkShareState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shared = null,Object? busy = null,}) {
  return _then(WalkShareReady(
shared: null == shared ? _self.shared : shared // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
