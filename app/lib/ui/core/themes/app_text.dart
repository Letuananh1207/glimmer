// Viết tay theo design/tokens/design_tokens.json ("font", "type", "space", "size", "radius", "border").
// sync_design.dart báo khi các nhóm này đổi — sửa file này cho khớp.
import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Kiểu chữ (`type` của token). Mọi chữ dùng JetBrains Mono (`font.mono`).
abstract final class AppFonts {
  static const String family = 'JetBrainsMono';

  static TextStyle _mono(double size, FontWeight weight, {Color? color, double? letterSpacing}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Tiêu đề màn Kết nối, tên glimmer ở Tổng quan.
  static final TextStyle screenTitle = _mono(20, FontWeight.w700);

  /// Tiêu đề thanh trên (Cài Wi-Fi).
  static final TextStyle appBarTitle = _mono(22, FontWeight.w400);

  /// Tiêu đề hộp thoại.
  static final TextStyle dialogTitle = _mono(24, FontWeight.w400);

  /// Dòng trạng thái, tiêu đề thẻ tiến trình.
  static final TextStyle heading = _mono(16, FontWeight.w700);

  /// Tiêu đề dòng danh sách.
  static final TextStyle itemTitle = _mono(16, FontWeight.w400);

  /// Chữ thân.
  static final TextStyle body = _mono(14, FontWeight.w400, color: AppColors.inkDim);

  /// Nhãn, chữ phụ.
  static final TextStyle label = _mono(12, FontWeight.w400, color: AppColors.muted, letterSpacing: 0.5);

  /// Chữ trên nút.
  static final TextStyle button = _mono(14, FontWeight.w500);

  /// Nhãn tab dưới.
  static final TextStyle navLabel = _mono(12, FontWeight.w500);

  /// Giá trị bên phải dòng (giờ Từ/Đến).
  static final TextStyle trailingValue = _mono(11, FontWeight.w500);

  /// % tuần.
  static final TextStyle usageHero = _mono(40, FontWeight.w700);

  /// % phiên 5 giờ.
  static final TextStyle usageSmall = _mono(24, FontWeight.w700);
}

/// Khoảng cách (`space`).
abstract final class AppSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Kích thước (`size`), bo góc (`radius`) và viền (`border`).
abstract final class AppSize {
  static const double tapMin = 44;
  static const double button = 40;
  static const double navBar = 80;
  static const double appBar = 64;
  static const double listTile = 56;
  static const double listTile2 = 72;
  static const double field = 56;
  static const double clawdConnect = 144;
  static const double clawdWifi = 120;
  static const double clawdHeader = 72;
  static const double usageBarBig = 8;
  static const double usageBarSmall = 5;
  static const double skillTile = 176;
  static const double skillBadge = 48;
  static const int navTabs = 4;
  static const double dockTab = 48;
  static const double skillRow = 72;
  static const double skillIcon = 44;
  static const double switchW = 52;
  static const double switchH = 32;
  static const double chip = 36;
  static const double headerClawd = 44;

  static const double radiusCard = 14;
  static const double radiusButton = 20;
  static const double radiusDialog = 28;
  static const double radiusField = 4;
  static const double radiusUsageBar = 3;
  static const double radiusNavIndicator = 16;
  static const double radiusSkillTile = 14;
  static const double radiusSkillBadge = 12;
  static const double radiusDockBar = 14;
  static const double radiusDockTab = 10;
  static const double radiusChip = 18;
  static const double radiusBadge = 4;

  static const double hairline = 1;
}
