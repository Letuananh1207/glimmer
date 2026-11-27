import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/cursor.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import 'trackpad.dart';

/// `KeyPad` (§8, design 2026-11-27.10, R-DK-19): lề 12 16 0, 3 hàng cách 8. Phím cao 52 bo 10, mặt gradient
/// `keyFaceTop` → `keyFaceBottom`, gờ dưới 3 `keyEdge` + viền sáng trên 1 px trắng 6 %, chữ 13/700 ink; đang bấm:
/// `keyPressed` + bóng trong. Hàng 1: Windows (cờ 4 màu 16) · Alt+Tab · Alt+F4 (rộng 1.2) · Esc. Hàng 2: Tab · Enter
/// (rộng 1.6) · Chữ (mờ 35 %, "sắp có"). Hàng 3: ← ↑ ↓ →. Tổ hợp là phím có sẵn, một chạm. [held] vẽ phím đó lõm.
class KeyPad extends StatelessWidget {
  const KeyPad({super.key, required this.enabled, required this.onKey, this.held});

  final bool enabled;
  final ValueChanged<ControlKey> onKey;
  final ControlKey? held;

  static const _rowGap = AppSpace.s;
  static const _wide = 1.2, _enter = 1.6;
  static const _tabIcon = 20.0, _arrowIcon = 22.0, _textIcon = 18.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget key(ControlKey k, String a11y, {double flex = 1, String? text, Widget? icon}) => Expanded(
      flex: (flex * 10).round(),
      child: _KeyCap(a11y: a11y, text: text, icon: icon, held: held == k, onTap: () => onKey(k)),
    );
    Widget row(List<Widget> keys) => Row(
      children: [
        for (final (i, k) in keys.indexed) ...[if (i > 0) const SizedBox(width: _rowGap), k],
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, 0),
      child: Semantics(
        label: l.controlKeysA11y,
        child: Opacity(
          opacity: enabled ? 1 : Trackpad.dimOpacity,
          child: IgnorePointer(
            ignoring: !enabled,
            child: Column(
              children: [
                row([
                  key(ControlKey.windows, l.keyWindows, flex: _wide, text: l.keyWindows, icon: const _WindowsFlag()),
                  key(ControlKey.altTab, l.keyAltTab, flex: _wide, text: l.keyAltTab),
                  key(ControlKey.altF4, l.keyAltF4, flex: _wide, text: l.keyAltF4),
                  key(ControlKey.escape, l.keyEsc, text: l.keyEsc),
                ]),
                const SizedBox(height: _rowGap),
                row([
                  key(
                    ControlKey.tab,
                    l.keyTab,
                    text: l.keyTab,
                    icon: const Icon(Icons.keyboard_tab, size: _tabIcon, color: AppColors.ink),
                  ),
                  key(
                    ControlKey.enter,
                    l.keyEnter,
                    flex: _enter,
                    text: l.keyEnter,
                    icon: const Icon(Icons.keyboard_return, size: _tabIcon, color: AppColors.ink),
                  ),
                  Expanded(
                    flex: 10,
                    child: _TextKeySoon(label: l.keyText, soon: l.keyTextSoon, iconSize: _textIcon),
                  ),
                ]),
                const SizedBox(height: _rowGap),
                row([
                  key(
                    ControlKey.left,
                    l.keyLeft,
                    icon: const Icon(Icons.arrow_back, size: _arrowIcon, color: AppColors.ink),
                  ),
                  key(
                    ControlKey.up,
                    l.keyUp,
                    icon: const Icon(Icons.arrow_upward, size: _arrowIcon, color: AppColors.ink),
                  ),
                  key(
                    ControlKey.down,
                    l.keyDown,
                    icon: const Icon(Icons.arrow_downward, size: _arrowIcon, color: AppColors.ink),
                  ),
                  key(
                    ControlKey.right,
                    l.keyRight,
                    icon: const Icon(Icons.arrow_forward, size: _arrowIcon, color: AppColors.ink),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One key: a `keyEdge` 3-px ledge under a gradient face (`keyFaceTop` → `keyFaceBottom`) with a 1-px white 6 % top
/// light; pressed = flat `keyPressed`, no ledge. Flutter has no inset shadow nor rounded mixed-colour borders, so the
/// ledge is the layer under the face.
class _KeyFace extends StatelessWidget {
  const _KeyFace({required this.pressed, required this.child});

  final bool pressed;
  final Widget child;

  static const _ledge = 3.0, _light = 0.06;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(AppSize.radiusKey);
    if (pressed) {
      return Container(
        height: AppSize.key,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: r, color: AppColors.keyPressed),
        child: child,
      );
    }
    return Container(
      height: AppSize.key,
      decoration: BoxDecoration(borderRadius: r, color: AppColors.keyEdge),
      padding: const EdgeInsets.only(bottom: _ledge),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.keyFaceTop, AppColors.keyFaceBottom],
          ),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: AppColors.outline.withValues(alpha: _light)),
        ),
        child: child,
      ),
    );
  }
}

const _keyLabel = 13.0, _soonLabel = 10.0;

const _keyText = TextStyle(
  fontFamily: AppFonts.family,
  fontSize: _keyLabel,
  fontWeight: FontWeight.w700,
  color: AppColors.ink,
);

class _KeyCap extends StatefulWidget {
  const _KeyCap({required this.a11y, required this.onTap, this.text, this.icon, this.held = false});

  final String a11y;
  final String? text;
  final Widget? icon;
  final bool held;
  final VoidCallback onTap;

  @override
  State<_KeyCap> createState() => _KeyCapState();
}

class _KeyCapState extends State<_KeyCap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.a11y,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: _KeyFace(
        pressed: _down || widget.held,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?widget.icon,
              if (widget.icon != null && widget.text != null) const SizedBox(width: 6),
              if (widget.text != null)
                Flexible(
                  child: Text(widget.text!, overflow: TextOverflow.fade, softWrap: false, style: _keyText),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// "Chữ" — typing comes later: dim 35 %, keyboard icon + "sắp có" 10 muted, not pressable.
class _TextKeySoon extends StatelessWidget {
  const _TextKeySoon({required this.label, required this.soon, required this.iconSize});

  final String label, soon;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label · $soon',
    child: Opacity(
      opacity: Trackpad.dimOpacity,
      child: _KeyFace(
        pressed: false,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.keyboard_outlined, size: iconSize, color: AppColors.ink),
              Text(
                soon,
                style: const TextStyle(fontFamily: AppFonts.family, fontSize: _soonLabel, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// XP's flag, 4 colours in a 16 square (red, green, blue, yellow).
class _WindowsFlag extends StatelessWidget {
  const _WindowsFlag();

  static const _side = 16.0, _half = 7.0;
  static const _colors = [AppColors.coral, AppColors.mint, AppColors.sky, AppColors.amber];

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _side,
    child: Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [for (final c in _colors) Container(width: _half, height: _half, color: c)],
    ),
  );
}
