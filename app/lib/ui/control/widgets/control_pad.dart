import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// How a remote button looks.
enum PadLook {
  normal,

  /// Not usable now (screen off, night, offline): 38 %.
  disabled,

  /// Firmware lacks the command (R-DK-3): 38 % + lock 14 top right.
  locked,
}

/// One remote button's content.
class PadItem {
  const PadItem({required this.icon, required this.label, required this.onTap, this.look = PadLook.normal, this.lit});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final PadLook look;

  /// Accent of a lit button (paused → amber: tint 16 % + icon and label in it); null = not lit.
  final Color? lit;
}

/// Mờ của nút không dùng được / thiếu firmware.
const padDisabledOpacity = 0.38;

/// `ControlPad` (§8): đệm 14 16 0, 3 nút chia đều cách 10, ≥ 64 (`padButton`) bo 18 nền `panel`: icon 28 ink +
/// 4 + nhãn 11 inkDim.
class ControlPad extends StatelessWidget {
  const ControlPad({super.key, required this.items});

  final List<PadItem> items;

  static const _gap = 10.0;
  static const _padTop = 14.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.l, _padTop, AppSpace.l, 0),
    child: Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(child: _PadButton(items[i])),
        ],
      ],
    ),
  );
}

class _PadButton extends StatelessWidget {
  const _PadButton(this.item);

  final PadItem item;

  static const _icon = 28.0;
  static const _label = 11.0;
  static const _lock = 14.0;
  static const _lockInset = 8.0;
  static const _tint = 0.16;

  @override
  Widget build(BuildContext context) {
    final lit = item.lit;
    final fg = lit ?? AppColors.ink;
    final usable = item.look == PadLook.normal;
    return Semantics(
      button: true,
      enabled: usable,
      child: Opacity(
        opacity: usable ? 1 : padDisabledOpacity,
        child: Material(
          color: lit == null ? AppColors.panel : Color.alphaBlend(lit.withValues(alpha: _tint), AppColors.panel),
          borderRadius: BorderRadius.circular(AppSize.radiusPadButton),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: usable ? item.onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.padButton),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: _icon, color: fg),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: _label,
                            color: lit ?? AppColors.inkDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.look == PadLook.locked)
                    const Positioned(
                      top: _lockInset,
                      right: _lockInset,
                      child: Icon(Icons.lock_outline, size: _lock, color: AppColors.inkDim),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
