// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_edit_form.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkEditForm {

 List<Dog> get dogs; Set<String> get selectedDogIds; String get memo; List<String> get photoPaths; WalkSession? get session; Walk? get existing;
/// Create a copy of WalkEditForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkEditFormCopyWith<WalkEditForm> get copyWith => _$WalkEditFormCopyWithImpl<WalkEditForm>(this as WalkEditForm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkEditForm&&const DeepCollectionEquality().equals(other.dogs, dogs)&&const DeepCollectionEquality().equals(other.selectedDogIds, selectedDogIds)&&(identical(other.memo, memo) || other.memo == memo)&&const DeepCollectionEquality().equals(other.photoPaths, photoPaths)&&(identical(other.session, session) || other.session == session)&&(identical(other.existing, existing) || other.existing == existing));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(dogs),const DeepCollectionEquality().hash(selectedDogIds),memo,const DeepCollectionEquality().hash(photoPaths),session,existing);

@override
String toString() {
  return 'WalkEditForm(dogs: $dogs, selectedDogIds: $selectedDogIds, memo: $memo, photoPaths: $photoPaths, session: $session, existing: $existing)';
}


}

/// @nodoc
abstract mixin class $WalkEditFormCopyWith<$Res>  {
  factory $WalkEditFormCopyWith(WalkEditForm value, $Res Function(WalkEditForm) _then) = _$WalkEditFormCopyWithImpl;
@useResult
$Res call({
 List<Dog> dogs, Set<String> selectedDogIds, String memo, List<String> photoPaths, WalkSession? session, Walk? existing
});




}
/// @nodoc
class _$WalkEditFormCopyWithImpl<$Res>
    implements $WalkEditFormCopyWith<$Res> {
  _$WalkEditFormCopyWithImpl(this._self, this._then);

  final WalkEditForm _self;
  final $Res Function(WalkEditForm) _then;

/// Create a copy of WalkEditForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dogs = null,Object? selectedDogIds = null,Object? memo = null,Object? photoPaths = null,Object? session = freezed,Object? existing = freezed,}) {
  return _then(WalkEditForm(
dogs: null == dogs ? _self.dogs : dogs // ignore: cast_nullable_to_non_nullable
as List<Dog>,selectedDogIds: null == selectedDogIds ? _self.selectedDogIds : selectedDogIds // ignore: cast_nullable_to_non_nullable
as Set<String>,memo: null == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String,photoPaths: null == photoPaths ? _self.photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WalkSession?,existing: freezed == existing ? _self.existing : existing // ignore: cast_nullable_to_non_nullable
as Walk?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkEditForm].
extension WalkEditFormPatterns on WalkEditForm {
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
