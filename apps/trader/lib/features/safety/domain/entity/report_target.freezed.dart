// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReportTarget {

 String get id;
/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportTargetCopyWith<ReportTarget> get copyWith => _$ReportTargetCopyWithImpl<ReportTarget>(this as ReportTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReportTarget(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReportTargetCopyWith<$Res>  {
  factory $ReportTargetCopyWith(ReportTarget value, $Res Function(ReportTarget) _then) = _$ReportTargetCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReportTargetCopyWithImpl<$Res>
    implements $ReportTargetCopyWith<$Res> {
  _$ReportTargetCopyWithImpl(this._self, this._then);

  final ReportTarget _self;
  final $Res Function(ReportTarget) _then;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportTarget].
extension ReportTargetPatterns on ReportTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReportPostTarget value)?  post,TResult Function( ReportCommentTarget value)?  comment,TResult Function( ReportUserTarget value)?  user,TResult Function( ReportChatMessageTarget value)?  chatMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReportPostTarget() when post != null:
return post(_that);case ReportCommentTarget() when comment != null:
return comment(_that);case ReportUserTarget() when user != null:
return user(_that);case ReportChatMessageTarget() when chatMessage != null:
return chatMessage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReportPostTarget value)  post,required TResult Function( ReportCommentTarget value)  comment,required TResult Function( ReportUserTarget value)  user,required TResult Function( ReportChatMessageTarget value)  chatMessage,}){
final _that = this;
switch (_that) {
case ReportPostTarget():
return post(_that);case ReportCommentTarget():
return comment(_that);case ReportUserTarget():
return user(_that);case ReportChatMessageTarget():
return chatMessage(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReportPostTarget value)?  post,TResult? Function( ReportCommentTarget value)?  comment,TResult? Function( ReportUserTarget value)?  user,TResult? Function( ReportChatMessageTarget value)?  chatMessage,}){
final _that = this;
switch (_that) {
case ReportPostTarget() when post != null:
return post(_that);case ReportCommentTarget() when comment != null:
return comment(_that);case ReportUserTarget() when user != null:
return user(_that);case ReportChatMessageTarget() when chatMessage != null:
return chatMessage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id)?  post,TResult Function( String id)?  comment,TResult Function( String id)?  user,TResult Function( String id)?  chatMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReportPostTarget() when post != null:
return post(_that.id);case ReportCommentTarget() when comment != null:
return comment(_that.id);case ReportUserTarget() when user != null:
return user(_that.id);case ReportChatMessageTarget() when chatMessage != null:
return chatMessage(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id)  post,required TResult Function( String id)  comment,required TResult Function( String id)  user,required TResult Function( String id)  chatMessage,}) {final _that = this;
switch (_that) {
case ReportPostTarget():
return post(_that.id);case ReportCommentTarget():
return comment(_that.id);case ReportUserTarget():
return user(_that.id);case ReportChatMessageTarget():
return chatMessage(_that.id);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id)?  post,TResult? Function( String id)?  comment,TResult? Function( String id)?  user,TResult? Function( String id)?  chatMessage,}) {final _that = this;
switch (_that) {
case ReportPostTarget() when post != null:
return post(_that.id);case ReportCommentTarget() when comment != null:
return comment(_that.id);case ReportUserTarget() when user != null:
return user(_that.id);case ReportChatMessageTarget() when chatMessage != null:
return chatMessage(_that.id);case _:
  return null;

}
}

}

/// @nodoc


class ReportPostTarget implements ReportTarget {
  const ReportPostTarget(this.id);
  

@override final  String id;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportPostTargetCopyWith<ReportPostTarget> get copyWith => _$ReportPostTargetCopyWithImpl<ReportPostTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportPostTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReportTarget.post(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReportPostTargetCopyWith<$Res> implements $ReportTargetCopyWith<$Res> {
  factory $ReportPostTargetCopyWith(ReportPostTarget value, $Res Function(ReportPostTarget) _then) = _$ReportPostTargetCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReportPostTargetCopyWithImpl<$Res>
    implements $ReportPostTargetCopyWith<$Res> {
  _$ReportPostTargetCopyWithImpl(this._self, this._then);

  final ReportPostTarget _self;
  final $Res Function(ReportPostTarget) _then;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ReportPostTarget(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReportCommentTarget implements ReportTarget {
  const ReportCommentTarget(this.id);
  

@override final  String id;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportCommentTargetCopyWith<ReportCommentTarget> get copyWith => _$ReportCommentTargetCopyWithImpl<ReportCommentTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportCommentTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReportTarget.comment(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReportCommentTargetCopyWith<$Res> implements $ReportTargetCopyWith<$Res> {
  factory $ReportCommentTargetCopyWith(ReportCommentTarget value, $Res Function(ReportCommentTarget) _then) = _$ReportCommentTargetCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReportCommentTargetCopyWithImpl<$Res>
    implements $ReportCommentTargetCopyWith<$Res> {
  _$ReportCommentTargetCopyWithImpl(this._self, this._then);

  final ReportCommentTarget _self;
  final $Res Function(ReportCommentTarget) _then;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ReportCommentTarget(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReportUserTarget implements ReportTarget {
  const ReportUserTarget(this.id);
  

@override final  String id;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportUserTargetCopyWith<ReportUserTarget> get copyWith => _$ReportUserTargetCopyWithImpl<ReportUserTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportUserTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReportTarget.user(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReportUserTargetCopyWith<$Res> implements $ReportTargetCopyWith<$Res> {
  factory $ReportUserTargetCopyWith(ReportUserTarget value, $Res Function(ReportUserTarget) _then) = _$ReportUserTargetCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReportUserTargetCopyWithImpl<$Res>
    implements $ReportUserTargetCopyWith<$Res> {
  _$ReportUserTargetCopyWithImpl(this._self, this._then);

  final ReportUserTarget _self;
  final $Res Function(ReportUserTarget) _then;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ReportUserTarget(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReportChatMessageTarget implements ReportTarget {
  const ReportChatMessageTarget(this.id);
  

@override final  String id;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportChatMessageTargetCopyWith<ReportChatMessageTarget> get copyWith => _$ReportChatMessageTargetCopyWithImpl<ReportChatMessageTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportChatMessageTarget&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ReportTarget.chatMessage(id: $id)';
}


}

/// @nodoc
abstract mixin class $ReportChatMessageTargetCopyWith<$Res> implements $ReportTargetCopyWith<$Res> {
  factory $ReportChatMessageTargetCopyWith(ReportChatMessageTarget value, $Res Function(ReportChatMessageTarget) _then) = _$ReportChatMessageTargetCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ReportChatMessageTargetCopyWithImpl<$Res>
    implements $ReportChatMessageTargetCopyWith<$Res> {
  _$ReportChatMessageTargetCopyWithImpl(this._self, this._then);

  final ReportChatMessageTarget _self;
  final $Res Function(ReportChatMessageTarget) _then;

/// Create a copy of ReportTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ReportChatMessageTarget(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
