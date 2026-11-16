// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackupState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupState()';
}


}

/// @nodoc
class $BackupStateCopyWith<$Res>  {
$BackupStateCopyWith(BackupState _, $Res Function(BackupState) __);
}


/// Adds pattern-matching-related methods to [BackupState].
extension BackupStatePatterns on BackupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BackupIdle value)?  idle,TResult Function( BackupWorking value)?  working,TResult Function( BackupExported value)?  exported,TResult Function( BackupPasswordNeeded value)?  passwordNeeded,TResult Function( BackupInspected value)?  inspected,TResult Function( BackupRestored value)?  restored,TResult Function( BackupFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle(_that);case BackupWorking() when working != null:
return working(_that);case BackupExported() when exported != null:
return exported(_that);case BackupPasswordNeeded() when passwordNeeded != null:
return passwordNeeded(_that);case BackupInspected() when inspected != null:
return inspected(_that);case BackupRestored() when restored != null:
return restored(_that);case BackupFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BackupIdle value)  idle,required TResult Function( BackupWorking value)  working,required TResult Function( BackupExported value)  exported,required TResult Function( BackupPasswordNeeded value)  passwordNeeded,required TResult Function( BackupInspected value)  inspected,required TResult Function( BackupRestored value)  restored,required TResult Function( BackupFailed value)  failed,}){
final _that = this;
switch (_that) {
case BackupIdle():
return idle(_that);case BackupWorking():
return working(_that);case BackupExported():
return exported(_that);case BackupPasswordNeeded():
return passwordNeeded(_that);case BackupInspected():
return inspected(_that);case BackupRestored():
return restored(_that);case BackupFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BackupIdle value)?  idle,TResult? Function( BackupWorking value)?  working,TResult? Function( BackupExported value)?  exported,TResult? Function( BackupPasswordNeeded value)?  passwordNeeded,TResult? Function( BackupInspected value)?  inspected,TResult? Function( BackupRestored value)?  restored,TResult? Function( BackupFailed value)?  failed,}){
final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle(_that);case BackupWorking() when working != null:
return working(_that);case BackupExported() when exported != null:
return exported(_that);case BackupPasswordNeeded() when passwordNeeded != null:
return passwordNeeded(_that);case BackupInspected() when inspected != null:
return inspected(_that);case BackupRestored() when restored != null:
return restored(_that);case BackupFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DateTime? lastAt,  int? daysAgo,  bool stale,  bool hasUndo)?  idle,TResult Function( BackupStep step,  double? progress)?  working,TResult Function( int bytes)?  exported,TResult Function( bool wrong)?  passwordNeeded,TResult Function( InspectedBackup backup)?  inspected,TResult Function( Set<RestoreNotice> notices)?  restored,TResult Function( BackupFailure failure,  bool needsRestart)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle(_that.lastAt,_that.daysAgo,_that.stale,_that.hasUndo);case BackupWorking() when working != null:
return working(_that.step,_that.progress);case BackupExported() when exported != null:
return exported(_that.bytes);case BackupPasswordNeeded() when passwordNeeded != null:
return passwordNeeded(_that.wrong);case BackupInspected() when inspected != null:
return inspected(_that.backup);case BackupRestored() when restored != null:
return restored(_that.notices);case BackupFailed() when failed != null:
return failed(_that.failure,_that.needsRestart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DateTime? lastAt,  int? daysAgo,  bool stale,  bool hasUndo)  idle,required TResult Function( BackupStep step,  double? progress)  working,required TResult Function( int bytes)  exported,required TResult Function( bool wrong)  passwordNeeded,required TResult Function( InspectedBackup backup)  inspected,required TResult Function( Set<RestoreNotice> notices)  restored,required TResult Function( BackupFailure failure,  bool needsRestart)  failed,}) {final _that = this;
switch (_that) {
case BackupIdle():
return idle(_that.lastAt,_that.daysAgo,_that.stale,_that.hasUndo);case BackupWorking():
return working(_that.step,_that.progress);case BackupExported():
return exported(_that.bytes);case BackupPasswordNeeded():
return passwordNeeded(_that.wrong);case BackupInspected():
return inspected(_that.backup);case BackupRestored():
return restored(_that.notices);case BackupFailed():
return failed(_that.failure,_that.needsRestart);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DateTime? lastAt,  int? daysAgo,  bool stale,  bool hasUndo)?  idle,TResult? Function( BackupStep step,  double? progress)?  working,TResult? Function( int bytes)?  exported,TResult? Function( bool wrong)?  passwordNeeded,TResult? Function( InspectedBackup backup)?  inspected,TResult? Function( Set<RestoreNotice> notices)?  restored,TResult? Function( BackupFailure failure,  bool needsRestart)?  failed,}) {final _that = this;
switch (_that) {
case BackupIdle() when idle != null:
return idle(_that.lastAt,_that.daysAgo,_that.stale,_that.hasUndo);case BackupWorking() when working != null:
return working(_that.step,_that.progress);case BackupExported() when exported != null:
return exported(_that.bytes);case BackupPasswordNeeded() when passwordNeeded != null:
return passwordNeeded(_that.wrong);case BackupInspected() when inspected != null:
return inspected(_that.backup);case BackupRestored() when restored != null:
return restored(_that.notices);case BackupFailed() when failed != null:
return failed(_that.failure,_that.needsRestart);case _:
  return null;

}
}

}

