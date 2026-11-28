import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/wifi_scan_view_model.dart';

/// Bảng dưới của Quét mã (screen_specs §10): nền `panel`, bo trên 20, đệm 20 20 28, cách 14 — hướng dẫn + ảnh màn thiết bị
/// (`scanning`), đã đọc (`found`), mã lạ + Quét lại (`wrongCode`), xin quyền camera (`noCamera`); "Không có mã? Nhập tay".
class ScanPanel extends StatelessWidget {
  const ScanPanel({
    super.key,
    required this.state,
    required this.blocked,
    required this.onManual,
    required this.onScanAgain,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final ScanState state;

  /// Camera refused for good: "Mở cài đặt điện thoại" shows.
  final bool blocked;
  final VoidCallback onManual, onScanAgain, onAllow, onOpenSettings;

  static const _pad = EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, 28);
  static const _gap = 14.0;
  static const _radius = 20.0;
  static const _image = 88.0, _imageRadius = 8.0;
  static const _title = 15.0, _body = 13.0, _bodyLine = 18 / 13, _link = 13.0;
  static const _check = 28.0;
  static const _buttonH = 48.0;

  static const _titleStyle =
      TextStyle(fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const _bodyStyle =
      TextStyle(fontFamily: AppFonts.family, fontSize: _body, height: _bodyLine, color: AppColors.inkDim);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final manual = SizedBox(
      height: AppSize.tapMin,
      child: Center(
        child: TextButton(
          onPressed: onManual,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.clawd,
            minimumSize: const Size(AppSize.tapMin, AppSize.tapMin),
            textStyle: const TextStyle(fontFamily: AppFonts.family, fontSize: _link, fontWeight: FontWeight.w500),
          ),
          child: Text(l.wifiScanManual),
        ),
      ),
    );
    final primary = FilledButton.styleFrom(minimumSize: const Size.fromHeight(_buttonH));
    final children = switch (state) {
      ScanState.found => [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle, size: _check, color: AppColors.mint),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.wifiScanFound, style: _titleStyle),
                const SizedBox(height: AppSpace.xs),
                Text(l.wifiScanFoundBody, style: _bodyStyle),
              ]),
            ),
          ]),
        ],
      ScanState.wrongCode => [
          Text(l.wifiScanWrongTitle, style: _titleStyle.copyWith(color: AppColors.coral)),
          Text(l.wifiScanWrongBody, style: _bodyStyle),
          FilledButton.icon(
            style: primary,
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.wifiScanAgain),
          ),
          manual,
        ],
      ScanState.noCamera => [
          FilledButton.icon(
            style: primary,
            onPressed: onAllow,
            icon: const Icon(Icons.photo_camera),
            label: Text(l.wifiScanAllowCamera),
          ),
          if (blocked)
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(_buttonH)),
              onPressed: onOpenSettings,
              child: Text(l.wifiScanOpenSettings),
            ),
          manual,
        ],
      _ => [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(
              label: l.wifiScanHelpImageA11y,
              image: true,
              child: Container(
                width: _image,
                height: _image,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line, width: AppSize.hairline),
                  borderRadius: BorderRadius.circular(_imageRadius),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/images/panel-setup-qr.png',
                    fit: BoxFit.cover, filterQuality: FilterQuality.none),
              ),
            ),
            const SizedBox(width: AppSpace.l),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.wifiScanHelpTitle, style: _titleStyle),
                const SizedBox(height: AppSpace.xs),
                Text(l.wifiScanHelpBody, style: _bodyStyle),
              ]),
            ),
          ]),
          manual,
        ],
    };
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: _pad,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              children[i],
            ],
          ]),
        ),
      ),
    );
  }
}
