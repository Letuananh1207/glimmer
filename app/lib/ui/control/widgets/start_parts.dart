import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

// Rows, columns and buttons of Start / Tất cả chương trình (design 2026-11-26.6, screen_specs §8).

/// Tay nắm 36 × 4 bo 2 `line`, cách dưới 10.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  static const _w = 36.0, _h = 4.0;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: _w,
      height: _h,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(_h / 2)),
    ),
  );
}

/// Cột của Start: nền [color] bo 14, đệm 6 4.
class StartColumn extends StatelessWidget {
  const StartColumn({super.key, required this.color, required this.children, this.vertical = 6});

  final Color color;
  final List<Widget> children;
  final double vertical;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: vertical),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

class StartRule extends StatelessWidget {
  const StartRule({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: AppSize.hairline,
    margin: const EdgeInsets.symmetric(horizontal: AppSpace.s, vertical: AppSpace.xs),
    color: AppColors.line,
  );
}

/// Hàng Start ≥ 48: icon trong ô 28, chữ 13 (700 / 500) ink, phụ 11 muted; bo 10. [onTap] null = mờ 38 %.
class StartRow extends StatelessWidget {
  const StartRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.sub,
    this.bold = false,
    this.trailing,
  });

  final Widget icon;
  final String title;
  final String? sub;
  final bool bold;
  final Widget? trailing;
  final VoidCallback? onTap;

  static const _minH = 48.0, _iconBox = 28.0, _radius = 10.0, _size = 13.0, _subSize = 11.0, _gap = 10.0;
  static const _disabled = 0.38;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? _disabled : 1,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minH),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
          child: Row(
            children: [
              SizedBox(
                width: _iconBox,
                child: Center(child: icon),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: _size,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.label.copyWith(fontSize: _subSize, letterSpacing: 0),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    ),
  );
}

/// Nút chữ ở chân Start: cao 44, đệm 0 14, icon 20 + chữ 13/500 cùng [color].
class StartFootButton extends StatelessWidget {
  const StartFootButton({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  static const _h = 44.0, _icon = 20.0, _size = 13.0;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, _h),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      foregroundColor: color,
      shape: const StadiumBorder(),
    ),
    icon: Icon(icon, size: _icon, color: color),
    label: Text(
      label,
      style: TextStyle(fontFamily: AppFonts.family, fontSize: _size, fontWeight: FontWeight.w500, color: color),
    ),
  );
}
