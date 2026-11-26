import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/clawd.dart';

/// Đầu màn Điều khiển (§8): đệm 10 16 4 20, cách 12 — Clawd ×1.75 + "glimmer" 16/700 / chấm 7 + mạng · IP 11 muted;
/// nút refresh 44 inkDim (`controlRefreshA11y`) lấn 8 vào lề phải.
class ControlHeader extends StatelessWidget {
  const ControlHeader({super.key, required this.network, required this.dot, required this.onRefresh});

  /// "Nhà-2G · 192.168.1.50".
  final String network;

  /// Mint online, amber setup, coral offline.
  final Color dot;
  final VoidCallback? onRefresh;

  static const _clawd = 18 * 1.75;
  static const _title = 16.0;
  static const _net = 11.0;
  static const _dot = 7.0;
  static const _dotGap = 6.0;
  static const _lineGap = 2.0;
  static const _nudge = 8.0;
  static const _padTop = 10.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, _padTop, AppSpace.l - _nudge, AppSpace.xs),
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
          IconButton(
            onPressed: onRefresh,
            tooltip: l.controlRefreshA11y,
            constraints: const BoxConstraints.tightFor(width: AppSize.tapMin, height: AppSize.tapMin),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.refresh, color: AppColors.inkDim),
          ),
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

/// Chip "Đang gửi…" trên góc vỏ: cao 28 bo 14 `panel2` viền `line`, vòng xoay 16 + chữ 12, đệm 0 12 0 8, cách 6.
class SendingChip extends StatelessWidget {
  const SendingChip({super.key, required this.label});

  final String label;

  static const _h = 28.0;
  static const _spinner = 16.0;
  static const _gap = 6.0;
  static const _stroke = 2.0;

  @override
  Widget build(BuildContext context) => Container(
    height: _h,
    padding: const EdgeInsets.fromLTRB(AppSpace.s, 0, AppSpace.m, 0),
    decoration: BoxDecoration(
      color: AppColors.panel2,
      borderRadius: BorderRadius.circular(_h / 2),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: _spinner,
          child: CircularProgressIndicator(strokeWidth: _stroke, color: AppColors.ink),
        ),
        const SizedBox(width: _gap),
        Text(label, style: AppFonts.label.copyWith(color: AppColors.ink, letterSpacing: 0)),
      ],
    ),
  );
}

/// `ChannelProgress` (§8): đệm 12 24 0, cách 8 — tên kênh 13/700 ink + ghi chú 13 (muted / amber / lilac); thanh 3
/// bo 2 nền `panel2`, phần chạy = [progress] màu [accent].
class ChannelProgress extends StatelessWidget {
  const ChannelProgress({
    super.key,
    required this.title,
    required this.note,
    required this.noteColor,
    required this.progress,
    required this.accent,
  });

  final String title, note;
  final Color noteColor, accent;
  final double progress;

  static const _size = 13.0;
  static const _bar = 3.0;
  static const _barRadius = 2.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.xxl, AppSpace.m, AppSpace.xxl, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              if (note.isNotEmpty)
                TextSpan(
                  text: ' $note',
                  style: TextStyle(color: noteColor),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: AppFonts.family, fontSize: _size),
        ),
        const SizedBox(height: AppSpace.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(_barRadius),
          child: SizedBox(
            height: _bar,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.panel2,
              color: accent,
            ),
          ),
        ),
      ],
    ),
  );
}
