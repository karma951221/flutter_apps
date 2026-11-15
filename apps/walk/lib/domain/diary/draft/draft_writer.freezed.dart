// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_writer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DraftEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftEvent);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $DraftEventCopyWith<$Res>  {
$DraftEventCopyWith(DraftEvent _, $Res Function(DraftEvent) __);
}


/// Adds pattern-matching-related methods to [DraftEvent].
extension DraftEventPatterns on DraftEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DraftDelta value)?  delta,TResult Function( DraftDone value)?  done,TResult Function( DraftFailed value)?  failed,TResult Function( DraftNeedsConsent value)?  needsConsent,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DraftDelta() when delta != null:
return delta(_that);case DraftDone() when done != null:
return done(_that);case DraftFailed() when failed != null:
return failed(_that);case DraftNeedsConsent() when needsConsent != null:
return needsConsent(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DraftDelta value)  delta,required TResult Function( DraftDone value)  done,required TResult Function( DraftFailed value)  failed,required TResult Function( DraftNeedsConsent value)  needsConsent,}){
final _that = this;
switch (_that) {
case DraftDelta():
return delta(_that);case DraftDone():
return done(_that);case DraftFailed():
return failed(_that);case DraftNeedsConsent():
return needsConsent(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DraftDelta value)?  delta,TResult? Function( DraftDone value)?  done,TResult? Function( DraftFailed value)?  failed,TResult? Function( DraftNeedsConsent value)?  needsConsent,}){
final _that = this;
switch (_that) {
case DraftDelta() when delta != null:
return delta(_that);case DraftDone() when done != null:
return done(_that);case DraftFailed() when failed != null:
return failed(_that);case DraftNeedsConsent() when needsConsent != null:
return needsConsent(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  delta,TResult Function( String text)?  done,TResult Function( ChatFailure failure)?  failed,TResult Function()?  needsConsent,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DraftDelta() when delta != null:
return delta(_that.text);case DraftDone() when done != null:
return done(_that.text);case DraftFailed() when failed != null:
return failed(_that.failure);case DraftNeedsConsent() when needsConsent != null:
return needsConsent();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  delta,required TResult Function( String text)  done,required TResult Function( ChatFailure failure)  failed,required TResult Function()  needsConsent,}) {final _that = this;
switch (_that) {
case DraftDelta():
return delta(_that.text);case DraftDone():
return done(_that.text);case DraftFailed():
return failed(_that.failure);case DraftNeedsConsent():
return needsConsent();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  delta,TResult? Function( String text)?  done,TResult? Function( ChatFailure failure)?  failed,TResult? Function()?  needsConsent,}) {final _that = this;
switch (_that) {
case DraftDelta() when delta != null:
return delta(_that.text);case DraftDone() when done != null:
return done(_that.text);case DraftFailed() when failed != null:
return failed(_that.failure);case DraftNeedsConsent() when needsConsent != null:
return needsConsent();case _:
  return null;

}
}

}

/// @nodoc


class DraftDelta implements DraftEvent {
  const DraftDelta(this.text);
  

 final  String text;

/// Create a copy of DraftEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftDeltaCopyWith<DraftDelta> get copyWith => _$DraftDeltaCopyWithImpl<DraftDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftDelta&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);



}

/// @nodoc
abstract mixin class $DraftDeltaCopyWith<$Res> implements $DraftEventCopyWith<$Res> {
  factory $DraftDeltaCopyWith(DraftDelta value, $Res Function(DraftDelta) _then) = _$DraftDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$DraftDeltaCopyWithImpl<$Res>
    implements $DraftDeltaCopyWith<$Res> {
  _$DraftDeltaCopyWithImpl(this._self, this._then);

  final DraftDelta _self;
  final $Res Function(DraftDelta) _then;

/// Create a copy of DraftEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(DraftDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DraftDone implements DraftEvent {
  const DraftDone(this.text);
  

 final  String text;

/// Create a copy of DraftEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftDoneCopyWith<DraftDone> get copyWith => _$DraftDoneCopyWithImpl<DraftDone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftDone&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);



}

/// @nodoc
abstract mixin class $DraftDoneCopyWith<$Res> implements $DraftEventCopyWith<$Res> {
  factory $DraftDoneCopyWith(DraftDone value, $Res Function(DraftDone) _then) = _$DraftDoneCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$DraftDoneCopyWithImpl<$Res>
    implements $DraftDoneCopyWith<$Res> {
  _$DraftDoneCopyWithImpl(this._self, this._then);

  final DraftDone _self;
  final $Res Function(DraftDone) _then;

/// Create a copy of DraftEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(DraftDone(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DraftFailed implements DraftEvent {
  const DraftFailed(this.failure);
  

 final  ChatFailure failure;

/// Create a copy of DraftEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftFailedCopyWith<DraftFailed> get copyWith => _$DraftFailedCopyWithImpl<DraftFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);



}

/// @nodoc
abstract mixin class $DraftFailedCopyWith<$Res> implements $DraftEventCopyWith<$Res> {
  factory $DraftFailedCopyWith(DraftFailed value, $Res Function(DraftFailed) _then) = _$DraftFailedCopyWithImpl;
@useResult
$Res call({
 ChatFailure failure
});




}
/// @nodoc
class _$DraftFailedCopyWithImpl<$Res>
    implements $DraftFailedCopyWith<$Res> {
  _$DraftFailedCopyWithImpl(this._self, this._then);

  final DraftFailed _self;
  final $Res Function(DraftFailed) _then;

/// Create a copy of DraftEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DraftFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ChatFailure,
  ));
}


}

