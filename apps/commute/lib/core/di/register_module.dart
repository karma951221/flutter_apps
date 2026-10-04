import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

/// 직접 소유하지 않는 인스턴스 등록.
@module
abstract class RegisterModule {
  @lazySingleton
  LocationGateway get locationGateway => const GeolocatorGateway();
}
