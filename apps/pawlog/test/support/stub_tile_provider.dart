import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

// 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// 네트워크를 타지 않고 1x1 PNG 를 타일로 돌려준다.
class StubTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_png);
}