/// @nodoc


class DraftNeedsConsent implements DraftEvent {
  const DraftNeedsConsent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftNeedsConsent);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc
mixin _$DraftAvailability {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftAvailability);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DraftAvailability()';
}


}

/// @nodoc
class $DraftAvailabilityCopyWith<$Res>  {
$DraftAvailabilityCopyWith(DraftAvailability _, $Res Function(DraftAvailability) __);
}


/// Adds pattern-matching-related methods to [DraftAvailability].
extension DraftAvailabilityPatterns on DraftAvailability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DraftNoKey value)?  noKey,TResult Function( DraftConsentNeeded value)?  needsConsent,TResult Function( DraftReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DraftNoKey() when noKey != null:
return noKey(_that);case DraftConsentNeeded() when needsConsent != null:
return needsConsent(_that);case DraftReady() when ready != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DraftNoKey value)  noKey,required TResult Function( DraftConsentNeeded value)  needsConsent,required TResult Function( DraftReady value)  ready,}){
final _that = this;
switch (_that) {
case DraftNoKey():
return noKey(_that);case DraftConsentNeeded():
return needsConsent(_that);case DraftReady():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DraftNoKey value)?  noKey,TResult? Function( DraftConsentNeeded value)?  needsConsent,TResult? Function( DraftReady value)?  ready,}){
final _that = this;
switch (_that) {
case DraftNoKey() when noKey != null:
return noKey(_that);case DraftConsentNeeded() when needsConsent != null:
return needsConsent(_that);case DraftReady() when ready != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  noKey,TResult Function( ChatVendor vendor)?  needsConsent,TResult Function( ChatVendor vendor)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DraftNoKey() when noKey != null:
return noKey();case DraftConsentNeeded() when needsConsent != null:
return needsConsent(_that.vendor);case DraftReady() when ready != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  noKey,required TResult Function( ChatVendor vendor)  needsConsent,required TResult Function( ChatVendor vendor)  ready,}) {final _that = this;
switch (_that) {
case DraftNoKey():
return noKey();case DraftConsentNeeded():
return needsConsent(_that.vendor);case DraftReady():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  noKey,TResult? Function( ChatVendor vendor)?  needsConsent,TResult? Function( ChatVendor vendor)?  ready,}) {final _that = this;
switch (_that) {
case DraftNoKey() when noKey != null:
return noKey();case DraftConsentNeeded() when needsConsent != null:
return needsConsent(_that.vendor);case DraftReady() when ready != null:
return ready(_that.vendor);case _:
  return null;

}
}

}

/// @nodoc


class DraftNoKey implements DraftAvailability {
  const DraftNoKey();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftNoKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DraftAvailability.noKey()';
}


}




/// @nodoc


class DraftConsentNeeded implements DraftAvailability {
  const DraftConsentNeeded(this.vendor);
  

 final  ChatVendor vendor;

/// Create a copy of DraftAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftConsentNeededCopyWith<DraftConsentNeeded> get copyWith => _$DraftConsentNeededCopyWithImpl<DraftConsentNeeded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftConsentNeeded&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'DraftAvailability.needsConsent(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $DraftConsentNeededCopyWith<$Res> implements $DraftAvailabilityCopyWith<$Res> {
  factory $DraftConsentNeededCopyWith(DraftConsentNeeded value, $Res Function(DraftConsentNeeded) _then) = _$DraftConsentNeededCopyWithImpl;
@useResult
$Res call({
 ChatVendor vendor
});




}
/// @nodoc
class _$DraftConsentNeededCopyWithImpl<$Res>
    implements $DraftConsentNeededCopyWith<$Res> {
  _$DraftConsentNeededCopyWithImpl(this._self, this._then);

  final DraftConsentNeeded _self;
  final $Res Function(DraftConsentNeeded) _then;

/// Create a copy of DraftAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? vendor = null,}) {
  return _then(DraftConsentNeeded(
null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,
  ));
}


}

/// @nodoc


class DraftReady implements DraftAvailability {
  const DraftReady(this.vendor);
  

 final  ChatVendor vendor;

/// Create a copy of DraftAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftReadyCopyWith<DraftReady> get copyWith => _$DraftReadyCopyWithImpl<DraftReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftReady&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'DraftAvailability.ready(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $DraftReadyCopyWith<$Res> implements $DraftAvailabilityCopyWith<$Res> {
  factory $DraftReadyCopyWith(DraftReady value, $Res Function(DraftReady) _then) = _$DraftReadyCopyWithImpl;
@useResult
$Res call({
 ChatVendor vendor
});




}
/// @nodoc
class _$DraftReadyCopyWithImpl<$Res>
    implements $DraftReadyCopyWith<$Res> {
  _$DraftReadyCopyWithImpl(this._self, this._then);

  final DraftReady _self;
  final $Res Function(DraftReady) _then;

/// Create a copy of DraftAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? vendor = null,}) {
  return _then(DraftReady(
null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,
  ));
}


}

// dart format on
