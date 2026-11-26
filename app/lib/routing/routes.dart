import 'dart:typed_data';

import '../domain/models/device_photo.dart';

/// What the Ảnh tab hands PhotoCrop: the picked image file and the device's limits.
typedef PhotoCropArgs = ({Uint8List image, PhotoInfo info});

/// Đường dẫn trong app (design/docs/navigation.json).
abstract final class Routes {
  static const connect = '/connect';

  /// Tab 1: Điều khiển (remote của thiết bị, 2026-11-26.5).
  static const control = '/control';

  /// Số liệu: màn phụ đẩy từ Điều khiển, ngoài khung tab; `?tab=<skill>` = tab mở đầu (tab của kênh đang hiện).
  static const detailsName = 'details';
  static const dashboard = '$control/$detailsName';

  /// Số liệu mở ở tab [skill] (null = tab đầu).
  static String detailsAt(String? skill) => skill == null ? dashboard : '$dashboard?tab=$skill';
  static const skills = '/skills';
  static const settings = '/settings';
  static const device = '/device';

  /// Cài Wi-Fi: mở từ Kết nối hoặc Thiết bị, nằm trên khung tab.
  static const wifiSetupName = 'wifi';
  static const connectWifi = '$connect/$wifiSetupName';
  static const deviceWifi = '$device/$wifiSetupName';

  /// Cắt ảnh: push từ tab Ảnh của Số liệu, ngoài khung tab; `extra` = [PhotoCropArgs].
  static const photoCropName = 'photo';
  static const photoCrop = '$dashboard/$photoCropName';

  /// Tab 2–4, dùng chung mọi skill.
  static const sharedTabs = [skills, settings, device];

  /// Tab đang chọn theo đường dẫn: 0 = Điều khiển, 1 Skill, 2 Cài đặt, 3 Thiết bị.
  static int tabOf(String location) {
    final i = sharedTabs.indexWhere(location.startsWith);
    return i < 0 ? 0 : i + 1;
  }
}
