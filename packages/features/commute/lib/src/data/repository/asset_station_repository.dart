import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/geo_point.dart';
import '../../domain/entity/station.dart';
import '../../domain/repository/station_repository.dart';

@LazySingleton(as: StationRepository)
class AssetStationRepository implements StationRepository {
  AssetStationRepository() : _bundle = rootBundle;

  AssetStationRepository.withBundle(this._bundle);

  static const _assetPath = 'packages/feature_commute/assets/stations.json';

  final AssetBundle _bundle;
  Future<List<Station>>? _stations;

  @override
  Future<Result<List<Station>>> search(String query) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return const Ok([]);
    try {
      final stations = await _loadStations();
      return Ok([
        for (final station in stations)
          if (_normalize(station.name).contains(normalizedQuery)) station,
      ]);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<Station?>> findById(String id) async {
    try {
      final stations = await _loadStations();
      for (final station in stations) {
        if (station.id == id) return Ok(station);
      }
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  Future<List<Station>> _loadStations() => _stations ??= _readStations();

  Future<List<Station>> _readStations() async {
    final value = jsonDecode(await _bundle.loadString(_assetPath));
    if (value is! List) throw const FormatException('역 목록은 배열이어야 합니다');
    return [
      for (final item in value)
        if (item case {
          'id': final String id,
          'name': final String name,
          'lines': final List<dynamic> lines,
          'lat': final num lat,
          'lng': final num lng,
        })
          Station(
            id: id,
            name: name,
            lines: lines.cast<String>(),
            location: GeoPoint(lat: lat.toDouble(), lng: lng.toDouble()),
          )
        else
          throw const FormatException('역 데이터 형식이 올바르지 않습니다'),
    ];
  }

  String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
