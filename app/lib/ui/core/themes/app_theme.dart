import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Theme của app — trùng `G.theme()` cũ (lib/ui/theme.dart) để giao diện không đổi (thiết kế 2026-11-25.1).
abstract final class AppTheme {
  /// Khoảng dọc giữa các thẻ (6, đúng app cũ; token không có bậc 6).
  static const double _cardGapV = 6;

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.clawd,
      onPrimary: AppColors.bg,
      secondary: AppColors.mint,
      surface: AppColors.panel,
      onSurface: AppColors.ink,
      error: AppColors.coral,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: AppFonts.family);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: _cardGapV),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.radiusCard)),
      ),
      // 2026-11-25.2: every icon ink (no more black selected icon); label 12/700 ink selected, 12/500 inkDim.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.panel,
        indicatorColor: AppColors.panel2,
        iconTheme: const WidgetStatePropertyAll(IconThemeData(color: AppColors.ink)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? AppFonts.navLabel.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)
            : AppFonts.navLabel.copyWith(color: AppColors.inkDim)),
      ),
      dividerColor: AppColors.line,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
