// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catch_verdict.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatchVerdict {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatchVerdict);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CatchVerdict()';
}


}

/// @nodoc
class $CatchVerdictCopyWith<$Res>  {
$CatchVerdictCopyWith(CatchVerdict _, $Res Function(CatchVerdict) __);
}


/// Adds pattern-matching-related methods to [CatchVerdict].
extension CatchVerdictPatterns on CatchVerdict {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CatchFirst value)?  catchFirst,TResult Function( CatchSecond value)?  catchSecond,TResult Function( MissBoth value)?  missBoth,TResult Function( CatchUnknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CatchFirst() when catchFirst != null:
return catchFirst(_that);case CatchSecond() when catchSecond != null:
return catchSecond(_that);case MissBoth() when missBoth != null:
return missBoth(_that);case CatchUnknown() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CatchFirst value)  catchFirst,required TResult Function( CatchSecond value)  catchSecond,required TResult Function( MissBoth value)  missBoth,required TResult Function( CatchUnknown value)  unknown,}){
final _that = this;
switch (_that) {
case CatchFirst():
return catchFirst(_that);case CatchSecond():
return catchSecond(_that);case MissBoth():
return missBoth(_that);case CatchUnknown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CatchFirst value)?  catchFirst,TResult? Function( CatchSecond value)?  catchSecond,TResult? Function( MissBoth value)?  missBoth,TResult? Function( CatchUnknown value)?  unknown,}){
final _that = this;
switch (_that) {
case CatchFirst() when catchFirst != null:
return catchFirst(_that);case CatchSecond() when catchSecond != null:
return catchSecond(_that);case MissBoth() when missBoth != null:
return missBoth(_that);case CatchUnknown() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  catchFirst,TResult Function()?  catchSecond,TResult Function()?  missBoth,TResult Function()?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CatchFirst() when catchFirst != null:
return catchFirst();case CatchSecond() when catchSecond != null:
return catchSecond();case MissBoth() when missBoth != null:
return missBoth();case CatchUnknown() when unknown != null:
return unknown();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  catchFirst,required TResult Function()  catchSecond,required TResult Function()  missBoth,required TResult Function()  unknown,}) {final _that = this;
switch (_that) {
case CatchFirst():
return catchFirst();case CatchSecond():
return catchSecond();case MissBoth():
return missBoth();case CatchUnknown():
return unknown();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  catchFirst,TResult? Function()?  catchSecond,TResult? Function()?  missBoth,TResult? Function()?  unknown,}) {final _that = this;
switch (_that) {
case CatchFirst() when catchFirst != null:
return catchFirst();case CatchSecond() when catchSecond != null:
return catchSecond();case MissBoth() when missBoth != null:
return missBoth();case CatchUnknown() when unknown != null:
return unknown();case _:
  return null;

}
}

}

/// @nodoc


class CatchFirst implements CatchVerdict {
  const CatchFirst();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatchFirst);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CatchVerdict.catchFirst()';
}


}




/// @nodoc


class CatchSecond implements CatchVerdict {
  const CatchSecond();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatchSecond);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CatchVerdict.catchSecond()';
}


}




/// @nodoc


class MissBoth implements CatchVerdict {
  const MissBoth();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MissBoth);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CatchVerdict.missBoth()';
}


}




/// @nodoc


class CatchUnknown implements CatchVerdict {
  const CatchUnknown();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatchUnknown);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CatchVerdict.unknown()';
}


}




// dart format on
