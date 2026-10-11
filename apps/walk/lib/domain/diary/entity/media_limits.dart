abstract final class MediaLimits {
  static const maxItems = 10;
  static const maxVideo = Duration(seconds: 30);
  static const photoLongEdge = 1600;
  static const photoQuality = 85;

  static bool canAdd(int current, int adding) => current + adding <= maxItems;

  static bool videoAllowed(Duration length) => length <= maxVideo;
}
