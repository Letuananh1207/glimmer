import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

const _body = 13.0, _bodyLine = 18 / 13;

/// Nút quét ở đầu `form` (screen_specs §5, 2026-11-28.12 `WifiScanEntry`): cao ≥ 64, bo 14, viền 1 `clawd`, nền `clawd`
/// 8 %, đệm 10 14, cách 12 — ô 40 bo 12 nền `clawd` 16 % + icon qr 24; `wifiScanEntry` 15/500 + `wifiScanEntrySub` 12 muted;
/// chevron 24 muted.
class WifiScanEntry extends StatelessWidget {
  const WifiScanEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _minH = 64.0, _radius = 14.0;
  static const _pad = EdgeInsets.symmetric(vertical: 10, horizontal: 14);
  static const _tint = 0.08, _boxTint = 0.16;
  static const _box = 40.0, _boxRadius = 12.0, _qr = 24.0, _chevron = 24.0;
  static const _title = 15.0, _sub = 12.0, _subLine = 16 / 12;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: AppColors.clawd.withValues(alpha: _tint),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: const BorderSide(color: AppColors.clawd, width: AppSize.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minH),
          child: Padding(
            padding: _pad,
            child: Row(children: [
              Container(
                width: _box,
                height: _box,
                decoration: BoxDecoration(
                  color: AppColors.clawd.withValues(alpha: _boxTint),
                  borderRadius: BorderRadius.circular(_boxRadius),
                ),
                child: const Icon(Icons.qr_code_2, size: _qr, color: AppColors.clawd),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.wifiScanEntry,
                      style: const TextStyle(
                          fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(l.wifiScanEntrySub,
                      style: const TextStyle(
                          fontFamily: AppFonts.family, fontSize: _sub, height: _subLine, color: AppColors.muted)),
                ]),
              ),
              const SizedBox(width: AppSpace.s),
              const Icon(Icons.chevron_right, size: _chevron, color: AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Vạch `wifiOrManual`: nhãn giữa hai kẻ 1 `line`, lề 16 0 14.
class OrManualDivider extends StatelessWidget {
  const OrManualDivider({super.key});

  static const _pad = EdgeInsets.only(top: AppSpace.l, bottom: 14);

  @override
  Widget build(BuildContext context) => Padding(
        padding: _pad,
        child: Row(children: [
          const Expanded(child: Divider(color: AppColors.line, height: AppSize.hairline, thickness: AppSize.hairline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
            child: Text(AppLocalizations.of(context).wifiOrManual, style: AppFonts.label),
          ),
          const Expanded(child: Divider(color: AppColors.line, height: AppSize.hairline, thickness: AppSize.hairline)),
        ]),
      );
}

/// Thanh báo "đã đọc mã" (`password` / `formScanned`): nền `panel2` bo 14 đệm 12 14, lề dưới 18 — check 20 mint +
/// `wifiScannedTitle` 14/700 + [body] 13 inkDim.
class ScannedBanner extends StatelessWidget {
  const ScannedBanner({super.key, required this.body});

  final String body;

  static const _radius = 14.0, _check = 20.0, _title = 14.0, _bottom = 18.0;
  static const _pad = EdgeInsets.symmetric(vertical: AppSpace.m, horizontal: 14);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: _bottom),
        padding: _pad,
        decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(_radius)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle, size: _check, color: AppColors.mint),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).wifiScannedTitle,
                  style: const TextStyle(
                      fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: AppSpace.xs),
              Text(body,
                  style: const TextStyle(
                      fontFamily: AppFonts.family, fontSize: _body, height: _bodyLine, color: AppColors.inkDim)),
            ]),
          ),
        ]),
      );
}

/// `password`: nhãn `wifiNetworkToSend`; hàng cao 52 bo 12 nền `panel` — icon wifi 22 inkDim + tên mạng 16 ink (chỉ đọc)
/// + nút chữ `wifiChangeNetwork` 13/500 `clawd`.
class NetworkToSend extends StatelessWidget {
  const NetworkToSend({super.key, required this.ssid, required this.onChange});

  final String ssid;
  final VoidCallback onChange;

  static const _rowH = 52.0, _radius = 12.0, _wifi = 22.0, _name = 16.0, _link = 13.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.wifiNetworkToSend, style: AppFonts.label),
      const SizedBox(height: AppSpace.s),
      Container(
        height: _rowH,
        padding: const EdgeInsets.only(left: 14, right: AppSpace.xs),
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(_radius)),
        child: Row(children: [
          const Icon(Icons.wifi, size: _wifi, color: AppColors.inkDim),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Text(ssid,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: AppFonts.family, fontSize: _name, color: AppColors.ink)),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.clawd,
              minimumSize: const Size(AppSize.tapMin, AppSize.tapMin),
              textStyle: const TextStyle(fontFamily: AppFonts.family, fontSize: _link, fontWeight: FontWeight.w500),
            ),
            child: Text(l.wifiChangeNetwork),
          ),
        ]),
      ),
    ]);
  }
}

/// Dưới ô mật khẩu (`password`): icon lock 14 + `wifiRememberNote` 12 muted.
class RememberNote extends StatelessWidget {
  const RememberNote({super.key});

  static const _lock = 14.0, _lockTop = 2.0, _line = 16 / 12;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(top: _lockTop),
          child: Icon(Icons.lock_outline, size: _lock, color: AppColors.muted),
        ),
        const SizedBox(width: AppSpace.s),
        Expanded(
          child: Text(AppLocalizations.of(context).wifiRememberNote,
              style: AppFonts.label.copyWith(height: _line, letterSpacing: 0)),
        ),
      ]);
}

/// Dưới nút gửi (`form`, lề trên 10, giữa, cao 44): icon key 16 + `wifiSavedLink` 13 inkDim → bảng mật khẩu đã nhớ.
class SavedPasswordsLink extends StatelessWidget {
  const SavedPasswordsLink({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  static const _top = 10.0, _key = 16.0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: _top),
        child: Center(
          child: TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.inkDim,
              minimumSize: const Size(AppSize.tapMin, AppSize.tapMin),
              textStyle: const TextStyle(fontFamily: AppFonts.family, fontSize: _body),
            ),
            icon: const Icon(Icons.key, size: _key),
            label: Text(AppLocalizations.of(context).wifiSavedLink('$count')),
          ),
        ),
      );
}
