// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wiki_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WikiNote {

 int get id; String get title; String get summary; String get body; String? get sourceConversationId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of WikiNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiNoteCopyWith<WikiNote> get copyWith => _$WikiNoteCopyWithImpl<WikiNote>(this as WikiNote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiNote&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.body, body) || other.body == body)&&(identical(other.sourceConversationId, sourceConversationId) || other.sourceConversationId == sourceConversationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,summary,body,sourceConversationId,createdAt,updatedAt);



}

/// @nodoc
abstract mixin class $WikiNoteCopyWith<$Res>  {
  factory $WikiNoteCopyWith(WikiNote value, $Res Function(WikiNote) _then) = _$WikiNoteCopyWithImpl;
@useResult
$Res call({
 int id, String title, String summary, String body, String? sourceConversationId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$WikiNoteCopyWithImpl<$Res>
    implements $WikiNoteCopyWith<$Res> {
  _$WikiNoteCopyWithImpl(this._self, this._then);

  final WikiNote _self;
  final $Res Function(WikiNote) _then;

/// Create a copy of WikiNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? body = null,Object? sourceConversationId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(WikiNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sourceConversationId: freezed == sourceConversationId ? _self.sourceConversationId : sourceConversationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WikiNote].
extension WikiNotePatterns on WikiNote {
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

/// @nodoc
mixin _$WikiNoteDraft {

 String get title; String get summary; String get body; String? get sourceConversationId;
/// Create a copy of WikiNoteDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiNoteDraftCopyWith<WikiNoteDraft> get copyWith => _$WikiNoteDraftCopyWithImpl<WikiNoteDraft>(this as WikiNoteDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiNoteDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.body, body) || other.body == body)&&(identical(other.sourceConversationId, sourceConversationId) || other.sourceConversationId == sourceConversationId));
}


@override
int get hashCode => Object.hash(runtimeType,title,summary,body,sourceConversationId);



}

/// @nodoc
abstract mixin class $WikiNoteDraftCopyWith<$Res>  {
  factory $WikiNoteDraftCopyWith(WikiNoteDraft value, $Res Function(WikiNoteDraft) _then) = _$WikiNoteDraftCopyWithImpl;
@useResult
$Res call({
 String title, String summary, String body, String? sourceConversationId
});




}
/// @nodoc
class _$WikiNoteDraftCopyWithImpl<$Res>
    implements $WikiNoteDraftCopyWith<$Res> {
  _$WikiNoteDraftCopyWithImpl(this._self, this._then);

  final WikiNoteDraft _self;
  final $Res Function(WikiNoteDraft) _then;

/// Create a copy of WikiNoteDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? summary = null,Object? body = null,Object? sourceConversationId = freezed,}) {
  return _then(WikiNoteDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sourceConversationId: freezed == sourceConversationId ? _self.sourceConversationId : sourceConversationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WikiNoteDraft].
extension WikiNoteDraftPatterns on WikiNoteDraft {
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

/// @nodoc
mixin _$WikiCandidate {

 String get title; String get summary; String get body;
/// Create a copy of WikiCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiCandidateCopyWith<WikiCandidate> get copyWith => _$WikiCandidateCopyWithImpl<WikiCandidate>(this as WikiCandidate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiCandidate&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,title,summary,body);



}

/// @nodoc
abstract mixin class $WikiCandidateCopyWith<$Res>  {
  factory $WikiCandidateCopyWith(WikiCandidate value, $Res Function(WikiCandidate) _then) = _$WikiCandidateCopyWithImpl;
@useResult
$Res call({
 String title, String summary, String body
});




}
/// @nodoc
class _$WikiCandidateCopyWithImpl<$Res>
    implements $WikiCandidateCopyWith<$Res> {
  _$WikiCandidateCopyWithImpl(this._self, this._then);

  final WikiCandidate _self;
  final $Res Function(WikiCandidate) _then;

/// Create a copy of WikiCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? summary = null,Object? body = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WikiCandidate].
extension WikiCandidatePatterns on WikiCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WikiCreateCandidate value)?  create,TResult Function( WikiUpdateCandidate value)?  update,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WikiCreateCandidate() when create != null:
return create(_that);case WikiUpdateCandidate() when update != null:
return update(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WikiCreateCandidate value)  create,required TResult Function( WikiUpdateCandidate value)  update,}){
final _that = this;
switch (_that) {
case WikiCreateCandidate():
return create(_that);case WikiUpdateCandidate():
return update(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WikiCreateCandidate value)?  create,TResult? Function( WikiUpdateCandidate value)?  update,}){
final _that = this;
switch (_that) {
case WikiCreateCandidate() when create != null:
return create(_that);case WikiUpdateCandidate() when update != null:
return update(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String title,  String summary,  String body)?  create,TResult Function( int id,  String title,  String summary,  String body)?  update,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WikiCreateCandidate() when create != null:
return create(_that.title,_that.summary,_that.body);case WikiUpdateCandidate() when update != null:
return update(_that.id,_that.title,_that.summary,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String title,  String summary,  String body)  create,required TResult Function( int id,  String title,  String summary,  String body)  update,}) {final _that = this;
switch (_that) {
case WikiCreateCandidate():
return create(_that.title,_that.summary,_that.body);case WikiUpdateCandidate():
return update(_that.id,_that.title,_that.summary,_that.body);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String title,  String summary,  String body)?  create,TResult? Function( int id,  String title,  String summary,  String body)?  update,}) {final _that = this;
switch (_that) {
case WikiCreateCandidate() when create != null:
return create(_that.title,_that.summary,_that.body);case WikiUpdateCandidate() when update != null:
return update(_that.id,_that.title,_that.summary,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class WikiCreateCandidate extends WikiCandidate {
  const WikiCreateCandidate({required this.title, required this.summary, required this.body}): super._();
  

@override final  String title;
@override final  String summary;
@override final  String body;

/// Create a copy of WikiCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiCreateCandidateCopyWith<WikiCreateCandidate> get copyWith => _$WikiCreateCandidateCopyWithImpl<WikiCreateCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiCreateCandidate&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,title,summary,body);



}

/// @nodoc
abstract mixin class $WikiCreateCandidateCopyWith<$Res> implements $WikiCandidateCopyWith<$Res> {
  factory $WikiCreateCandidateCopyWith(WikiCreateCandidate value, $Res Function(WikiCreateCandidate) _then) = _$WikiCreateCandidateCopyWithImpl;
@override @useResult
$Res call({
 String title, String summary, String body
});




}
/// @nodoc
class _$WikiCreateCandidateCopyWithImpl<$Res>
    implements $WikiCreateCandidateCopyWith<$Res> {
  _$WikiCreateCandidateCopyWithImpl(this._self, this._then);

  final WikiCreateCandidate _self;
  final $Res Function(WikiCreateCandidate) _then;

/// Create a copy of WikiCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? summary = null,Object? body = null,}) {
  return _then(WikiCreateCandidate(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WikiUpdateCandidate extends WikiCandidate {
  const WikiUpdateCandidate({required this.id, required this.title, required this.summary, required this.body}): super._();
  

 final  int id;
@override final  String title;
@override final  String summary;
@override final  String body;

/// Create a copy of WikiCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiUpdateCandidateCopyWith<WikiUpdateCandidate> get copyWith => _$WikiUpdateCandidateCopyWithImpl<WikiUpdateCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiUpdateCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,summary,body);



}

/// @nodoc
abstract mixin class $WikiUpdateCandidateCopyWith<$Res> implements $WikiCandidateCopyWith<$Res> {
  factory $WikiUpdateCandidateCopyWith(WikiUpdateCandidate value, $Res Function(WikiUpdateCandidate) _then) = _$WikiUpdateCandidateCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String summary, String body
});




}
/// @nodoc
class _$WikiUpdateCandidateCopyWithImpl<$Res>
    implements $WikiUpdateCandidateCopyWith<$Res> {
  _$WikiUpdateCandidateCopyWithImpl(this._self, this._then);

  final WikiUpdateCandidate _self;
  final $Res Function(WikiUpdateCandidate) _then;

/// Create a copy of WikiCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? body = null,}) {
  return _then(WikiUpdateCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$WikiLink {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiLink);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WikiLink()';
}


}

/// @nodoc
class $WikiLinkCopyWith<$Res>  {
$WikiLinkCopyWith(WikiLink _, $Res Function(WikiLink) __);
}


/// Adds pattern-matching-related methods to [WikiLink].
extension WikiLinkPatterns on WikiLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WikiNoteLink value)?  note,TResult Function( WikiDiaryLink value)?  diary,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WikiNoteLink() when note != null:
return note(_that);case WikiDiaryLink() when diary != null:
return diary(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WikiNoteLink value)  note,required TResult Function( WikiDiaryLink value)  diary,}){
final _that = this;
switch (_that) {
case WikiNoteLink():
return note(_that);case WikiDiaryLink():
return diary(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WikiNoteLink value)?  note,TResult? Function( WikiDiaryLink value)?  diary,}){
final _that = this;
switch (_that) {
case WikiNoteLink() when note != null:
return note(_that);case WikiDiaryLink() when diary != null:
return diary(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int id)?  note,TResult Function( String entryId)?  diary,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WikiNoteLink() when note != null:
return note(_that.id);case WikiDiaryLink() when diary != null:
return diary(_that.entryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int id)  note,required TResult Function( String entryId)  diary,}) {final _that = this;
switch (_that) {
case WikiNoteLink():
return note(_that.id);case WikiDiaryLink():
return diary(_that.entryId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int id)?  note,TResult? Function( String entryId)?  diary,}) {final _that = this;
switch (_that) {
case WikiNoteLink() when note != null:
return note(_that.id);case WikiDiaryLink() when diary != null:
return diary(_that.entryId);case _:
  return null;

}
}

}

/// @nodoc


class WikiNoteLink implements WikiLink {
  const WikiNoteLink(this.id);
  

 final  int id;

/// Create a copy of WikiLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiNoteLinkCopyWith<WikiNoteLink> get copyWith => _$WikiNoteLinkCopyWithImpl<WikiNoteLink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiNoteLink&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'WikiLink.note(id: $id)';
}


}

/// @nodoc
abstract mixin class $WikiNoteLinkCopyWith<$Res> implements $WikiLinkCopyWith<$Res> {
  factory $WikiNoteLinkCopyWith(WikiNoteLink value, $Res Function(WikiNoteLink) _then) = _$WikiNoteLinkCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class _$WikiNoteLinkCopyWithImpl<$Res>
    implements $WikiNoteLinkCopyWith<$Res> {
  _$WikiNoteLinkCopyWithImpl(this._self, this._then);

  final WikiNoteLink _self;
  final $Res Function(WikiNoteLink) _then;

/// Create a copy of WikiLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(WikiNoteLink(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class WikiDiaryLink implements WikiLink {
  const WikiDiaryLink(this.entryId);
  

 final  String entryId;

/// Create a copy of WikiLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiDiaryLinkCopyWith<WikiDiaryLink> get copyWith => _$WikiDiaryLinkCopyWithImpl<WikiDiaryLink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiDiaryLink&&(identical(other.entryId, entryId) || other.entryId == entryId));
}


@override
int get hashCode => Object.hash(runtimeType,entryId);

@override
String toString() {
  return 'WikiLink.diary(entryId: $entryId)';
}


}

/// @nodoc
abstract mixin class $WikiDiaryLinkCopyWith<$Res> implements $WikiLinkCopyWith<$Res> {
  factory $WikiDiaryLinkCopyWith(WikiDiaryLink value, $Res Function(WikiDiaryLink) _then) = _$WikiDiaryLinkCopyWithImpl;
@useResult
$Res call({
 String entryId
});




}
/// @nodoc
class _$WikiDiaryLinkCopyWithImpl<$Res>
    implements $WikiDiaryLinkCopyWith<$Res> {
  _$WikiDiaryLinkCopyWithImpl(this._self, this._then);

  final WikiDiaryLink _self;
  final $Res Function(WikiDiaryLink) _then;

/// Create a copy of WikiLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entryId = null,}) {
  return _then(WikiDiaryLink(
null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$WikiSegment {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiSegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WikiSegment()';
}


}

/// @nodoc
class $WikiSegmentCopyWith<$Res>  {
$WikiSegmentCopyWith(WikiSegment _, $Res Function(WikiSegment) __);
}


/// Adds pattern-matching-related methods to [WikiSegment].
extension WikiSegmentPatterns on WikiSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WikiTextSegment value)?  text,TResult Function( WikiLinkSegment value)?  link,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WikiTextSegment() when text != null:
return text(_that);case WikiLinkSegment() when link != null:
return link(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WikiTextSegment value)  text,required TResult Function( WikiLinkSegment value)  link,}){
final _that = this;
switch (_that) {
case WikiTextSegment():
return text(_that);case WikiLinkSegment():
return link(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WikiTextSegment value)?  text,TResult? Function( WikiLinkSegment value)?  link,}){
final _that = this;
switch (_that) {
case WikiTextSegment() when text != null:
return text(_that);case WikiLinkSegment() when link != null:
return link(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  text,TResult Function( WikiLink link,  String raw)?  link,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WikiTextSegment() when text != null:
return text(_that.text);case WikiLinkSegment() when link != null:
return link(_that.link,_that.raw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  text,required TResult Function( WikiLink link,  String raw)  link,}) {final _that = this;
switch (_that) {
case WikiTextSegment():
return text(_that.text);case WikiLinkSegment():
return link(_that.link,_that.raw);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  text,TResult? Function( WikiLink link,  String raw)?  link,}) {final _that = this;
switch (_that) {
case WikiTextSegment() when text != null:
return text(_that.text);case WikiLinkSegment() when link != null:
return link(_that.link,_that.raw);case _:
  return null;

}
}

}

/// @nodoc


class WikiTextSegment implements WikiSegment {
  const WikiTextSegment(this.text);
  

 final  String text;

/// Create a copy of WikiSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiTextSegmentCopyWith<WikiTextSegment> get copyWith => _$WikiTextSegmentCopyWithImpl<WikiTextSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiTextSegment&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'WikiSegment.text(text: $text)';
}


}

/// @nodoc
abstract mixin class $WikiTextSegmentCopyWith<$Res> implements $WikiSegmentCopyWith<$Res> {
  factory $WikiTextSegmentCopyWith(WikiTextSegment value, $Res Function(WikiTextSegment) _then) = _$WikiTextSegmentCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$WikiTextSegmentCopyWithImpl<$Res>
    implements $WikiTextSegmentCopyWith<$Res> {
  _$WikiTextSegmentCopyWithImpl(this._self, this._then);

  final WikiTextSegment _self;
  final $Res Function(WikiTextSegment) _then;

/// Create a copy of WikiSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(WikiTextSegment(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WikiLinkSegment implements WikiSegment {
  const WikiLinkSegment(this.link, this.raw);
  

 final  WikiLink link;
 final  String raw;

/// Create a copy of WikiSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiLinkSegmentCopyWith<WikiLinkSegment> get copyWith => _$WikiLinkSegmentCopyWithImpl<WikiLinkSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiLinkSegment&&(identical(other.link, link) || other.link == link)&&(identical(other.raw, raw) || other.raw == raw));
}


@override
int get hashCode => Object.hash(runtimeType,link,raw);

@override
String toString() {
  return 'WikiSegment.link(link: $link, raw: $raw)';
}


}

/// @nodoc
abstract mixin class $WikiLinkSegmentCopyWith<$Res> implements $WikiSegmentCopyWith<$Res> {
  factory $WikiLinkSegmentCopyWith(WikiLinkSegment value, $Res Function(WikiLinkSegment) _then) = _$WikiLinkSegmentCopyWithImpl;
@useResult
$Res call({
 WikiLink link, String raw
});


$WikiLinkCopyWith<$Res> get link;

}
/// @nodoc
class _$WikiLinkSegmentCopyWithImpl<$Res>
    implements $WikiLinkSegmentCopyWith<$Res> {
  _$WikiLinkSegmentCopyWithImpl(this._self, this._then);

  final WikiLinkSegment _self;
  final $Res Function(WikiLinkSegment) _then;

/// Create a copy of WikiSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? link = null,Object? raw = null,}) {
  return _then(WikiLinkSegment(
null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as WikiLink,null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of WikiSegment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WikiLinkCopyWith<$Res> get link {
  
  return $WikiLinkCopyWith<$Res>(_self.link, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}

// dart format on
