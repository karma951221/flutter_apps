abstract final class CommutePaths {
  static const home = '/';
  static const settings = '/settings';
}

class SettingsRedirect {
  SettingsRedirect({required bool settingsComplete})
    : _settingsComplete = settingsComplete;

  bool _settingsComplete;

  String? resolve(String location) {
    if (!_settingsComplete && location != CommutePaths.settings) {
      return CommutePaths.settings;
    }
    return null;
  }

  void markComplete() => _settingsComplete = true;
}
