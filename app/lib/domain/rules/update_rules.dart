// Cập nhật firmware và tệp sao lưu.
import '../models/release.dart';

/// R-TB-1: có bản mới khi bản phát hành mới hơn lúc build của thiết bị quá 30 phút
/// (CI đóng dấu build vài phút trước khi phát hành).
bool updateAvailable(DateTime? deviceBuild, Release? latest) =>
    deviceBuild != null &&
    latest != null &&
    latest.published.isAfter(deviceBuild.add(const Duration(minutes: 30)));

/// R-TB-2: tệp khôi phục chỉ hợp lệ khi là config.json của glimmer (có `wifi_ssid`).
bool isGlimmerConfig(Map<String, dynamic> cfg) => cfg['wifi_ssid'] != null;
