import 'package:flutter/foundation.dart';

/// Mật khẩu Wi-Fi app nhớ theo tên mạng (R-WF-5). Nạp lúc khởi động, getter đồng bộ.
abstract class WifiPasswordRepository extends ChangeNotifier {
  /// Mật khẩu đã nhớ của [ssid]; null khi chưa nhớ.
  String? passwordFor(String ssid);

  /// Tên các mạng đã nhớ, theo bảng chữ cái.
  List<String> get networks;

  /// Lần cuối thiết bị vào [ssid] bằng mật khẩu đã nhớ (bảng "Mật khẩu đã nhớ"); null khi chưa biết.
  DateTime? lastUsed(String ssid);

  /// Nhớ (hoặc thay) mật khẩu của [ssid], ghi lần dùng là bây giờ. Tên rỗng → bỏ qua.
  void remember(String ssid, String password);

  /// Quên mật khẩu của [ssid].
  void forget(String ssid);
}
