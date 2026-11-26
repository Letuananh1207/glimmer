// SINH TỰ ĐỘNG bởi tool/sync_design.dart từ design/tokens/design_tokens.json.
// Không sửa tay — sửa thiết kế rồi chạy: dart run tool/sync_design.dart
import 'package:flutter/painting.dart';

abstract final class AppColors {
  /// Nền mọi màn
  static const Color bg = Color(0xFF0E0D12);
  /// Thẻ (card), thanh điều hướng dưới, hộp thoại
  static const Color panel = Color(0xFF1F1A28);
  /// Thẻ nhấn mạnh (ghi chú, tiến trình), nền thanh %, viên chỉ báo tab đang chọn
  static const Color panel2 = Color(0xFF2A2236);
  /// Đường kẻ
  static const Color line = Color(0xFF34293F);
  /// Chữ chính
  static const Color ink = Color(0xFFFFF8E8);
  /// Chữ thân, chữ phụ sáng
  static const Color inkDim = Color(0xFFD8CDB8);
  /// Nhãn nhỏ, chữ phụ
  static const Color muted = Color(0xFF8A7F96);
  /// Lỗi; mức dùng còn ≤ 20%
  static const Color coral = Color(0xFFFF5247);
  /// Cần duyệt, cảnh báo, số liệu cũ; mức dùng còn ≤ 50%
  static const Color amber = Color(0xFFFFD23F);
  /// Xong, trực tuyến; mức dùng còn > 50%
  static const Color mint = Color(0xFF8FE574);
  /// Chờ bạn (input)
  static const Color sky = Color(0xFF54B6FF);
  /// Đang chạy (working), tiến độ
  static const Color lilac = Color(0xFFC385FF);
  /// Màu chính (nút, công tắc, thanh trượt), linh vật Clawd, tiêu đề nhóm Cài đặt
  static const Color clawd = Color(0xFFD97757);
  /// Viền nút viền và ô nhập (hiện là mặc định của Flutter)
  static const Color outline = Color(0xFFFFFFFF);
  /// Lớp phủ sau hộp thoại
  static const Color scrim = Color(0x8A000000);
  /// Màu nhấn skill Agent (= clawd)
  static const Color skillAgent = Color(0xFFD97757);
  /// Màu nhấn skill Nhạc (= lilac)
  static const Color skillMusic = Color(0xFFC385FF);
  /// Màu nhấn skill Mạng xã hội (= sky)
  static const Color skillSocial = Color(0xFF54B6FF);
  /// Màu nhấn skill Giải trí (= amber)
  static const Color skillFun = Color(0xFFFFD23F);
  /// Nền ô icon skill Agent
  static const Color skillAgentTint = Color(0x29D97757);
  /// Nền ô icon skill Nhạc
  static const Color skillMusicTint = Color(0x29C385FF);
  /// Nền ô icon skill Mạng xã hội
  static const Color skillSocialTint = Color(0x2954B6FF);
  /// Nền ô icon skill Giải trí
  static const Color skillFunTint = Color(0x29FFD23F);
  /// Màu nhấn skill Thời tiết (= sky, như kênh Weather)
  static const Color skillWeather = Color(0xFF54B6FF);
  /// Màu nhấn skill Đồng hồ (= amber, như kênh Clock)
  static const Color skillClock = Color(0xFFFFD23F);
  /// Nền ô icon skill Thời tiết
  static const Color skillWeatherTint = Color(0x2954B6FF);
  /// Nền ô icon skill Đồng hồ
  static const Color skillClockTint = Color(0x29FFD23F);
  /// Màu nhấn skill Ảnh (= mint, như kênh Photo trên thiết bị)
  static const Color skillPhoto = Color(0xFF8FE574);
  /// Nền ô icon skill Ảnh; nền ô "+ Thêm ảnh" dùng mint 8 %
  static const Color skillPhotoTint = Color(0x298FE574);
  /// Vỏ máy quanh ô màn (gradient 160°, trên)
  static const Color deviceShellTop = Color(0xFF26232B);
  /// Vỏ máy quanh ô màn (gradient 160°, dưới)
  static const Color deviceShellBottom = Color(0xFF141217);
  /// Thanh báo nổi (lệnh không nhận)
  static const Color snackbar = Color(0xFF3A3048);
  /// Ô màn khi màn thiết bị tắt
  static const Color screenOff = Color(0xFF050507);
  /// Nút start (Start menu) — gradient trên, như XP
  static const Color xpStartTop = Color(0xFF4CB04C);
  /// Nút start — gradient dưới
  static const Color xpStartBottom = Color(0xFF2F8A2F);
  /// Nền nhãn biểu tượng desktop đang chọn (XP)
  static const Color xpSelect = Color(0xFF316AC5);
  /// Viền ngoài vòng chạm trên ô màn
  static const Color tapRing = Color(0x8CFFD23F);
}