/// @nodoc


class BackupIdle implements BackupState {
  const BackupIdle({this.lastAt, this.daysAgo, this.stale = false, this.hasUndo = false});
  

 final  DateTime? lastAt;
 final  int? daysAgo;
@JsonKey() final  bool stale;
@JsonKey() final  bool hasUndo;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupIdleCopyWith<BackupIdle> get copyWith => _$BackupIdleCopyWithImpl<BackupIdle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupIdle&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt)&&(identical(other.daysAgo, daysAgo) || other.daysAgo == daysAgo)&&(identical(other.stale, stale) || other.stale == stale)&&(identical(other.hasUndo, hasUndo) || other.hasUndo == hasUndo));
}


@override
int get hashCode => Object.hash(runtimeType,lastAt,daysAgo,stale,hasUndo);

@override
String toString() {
  return 'BackupState.idle(lastAt: $lastAt, daysAgo: $daysAgo, stale: $stale, hasUndo: $hasUndo)';
}


}

/// @nodoc
abstract mixin class $BackupIdleCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupIdleCopyWith(BackupIdle value, $Res Function(BackupIdle) _then) = _$BackupIdleCopyWithImpl;
@useResult
$Res call({
 DateTime? lastAt, int? daysAgo, bool stale, bool hasUndo
});




}
/// @nodoc
class _$BackupIdleCopyWithImpl<$Res>
    implements $BackupIdleCopyWith<$Res> {
  _$BackupIdleCopyWithImpl(this._self, this._then);

  final BackupIdle _self;
  final $Res Function(BackupIdle) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? lastAt = freezed,Object? daysAgo = freezed,Object? stale = null,Object? hasUndo = null,}) {
  return _then(BackupIdle(
lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,daysAgo: freezed == daysAgo ? _self.daysAgo : daysAgo // ignore: cast_nullable_to_non_nullable
as int?,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as bool,hasUndo: null == hasUndo ? _self.hasUndo : hasUndo // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class BackupWorking implements BackupState {
  const BackupWorking(this.step, {this.progress});
  

 final  BackupStep step;
 final  double? progress;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupWorkingCopyWith<BackupWorking> get copyWith => _$BackupWorkingCopyWithImpl<BackupWorking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupWorking&&(identical(other.step, step) || other.step == step)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,step,progress);

@override
String toString() {
  return 'BackupState.working(step: $step, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $BackupWorkingCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupWorkingCopyWith(BackupWorking value, $Res Function(BackupWorking) _then) = _$BackupWorkingCopyWithImpl;
@useResult
$Res call({
 BackupStep step, double? progress
});




}
/// @nodoc
class _$BackupWorkingCopyWithImpl<$Res>
    implements $BackupWorkingCopyWith<$Res> {
  _$BackupWorkingCopyWithImpl(this._self, this._then);

  final BackupWorking _self;
  final $Res Function(BackupWorking) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? step = null,Object? progress = freezed,}) {
  return _then(BackupWorking(
null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as BackupStep,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc


class BackupExported implements BackupState {
  const BackupExported(this.bytes);
  

 final  int bytes;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupExportedCopyWith<BackupExported> get copyWith => _$BackupExportedCopyWithImpl<BackupExported>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupExported&&(identical(other.bytes, bytes) || other.bytes == bytes));
}


@override
int get hashCode => Object.hash(runtimeType,bytes);

@override
String toString() {
  return 'BackupState.exported(bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $BackupExportedCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupExportedCopyWith(BackupExported value, $Res Function(BackupExported) _then) = _$BackupExportedCopyWithImpl;
@useResult
$Res call({
 int bytes
});




}
/// @nodoc
class _$BackupExportedCopyWithImpl<$Res>
    implements $BackupExportedCopyWith<$Res> {
  _$BackupExportedCopyWithImpl(this._self, this._then);

  final BackupExported _self;
  final $Res Function(BackupExported) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,}) {
  return _then(BackupExported(
null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class BackupPasswordNeeded implements BackupState {
  const BackupPasswordNeeded({this.wrong = false});
  

@JsonKey() final  bool wrong;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupPasswordNeededCopyWith<BackupPasswordNeeded> get copyWith => _$BackupPasswordNeededCopyWithImpl<BackupPasswordNeeded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupPasswordNeeded&&(identical(other.wrong, wrong) || other.wrong == wrong));
}


@override
int get hashCode => Object.hash(runtimeType,wrong);

@override
String toString() {
  return 'BackupState.passwordNeeded(wrong: $wrong)';
}


}

/// @nodoc
abstract mixin class $BackupPasswordNeededCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupPasswordNeededCopyWith(BackupPasswordNeeded value, $Res Function(BackupPasswordNeeded) _then) = _$BackupPasswordNeededCopyWithImpl;
@useResult
$Res call({
 bool wrong
});




}
/// @nodoc
class _$BackupPasswordNeededCopyWithImpl<$Res>
    implements $BackupPasswordNeededCopyWith<$Res> {
  _$BackupPasswordNeededCopyWithImpl(this._self, this._then);

  final BackupPasswordNeeded _self;
  final $Res Function(BackupPasswordNeeded) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? wrong = null,}) {
  return _then(BackupPasswordNeeded(
wrong: null == wrong ? _self.wrong : wrong // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class BackupInspected implements BackupState {
  const BackupInspected(this.backup);
  

 final  InspectedBackup backup;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupInspectedCopyWith<BackupInspected> get copyWith => _$BackupInspectedCopyWithImpl<BackupInspected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupInspected&&(identical(other.backup, backup) || other.backup == backup));
}


@override
int get hashCode => Object.hash(runtimeType,backup);

@override
String toString() {
  return 'BackupState.inspected(backup: $backup)';
}


}

/// @nodoc
abstract mixin class $BackupInspectedCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupInspectedCopyWith(BackupInspected value, $Res Function(BackupInspected) _then) = _$BackupInspectedCopyWithImpl;
@useResult
$Res call({
 InspectedBackup backup
});


$InspectedBackupCopyWith<$Res> get backup;

}
/// @nodoc
class _$BackupInspectedCopyWithImpl<$Res>
    implements $BackupInspectedCopyWith<$Res> {
  _$BackupInspectedCopyWithImpl(this._self, this._then);

  final BackupInspected _self;
  final $Res Function(BackupInspected) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? backup = null,}) {
  return _then(BackupInspected(
null == backup ? _self.backup : backup // ignore: cast_nullable_to_non_nullable
as InspectedBackup,
  ));
}

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InspectedBackupCopyWith<$Res> get backup {
  
  return $InspectedBackupCopyWith<$Res>(_self.backup, (value) {
    return _then(_self.copyWith(backup: value));
  });
}
}

