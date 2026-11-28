import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Lớp phủ đen 60 % dưới bảng / hộp thoại.
const _scrimAlpha = 0.6;

/// "Mật khẩu đã nhớ" (screen_specs §5 `saved`, 2026-11-28.12): bảng dưới nền `panel`, bo trên 20, đệm 10 20 28 — tay nắm,
/// `wifiSavedTitle` 16/700, `wifiSavedBody` 12 muted; mỗi mạng một dòng ≥ 60 kẻ trên `line` (icon wifi 22, tên 15 +
/// `wifiSavedLastUsed` 12 muted, `wifiForget` 13/500 coral → hỏi quên); nút `commonClose` cao 48 bo 14 `panel2`.
Future<void> showSavedPasswordsSheet(
  BuildContext context, {
  required List<String> Function() networks,
  required DateTime? Function(String ssid) lastUsed,
  required void Function(String ssid) onForget,
}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: _scrimAlpha),
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.radiusSheet)),
      ),
      builder: (_) => SavedPasswordsSheet(networks: networks, lastUsed: lastUsed, onForget: onForget),
    );

class SavedPasswordsSheet extends StatefulWidget {
  const SavedPasswordsSheet({super.key, required this.networks, required this.lastUsed, required this.onForget});

  final List<String> Function() networks;
  final DateTime? Function(String ssid) lastUsed;
  final void Function(String ssid) onForget;

  @override
  State<SavedPasswordsSheet> createState() => _SavedPasswordsSheetState();
}

class _SavedPasswordsSheetState extends State<SavedPasswordsSheet> {
  static const _pad = EdgeInsets.fromLTRB(AppSpace.xl, 10, AppSpace.xl, 28);
  static const _handleW = 36.0, _handleH = 4.0;
  static const _title = 16.0, _line = 16 / 12;
  static const _rowMin = 60.0, _wifi = 22.0, _name = 15.0, _forget = 13.0;
  static const _closeH = 48.0, _closeRadius = 14.0;

  String _when(AppLocalizations l, DateTime at) {
    final now = DateTime.now();
    if (at.year == now.year && at.month == now.month && at.day == now.day) return l.devWifiUsedToday;
    return '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}';
  }

  Future<void> _askForget(String ssid) async {
    if (await showForgetPasswordDialog(context, ssid)) {
      widget.onForget(ssid);
      if (!mounted) return;
      if (widget.networks().isEmpty) {
        Navigator.of(context).pop();
      } else {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nets = widget.networks();
    return SafeArea(
      child: Padding(
        padding: _pad,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: _handleW,
              height: _handleH,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(_handleH / 2)),
            ),
          ),
          const SizedBox(height: 14),
          Text(l.wifiSavedTitle,
              style: const TextStyle(
                  fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: AppSpace.xs),
          Text(l.wifiSavedBody, style: AppFonts.label.copyWith(height: _line, letterSpacing: 0)),
          const SizedBox(height: AppSpace.m),
          for (final ssid in nets)
            Container(
              constraints: const BoxConstraints(minHeight: _rowMin),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(children: [
                const Icon(Icons.wifi, size: _wifi, color: AppColors.inkDim),
                const SizedBox(width: AppSpace.l),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ssid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: AppFonts.family, fontSize: _name, color: AppColors.ink)),
                    if (widget.lastUsed(ssid) case final at?)
                      Text(l.wifiSavedLastUsed(_when(l, at)), style: AppFonts.label.copyWith(letterSpacing: 0)),
                  ]),
                ),
                TextButton(
                  onPressed: () => _askForget(ssid),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    minimumSize: const Size(AppSize.tapMin, AppSize.tapMin),
                    textStyle:
                        const TextStyle(fontFamily: AppFonts.family, fontSize: _forget, fontWeight: FontWeight.w500),
                  ),
                  child: Text(l.wifiForget),
                ),
              ]),
            ),
          const SizedBox(height: AppSpace.l),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.panel2,
              foregroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(_closeH),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_closeRadius)),
            ),
            child: Text(l.commonClose),
          ),
        ]),
      ),
    );
  }
}

/// `forget` (hộp thoại 312, bo 20, đệm 24): `wifiForgetTitle` 18/700, `wifiForgetBody` 13 inkDim, `commonCancel` /
/// `wifiForget` (coral 700). True = quên.
Future<bool> showForgetPasswordDialog(BuildContext context, String ssid) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: _scrimAlpha),
      builder: (_) => ForgetPasswordDialog(ssid: ssid),
    ) ??
    false;

class ForgetPasswordDialog extends StatelessWidget {
  const ForgetPasswordDialog({super.key, required this.ssid});

  final String ssid;

  static const _width = 312.0, _radius = 20.0, _gap = 14.0;
  static const _title = 18.0, _body = 13.0, _bodyLine = 18 / 13;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      insetPadding: const EdgeInsets.all(AppSpace.xxl),
      child: SizedBox(
        width: _width,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.wifiForgetTitle(ssid),
                style: const TextStyle(
                    fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: _gap),
            Text(l.wifiForgetBody,
                style: const TextStyle(
                    fontFamily: AppFonts.family, fontSize: _body, height: _bodyLine, color: AppColors.inkDim)),
            const SizedBox(height: _gap + AppSpace.xs),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.inkDim, minimumSize: const Size(AppSize.tapMin, AppSize.tapMin)),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.commonCancel),
              ),
              const SizedBox(width: AppSpace.s),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  minimumSize: const Size(AppSize.tapMin, AppSize.tapMin),
                  textStyle: AppFonts.button.copyWith(fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.wifiForget),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
