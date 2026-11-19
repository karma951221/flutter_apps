// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_classifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryAiAvailability {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryAiAvailability);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoryAiAvailability()';
}


}

/// @nodoc
class $StoryAiAvailabilityCopyWith<$Res>  {
$StoryAiAvailabilityCopyWith(StoryAiAvailability _, $Res Function(StoryAiAvailability) __);
}


/// Adds pattern-matching-related methods to [StoryAiAvailability].
extension StoryAiAvailabilityPatterns on StoryAiAvailability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StoryAiUnavailable value)?  unavailable,TResult Function( StoryAiConsentNeeded value)?  needsConsent,TResult Function( StoryAiReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StoryAiUnavailable() when unavailable != null:
return unavailable(_that);case StoryAiConsentNeeded() when needsConsent != null:
return needsConsent(_that);case StoryAiReady() when ready != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StoryAiUnavailable value)  unavailable,required TResult Function( StoryAiConsentNeeded value)  needsConsent,required TResult Function( StoryAiReady value)  ready,}){
final _that = this;
switch (_that) {
case StoryAiUnavailable():
return unavailable(_that);case StoryAiConsentNeeded():
return needsConsent(_that);case StoryAiReady():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StoryAiUnavailable value)?  unavailable,TResult? Function( StoryAiConsentNeeded value)?  needsConsent,TResult? Function( StoryAiReady value)?  ready,}){
final _that = this;
switch (_that) {
case StoryAiUnavailable() when unavailable != null:
return unavailable(_that);case StoryAiConsentNeeded() when needsConsent != null:
return needsConsent(_that);case StoryAiReady() when ready != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unavailable,TResult Function( ChatVendor vendor)?  needsConsent,TResult Function( ChatVendor vendor)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StoryAiUnavailable() when unavailable != null:
return unavailable();case StoryAiConsentNeeded() when needsConsent != null:
return needsConsent(_that.vendor);case StoryAiReady() when ready != null:
return ready(_that.vendor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unavailable,required TResult Function( ChatVendor vendor)  needsConsent,required TResult Function( ChatVendor vendor)  ready,}) {final _that = this;
switch (_that) {
case StoryAiUnavailable():
return unavailable();case StoryAiConsentNeeded():
return needsConsent(_that.vendor);case StoryAiReady():
return ready(_that.vendor);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unavailable,TResult? Function( ChatVendor vendor)?  needsConsent,TResult? Function( ChatVendor vendor)?  ready,}) {final _that = this;
switch (_that) {
case StoryAiUnavailable() when unavailable != null:
return unavailable();case StoryAiConsentNeeded() when needsConsent != null:
return needsConsent(_that.vendor);case StoryAiReady() when ready != null:
return ready(_that.vendor);case _:
  return null;

}
}

}

/// @nodoc


class StoryAiUnavailable implements StoryAiAvailability {
  const StoryAiUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryAiUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoryAiAvailability.unavailable()';
}


}




/// @nodoc


class StoryAiConsentNeeded implements StoryAiAvailability {
  const StoryAiConsentNeeded(this.vendor);
  

 final  ChatVendor vendor;

/// Create a copy of StoryAiAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryAiConsentNeededCopyWith<StoryAiConsentNeeded> get copyWith => _$StoryAiConsentNeededCopyWithImpl<StoryAiConsentNeeded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryAiConsentNeeded&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'StoryAiAvailability.needsConsent(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $StoryAiConsentNeededCopyWith<$Res> implements $StoryAiAvailabilityCopyWith<$Res> {
  factory $StoryAiConsentNeededCopyWith(StoryAiConsentNeeded value, $Res Function(StoryAiConsentNeeded) _then) = _$StoryAiConsentNeededCopyWithImpl;
@useResult
$Res call({
 ChatVendor vendor
});




}
/// @nodoc
class _$StoryAiConsentNeededCopyWithImpl<$Res>
    implements $StoryAiConsentNeededCopyWith<$Res> {
  _$StoryAiConsentNeededCopyWithImpl(this._self, this._then);

  final StoryAiConsentNeeded _self;
  final $Res Function(StoryAiConsentNeeded) _then;

/// Create a copy of StoryAiAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? vendor = null,}) {
  return _then(StoryAiConsentNeeded(
null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,
  ));
}


}

/// @nodoc


class StoryAiReady implements StoryAiAvailability {
  const StoryAiReady(this.vendor);
  

 final  ChatVendor vendor;

/// Create a copy of StoryAiAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryAiReadyCopyWith<StoryAiReady> get copyWith => _$StoryAiReadyCopyWithImpl<StoryAiReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryAiReady&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'StoryAiAvailability.ready(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $StoryAiReadyCopyWith<$Res> implements $StoryAiAvailabilityCopyWith<$Res> {
  factory $StoryAiReadyCopyWith(StoryAiReady value, $Res Function(StoryAiReady) _then) = _$StoryAiReadyCopyWithImpl;
@useResult
$Res call({
 ChatVendor vendor
});




}
/// @nodoc
class _$StoryAiReadyCopyWithImpl<$Res>
    implements $StoryAiReadyCopyWith<$Res> {
  _$StoryAiReadyCopyWithImpl(this._self, this._then);

  final StoryAiReady _self;
  final $Res Function(StoryAiReady) _then;

/// Create a copy of StoryAiAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? vendor = null,}) {
  return _then(StoryAiReady(
null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,
  ));
}


}

// dart format on
