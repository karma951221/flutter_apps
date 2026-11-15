// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DraftRun {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftRun);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $DraftRunCopyWith<$Res>  {
$DraftRunCopyWith(DraftRun _, $Res Function(DraftRun) __);
}


/// Adds pattern-matching-related methods to [DraftRun].
extension DraftRunPatterns on DraftRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DraftRunIdle value)?  idle,TResult Function( DraftRunWriting value)?  writing,TResult Function( DraftRunDone value)?  done,TResult Function( DraftRunFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DraftRunIdle() when idle != null:
return idle(_that);case DraftRunWriting() when writing != null:
return writing(_that);case DraftRunDone() when done != null:
return done(_that);case DraftRunFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DraftRunIdle value)  idle,required TResult Function( DraftRunWriting value)  writing,required TResult Function( DraftRunDone value)  done,required TResult Function( DraftRunFailed value)  failed,}){
final _that = this;
switch (_that) {
case DraftRunIdle():
return idle(_that);case DraftRunWriting():
return writing(_that);case DraftRunDone():
return done(_that);case DraftRunFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DraftRunIdle value)?  idle,TResult? Function( DraftRunWriting value)?  writing,TResult? Function( DraftRunDone value)?  done,TResult? Function( DraftRunFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DraftRunIdle() when idle != null:
return idle(_that);case DraftRunWriting() when writing != null:
return writing(_that);case DraftRunDone() when done != null:
return done(_that);case DraftRunFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  writing,TResult Function( String text)?  done,TResult Function( ChatFailure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DraftRunIdle() when idle != null:
return idle();case DraftRunWriting() when writing != null:
return writing();case DraftRunDone() when done != null:
return done(_that.text);case DraftRunFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  writing,required TResult Function( String text)  done,required TResult Function( ChatFailure failure)  failed,}) {final _that = this;
switch (_that) {
case DraftRunIdle():
return idle();case DraftRunWriting():
return writing();case DraftRunDone():
return done(_that.text);case DraftRunFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  writing,TResult? Function( String text)?  done,TResult? Function( ChatFailure failure)?  failed,}) {final _that = this;
switch (_that) {
case DraftRunIdle() when idle != null:
return idle();case DraftRunWriting() when writing != null:
return writing();case DraftRunDone() when done != null:
return done(_that.text);case DraftRunFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DraftRunIdle implements DraftRun {
  const DraftRunIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftRunIdle);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class DraftRunWriting implements DraftRun {
  const DraftRunWriting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftRunWriting);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class DraftRunDone implements DraftRun {
  const DraftRunDone(this.text);
  

 final  String text;

/// Create a copy of DraftRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftRunDoneCopyWith<DraftRunDone> get copyWith => _$DraftRunDoneCopyWithImpl<DraftRunDone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftRunDone&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);



}

/// @nodoc
abstract mixin class $DraftRunDoneCopyWith<$Res> implements $DraftRunCopyWith<$Res> {
  factory $DraftRunDoneCopyWith(DraftRunDone value, $Res Function(DraftRunDone) _then) = _$DraftRunDoneCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$DraftRunDoneCopyWithImpl<$Res>
    implements $DraftRunDoneCopyWith<$Res> {
  _$DraftRunDoneCopyWithImpl(this._self, this._then);

  final DraftRunDone _self;
  final $Res Function(DraftRunDone) _then;

/// Create a copy of DraftRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(DraftRunDone(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DraftRunFailed implements DraftRun {
  const DraftRunFailed(this.failure);
  

 final  ChatFailure failure;

/// Create a copy of DraftRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftRunFailedCopyWith<DraftRunFailed> get copyWith => _$DraftRunFailedCopyWithImpl<DraftRunFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftRunFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);



}

/// @nodoc
abstract mixin class $DraftRunFailedCopyWith<$Res> implements $DraftRunCopyWith<$Res> {
  factory $DraftRunFailedCopyWith(DraftRunFailed value, $Res Function(DraftRunFailed) _then) = _$DraftRunFailedCopyWithImpl;
@useResult
$Res call({
 ChatFailure failure
});




}
/// @nodoc
class _$DraftRunFailedCopyWithImpl<$Res>
    implements $DraftRunFailedCopyWith<$Res> {
  _$DraftRunFailedCopyWithImpl(this._self, this._then);

  final DraftRunFailed _self;
  final $Res Function(DraftRunFailed) _then;

/// Create a copy of DraftRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DraftRunFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ChatFailure,
  ));
}


}

/// @nodoc
mixin _$DraftState {

 DraftAvailability? get availability; DraftStyle get style; bool get includePhotos; DraftRun get run;
/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftStateCopyWith<DraftState> get copyWith => _$DraftStateCopyWithImpl<DraftState>(this as DraftState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftState&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.style, style) || other.style == style)&&(identical(other.includePhotos, includePhotos) || other.includePhotos == includePhotos)&&(identical(other.run, run) || other.run == run));
}


@override
int get hashCode => Object.hash(runtimeType,availability,style,includePhotos,run);

@override
String toString() {
  return 'DraftState(availability: $availability, style: $style, includePhotos: $includePhotos, run: $run)';
}


}

/// @nodoc
abstract mixin class $DraftStateCopyWith<$Res>  {
  factory $DraftStateCopyWith(DraftState value, $Res Function(DraftState) _then) = _$DraftStateCopyWithImpl;
@useResult
$Res call({
 DraftAvailability? availability, DraftStyle style, bool includePhotos, DraftRun run
});




}
/// @nodoc
class _$DraftStateCopyWithImpl<$Res>
    implements $DraftStateCopyWith<$Res> {
  _$DraftStateCopyWithImpl(this._self, this._then);

  final DraftState _self;
  final $Res Function(DraftState) _then;

/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? availability = freezed,Object? style = null,Object? includePhotos = null,Object? run = null,}) {
  return _then(DraftState(
availability: freezed == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as DraftAvailability?,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as DraftStyle,includePhotos: null == includePhotos ? _self.includePhotos : includePhotos // ignore: cast_nullable_to_non_nullable
as bool,run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as DraftRun,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftState].
extension DraftStatePatterns on DraftState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
