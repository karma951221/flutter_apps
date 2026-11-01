// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_model_choice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModelsRefresh {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelsRefresh);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelsRefresh()';
}


}

/// @nodoc
class $ModelsRefreshCopyWith<$Res>  {
$ModelsRefreshCopyWith(ModelsRefresh _, $Res Function(ModelsRefresh) __);
}


/// Adds pattern-matching-related methods to [ModelsRefresh].
extension ModelsRefreshPatterns on ModelsRefresh {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ModelsSkipped value)?  skipped,TResult Function( ModelsUpdated value)?  updated,TResult Function( ModelsInvalidKey value)?  invalidKey,TResult Function( ModelsUnreachable value)?  unreachable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ModelsSkipped() when skipped != null:
return skipped(_that);case ModelsUpdated() when updated != null:
return updated(_that);case ModelsInvalidKey() when invalidKey != null:
return invalidKey(_that);case ModelsUnreachable() when unreachable != null:
return unreachable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ModelsSkipped value)  skipped,required TResult Function( ModelsUpdated value)  updated,required TResult Function( ModelsInvalidKey value)  invalidKey,required TResult Function( ModelsUnreachable value)  unreachable,}){
final _that = this;
switch (_that) {
case ModelsSkipped():
return skipped(_that);case ModelsUpdated():
return updated(_that);case ModelsInvalidKey():
return invalidKey(_that);case ModelsUnreachable():
return unreachable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ModelsSkipped value)?  skipped,TResult? Function( ModelsUpdated value)?  updated,TResult? Function( ModelsInvalidKey value)?  invalidKey,TResult? Function( ModelsUnreachable value)?  unreachable,}){
final _that = this;
switch (_that) {
case ModelsSkipped() when skipped != null:
return skipped(_that);case ModelsUpdated() when updated != null:
return updated(_that);case ModelsInvalidKey() when invalidKey != null:
return invalidKey(_that);case ModelsUnreachable() when unreachable != null:
return unreachable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  skipped,TResult Function( bool replacedSelection)?  updated,TResult Function()?  invalidKey,TResult Function()?  unreachable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ModelsSkipped() when skipped != null:
return skipped();case ModelsUpdated() when updated != null:
return updated(_that.replacedSelection);case ModelsInvalidKey() when invalidKey != null:
return invalidKey();case ModelsUnreachable() when unreachable != null:
return unreachable();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  skipped,required TResult Function( bool replacedSelection)  updated,required TResult Function()  invalidKey,required TResult Function()  unreachable,}) {final _that = this;
switch (_that) {
case ModelsSkipped():
return skipped();case ModelsUpdated():
return updated(_that.replacedSelection);case ModelsInvalidKey():
return invalidKey();case ModelsUnreachable():
return unreachable();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  skipped,TResult? Function( bool replacedSelection)?  updated,TResult? Function()?  invalidKey,TResult? Function()?  unreachable,}) {final _that = this;
switch (_that) {
case ModelsSkipped() when skipped != null:
return skipped();case ModelsUpdated() when updated != null:
return updated(_that.replacedSelection);case ModelsInvalidKey() when invalidKey != null:
return invalidKey();case ModelsUnreachable() when unreachable != null:
return unreachable();case _:
  return null;

}
}

}

/// @nodoc


class ModelsSkipped implements ModelsRefresh {
  const ModelsSkipped();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelsSkipped);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelsRefresh.skipped()';
}


}




/// @nodoc


class ModelsUpdated implements ModelsRefresh {
  const ModelsUpdated({required this.replacedSelection});
  

 final  bool replacedSelection;

/// Create a copy of ModelsRefresh
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelsUpdatedCopyWith<ModelsUpdated> get copyWith => _$ModelsUpdatedCopyWithImpl<ModelsUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelsUpdated&&(identical(other.replacedSelection, replacedSelection) || other.replacedSelection == replacedSelection));
}


@override
int get hashCode => Object.hash(runtimeType,replacedSelection);

@override
String toString() {
  return 'ModelsRefresh.updated(replacedSelection: $replacedSelection)';
}


}

/// @nodoc
abstract mixin class $ModelsUpdatedCopyWith<$Res> implements $ModelsRefreshCopyWith<$Res> {
  factory $ModelsUpdatedCopyWith(ModelsUpdated value, $Res Function(ModelsUpdated) _then) = _$ModelsUpdatedCopyWithImpl;
@useResult
$Res call({
 bool replacedSelection
});




}
/// @nodoc
class _$ModelsUpdatedCopyWithImpl<$Res>
    implements $ModelsUpdatedCopyWith<$Res> {
  _$ModelsUpdatedCopyWithImpl(this._self, this._then);

  final ModelsUpdated _self;
  final $Res Function(ModelsUpdated) _then;

/// Create a copy of ModelsRefresh
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? replacedSelection = null,}) {
  return _then(ModelsUpdated(
replacedSelection: null == replacedSelection ? _self.replacedSelection : replacedSelection // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ModelsInvalidKey implements ModelsRefresh {
  const ModelsInvalidKey();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelsInvalidKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelsRefresh.invalidKey()';
}


}




/// @nodoc


class ModelsUnreachable implements ModelsRefresh {
  const ModelsUnreachable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelsUnreachable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModelsRefresh.unreachable()';
}


}




// dart format on
