/// Đường dẫn trong app (design/docs/navigation.json).
abstract final class Routes {
  static const connect = '/connect';
  static const dashboard = '/dashboard';
  static const settings = '/settings';
  static const device = '/device';

  /// Cài Wi-Fi: mở từ Kết nối hoặc Thiết bị, nằm trên khung tab.
  static const wifiSetupName = 'wifi';
  static const connectWifi = '$connect/$wifiSetupName';
  static const deviceWifi = '$device/$wifiSetupName';

  /// Ba tab dưới, theo thứ tự.
  static const tabs = [dashboard, settings, device];
}
