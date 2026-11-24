import 'package:flutter/painting.dart';

import '../../../domain/models/usage_meta.dart';
import 'app_colors.dart';

/// Colours that carry meaning — same as the panel (src/core/theme.h).
abstract final class StatusColors {
  /// R-DUNG-1.
  static Color usage(UsageLevel level) => switch (level) {
        UsageLevel.unknown => AppColors.muted,
        UsageLevel.ok => AppColors.mint,
        UsageLevel.low => AppColors.amber,
        UsageLevel.critical => AppColors.coral,
      };

  /// Project state (approval / input / error / working / done).
  static Color projectState(String s) => switch (s) {
        'approval' => AppColors.amber,
        'input' => AppColors.sky,
        'error' => AppColors.coral,
        'working' => AppColors.lilac,
        _ => AppColors.mint,
      };

  /// Attention card kind.
  static Color cardKind(String k) => switch (k) {
        'approval' || 'warning' => AppColors.amber,
        'input' => AppColors.sky,
        'success' => AppColors.mint,
        'error' => AppColors.coral,
        'progress' => AppColors.lilac,
        _ => AppColors.ink,
      };
}
