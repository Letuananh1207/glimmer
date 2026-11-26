import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// `HoldCardPanel` (§8 `card`): lề 12 16 0, đệm 14 16, bo 14, nền amber 10 %, viền amber 40 %, cách 6 —
/// `controlCardLabel` 12 amber, thân 14 ink (tên công cụ đậm), `controlCardNote` 12 inkDim, nút viền
/// `controlDismissCard` cao 40 bo 20. Không có nút duyệt (R-DK-2).
class HoldCardPanel extends StatelessWidget {
  const HoldCardPanel({
    super.key,
    required this.agent,
    required this.project,
    required this.tool,
    required this.input,
    required this.onDismiss,
  });

  final String agent, project, tool;

  /// Waiting for an answer (input) rather than an approval.
  final bool input;

  /// Null while a command is on its way / the firmware lacks it.
  final VoidCallback? onDismiss;

  static const _fill = 0.10, _edge = 0.4;
  static const _padV = 14.0;
  static const _gap = 6.0;
  static const _body = 14.0, _bodyLine = 19 / 14;
  static const _noteLine = 16 / 12;
  static const _button = 13.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final body = input
        ? Text(l.controlCardBodyInput(agent, project), style: _bodyStyle)
        : _approval(l.controlCardBody(agent, project, tool), tool);
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: _padV),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: _fill),
        borderRadius: BorderRadius.circular(AppSize.radiusCard),
        border: Border.all(color: AppColors.amber.withValues(alpha: _edge)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.controlCardLabel, style: AppFonts.label.copyWith(color: AppColors.amber)),
          const SizedBox(height: _gap),
          body,
          const SizedBox(height: _gap),
          Text(
            l.controlCardNote,
            style: AppFonts.label.copyWith(color: AppColors.inkDim, letterSpacing: 0, height: _noteLine),
          ),
          const SizedBox(height: _gap),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onDismiss,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(AppSize.tapMin, AppSize.button),
                side: const BorderSide(color: AppColors.line),
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.radiusButton)),
                textStyle: AppFonts.button.copyWith(fontSize: _button),
              ),
              child: Text(l.controlDismissCard),
            ),
          ),
        ],
      ),
    );
  }

  static const _bodyStyle = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: _body,
    height: _bodyLine,
    color: AppColors.ink,
  );

  /// The tool name in bold where it sits in the sentence.
  static Widget _approval(String text, String tool) {
    final i = tool.isEmpty ? -1 : text.lastIndexOf(tool);
    if (i < 0) return Text(text, style: _bodyStyle);
    return Text.rich(
      TextSpan(
        style: _bodyStyle,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: tool,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(i + tool.length)),
        ],
      ),
    );
  }
}

/// `CommandSnackbar` (§8 `failed`): trái / phải 12, nền `snackbar` bo 12 bóng, đệm 6 8 6 16 — chữ 13 ink + nút
/// `commonRetry` 14/700 `clawd`. Tự ẩn sau 6 s (ViewModel).
class CommandSnackbar extends StatelessWidget {
  const CommandSnackbar({super.key, required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  static const _text = 13.0, _textLine = 18 / 13;
  static const _blur = 18.0, _shadowY = 6.0, _shadowAlpha = 0.5;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.l, 6, AppSpace.s, 6),
        decoration: BoxDecoration(
          color: AppColors.snackbar,
          borderRadius: BorderRadius.circular(AppSize.radiusSnackbar),
          boxShadow: [
            BoxShadow(
              color: AppColors.bg.withValues(alpha: _shadowAlpha),
              blurRadius: _blur,
              offset: const Offset(0, _shadowY),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: _text,
                  height: _textLine,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSize.tapMin, AppSize.button),
                foregroundColor: AppColors.clawd,
                textStyle: AppFonts.button.copyWith(fontWeight: FontWeight.w700),
              ),
              child: Text(l.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