/// @nodoc


class BackupRestored implements BackupState {
  const BackupRestored(final  Set<RestoreNotice> notices): _notices = notices;
  

 final  Set<RestoreNotice> _notices;
 Set<RestoreNotice> get notices {
  if (_notices is EqualUnmodifiableSetView) return _notices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_notices);
}


/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupRestoredCopyWith<BackupRestored> get copyWith => _$BackupRestoredCopyWithImpl<BackupRestored>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupRestored&&const DeepCollectionEquality().equals(other._notices, _notices));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_notices));

@override
String toString() {
  return 'BackupState.restored(notices: $notices)';
}


}

/// @nodoc
abstract mixin class $BackupRestoredCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupRestoredCopyWith(BackupRestored value, $Res Function(BackupRestored) _then) = _$BackupRestoredCopyWithImpl;
@useResult
$Res call({
 Set<RestoreNotice> notices
});




}
/// @nodoc
class _$BackupRestoredCopyWithImpl<$Res>
    implements $BackupRestoredCopyWith<$Res> {
  _$BackupRestoredCopyWithImpl(this._self, this._then);

  final BackupRestored _self;
  final $Res Function(BackupRestored) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? notices = null,}) {
  return _then(BackupRestored(
null == notices ? _self._notices : notices // ignore: cast_nullable_to_non_nullable
as Set<RestoreNotice>,
  ));
}


}

/// @nodoc


class BackupFailed implements BackupState {
  const BackupFailed(this.failure, {this.needsRestart = false});
  

 final  BackupFailure failure;
@JsonKey() final  bool needsRestart;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupFailedCopyWith<BackupFailed> get copyWith => _$BackupFailedCopyWithImpl<BackupFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupFailed&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.needsRestart, needsRestart) || other.needsRestart == needsRestart));
}


@override
int get hashCode => Object.hash(runtimeType,failure,needsRestart);

@override
String toString() {
  return 'BackupState.failed(failure: $failure, needsRestart: $needsRestart)';
}


}

/// @nodoc
abstract mixin class $BackupFailedCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupFailedCopyWith(BackupFailed value, $Res Function(BackupFailed) _then) = _$BackupFailedCopyWithImpl;
@useResult
$Res call({
 BackupFailure failure, bool needsRestart
});




}
/// @nodoc
class _$BackupFailedCopyWithImpl<$Res>
    implements $BackupFailedCopyWith<$Res> {
  _$BackupFailedCopyWithImpl(this._self, this._then);

  final BackupFailed _self;
  final $Res Function(BackupFailed) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? needsRestart = null,}) {
  return _then(BackupFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as BackupFailure,needsRestart: null == needsRestart ? _self.needsRestart : needsRestart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
