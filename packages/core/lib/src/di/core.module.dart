// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;
import 'package:uuid/uuid.dart' as _i706;

import '../id/id_generator.dart' as _i1000;
import '../media/image_picker_service.dart' as _i350;
import '../media/image_storage.dart' as _i1040;
import '../media/supabase_image_storage.dart' as _i571;
import 'register_module.dart' as _i291;

class CorePackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) async {
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i706.Uuid>(() => registerModule.uuid);
    gh.lazySingleton<_i350.ImagePickerService>(
        () => _i350.ImagePickerService());
    gh.lazySingleton<_i1000.IdGenerator>(
        () => _i1000.IdGenerator(gh<_i706.Uuid>()));
    gh.lazySingleton<_i1040.ImageStorage>(
        () => _i571.SupabaseImageStorage(gh<_i454.SupabaseClient>()));
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
