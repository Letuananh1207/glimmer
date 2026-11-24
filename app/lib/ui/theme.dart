import 'package:flutter/material.dart';

/// The device's palette (src/core/theme.h) so the app reads like the panel.
class G {
  static const bg = Color(0xFF0E0D12);
  static const panel = Color(0xFF1F1A28);
  static const panel2 = Color(0xFF2A2236);
  static const line = Color(0xFF34293F);
  static const ink = Color(0xFFFFF8E8);
  static const inkDim = Color(0xFFD8CDB8);
  static const muted = Color(0xFF8A7F96);
  static const coral = Color(0xFFFF5247);
  static const amber = Color(0xFFFFD23F);
  static const mint = Color(0xFF8FE574);
  static const sky = Color(0xFF54B6FF);
  static const lilac = Color(0xFFC385FF);
  static const clawd = Color(0xFFD97757);

  /// Colour of a % USED value — matches Display::usageColor on remaining.
  static Color usage(int used) {
    if (used < 0) return muted;
    final remaining = 100 - used;
    return remaining <= 20 ? coral : remaining <= 50 ? amber : mint;
  }

  static Color state(String s) => switch (s) {
        'approval' => amber,
        'input' => sky,
        'error' => coral,
        'working' => lilac,
        _ => mint,
      };

  static String stateLabel(String s) => switch (s) {
        'approval' => 'Cần duyệt',
        'input' => 'Chờ bạn',
        'error' => 'Lỗi',
        'working' => 'Đang chạy',
        _ => 'Xong',
      };

  static ThemeData theme() {
    final scheme = const ColorScheme.dark(
      primary: clawd,
      onPrimary: bg,
      secondary: mint,
      surface: panel,
      onSurface: ink,
      error: coral,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'JetBrainsMono');
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: ink, centerTitle: false),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: panel, indicatorColor: panel2),
      dividerColor: line,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}

/// Small helpers for consistent text.
class T {
  static TextStyle h(Color c) => TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c);
  static const label = TextStyle(fontSize: 12, color: G.muted, letterSpacing: 0.5);
  static const body = TextStyle(fontSize: 14, color: G.inkDim);
}

/// "4d 3h", "2h 14m", "12m", "ngay".
String countdown(int resetEpoch, int nowEpoch) {
  if (resetEpoch <= 0 || nowEpoch < 1000000000) return '--';
  var s = resetEpoch - nowEpoch;
  if (s <= 0) return 'ngay';
  final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60;
  if (d > 0) return '${d}d ${h}h';
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

/// "45s", "12m", "3h", "2d".
String ago(int s) => s < 60
    ? '${s}s'
    : s < 3600
        ? '${s ~/ 60}m'
        : s < 172800
            ? '${(s / 3600).round()}h'
            : '${(s / 86400).round()}d';
