import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/clawd.dart';

/// Đầu màn Điều khiển (§8, design 2026-11-27.10): đệm 10 16 6 20, cách 12 — Clawd ×1.75 + "glimmer" 16/700 / chấm 7 +
/// mạng · IP 11 muted; bên phải [trailing] (`PowerButton`, lề phải −4).
class ControlHeader extends StatelessWidget {
  const ControlHeader({super.key, required this.network, required this.dot, required this.trailing});

  /// "Nhà-2G · 192.168.1.50".
  final String network;

  /// Mint online, amber setup, coral offline.
  final Color dot;
  final Widget trailing;

  static const _clawd = 18 * 1.75;
  static const _title = 16.0;
  static const _net = 11.0;
  static const _dot = 7.0;
  static const _dotGap = 6.0;
  static const _lineGap = 2.0;
  static const _nudge = 4.0;
  static const _padTop = 10.0, _padBottom = 6.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, _padTop, AppSpace.l - _nudge, _padBottom),
      child: Row(
        children: [
          const Clawd(size: _clawd),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'glimmer',
                  style: AppFonts.heading.copyWith(fontSize: _title, color: AppColors.ink),
                ),
                const SizedBox(height: _lineGap),
                Row(
                  children: [
                    Container(
                      width: _dot,
                      height: _dot,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: _dotGap),
                    Flexible(
                      child: Text(
                        network,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.label.copyWith(fontSize: _net, letterSpacing: 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.m),
          trailing,
        ],
      ),
    );
  }
}

/// Thanh báo đầu màn (oldFw amber / setup amber / offline coral): lề 6 16 4, nền `panel2` bo 14, đệm 12 16 —
/// tiêu đề 14/700 màu báo, thân 13 inkDim, nút chữ `clawd` 14/500 bên phải.
class ControlBanner extends StatelessWidget {
  const ControlBanner({
    super.key,
    required this.title,
    required this.body,
    required this.color,
    required this.action,
    required this.onAction,
  });

  final String title, body, action;
  final Color color;
  final VoidCallback onAction;

  static const _margin = EdgeInsets.fromLTRB(AppSpace.l, 6, AppSpace.l, AppSpace.xs);
  static const _bodySize = 13.0;
  static const _bodyLine = 18 / 13;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Container(
      margin: _margin,
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l - AppSpace.s, 0),
      decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.button.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: AppSpace.xs),
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.s),
            child: Text(
              body,
              style: AppFonts.body.copyWith(fontSize: _bodySize, height: _bodyLine),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSize.tapMin, AppSize.button),
                foregroundColor: AppColors.clawd,
                textStyle: AppFonts.button,
              ),
              child: Text(action),
            ),
          ),
        ],
      ),
    ),
  );
}

