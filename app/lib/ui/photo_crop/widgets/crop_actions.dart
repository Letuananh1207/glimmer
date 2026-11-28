import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/photo_crop_view_model.dart';

/// Đáy màn Cắt ảnh theo trạng thái (screen_specs §7): đệm 16 16 24, cách 12 — hai nút / thẻ tiến độ + Huỷ / thẻ xong
/// + hai nút / thanh báo lỗi + nút.
class CropActions extends StatelessWidget {
  const CropActions({
    super.key,
    required this.status,
    required this.progress,
    required this.sentCount,
    required this.maxCount,
    required this.onSend,
    required this.onCancel,
    required this.onBackToCrop,
    required this.onPickOther,
    required this.onClose,
    this.library = false,
  });

  final CropStatus status;
  final double progress;

  /// Done: photos on the device now.
  final int sentCount;
  final int maxCount;
  final VoidCallback onSend, onCancel, onBackToCrop, onPickOther, onClose;

  /// Kho ảnh (design 2026-11-28.11): the send button reads `photoCropAddToLibrary`.
  final bool library;

  static const _pad = EdgeInsets.fromLTRB(AppSpace.l, AppSpace.l, AppSpace.l, AppSpace.xxl);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pickOther = _Pill(label: l.photoCropPickOther, icon: Icons.photo_library, onPressed: onPickOther);
    final retry = _Pill(label: l.commonRetry, primary: true, onPressed: onSend);
    final backToList = _Pill(label: l.photoCropBackToList, onPressed: onClose);
    final cancel = _Pill(label: l.commonCancel, onPressed: onBackToCrop);
    final children = switch (status) {
      CropStatus.loading => const <Widget>[],
      CropStatus.unreadable => [
          _Alert(title: l.devPhotoUnreadableTitle, body: l.devPhotoUnreadableBody),
          _Buttons([_Pill(label: l.photoCropPickOther, icon: Icons.photo_library, primary: true, onPressed: onPickOther)]),
        ],
      CropStatus.crop => [
          _Buttons([pickOther, library
              ? _Pill(label: l.photoCropAddToLibrary, icon: Icons.add, primary: true, onPressed: onSend)
              : _Pill(label: l.photoCropSend, icon: Icons.send, primary: true, onPressed: onSend)]),
        ],
      CropStatus.sending => [
          _Sending(progress: progress),
          _Buttons([_Pill(label: l.commonCancel, onPressed: onCancel)]),
        ],
      CropStatus.done => [
          _Done(count: sentCount, max: maxCount),
          _Buttons([
            _Pill(label: l.photoCropAddAnother, onPressed: onPickOther),
            _Pill(label: l.photoCropDone, primary: true, onPressed: onClose),
          ]),
        ],
      CropStatus.full => [
          _Alert(title: l.photoCropErrorFullTitle(maxCount), body: l.photoCropErrorFullBody),
          _Buttons([backToList]),
        ],
      CropStatus.tooBig => [
          _Alert(title: l.photoCropErrorTooBigTitle, body: l.photoCropErrorTooBigBody),
          _Buttons([pickOther, _Pill(label: l.photoCropRecrop, primary: true, onPressed: onBackToCrop)]),
        ],
      CropStatus.noSpace => [
          _Alert(title: l.photoCropErrorNoSpaceTitle, body: l.photoCropErrorNoSpaceBody),
          _Buttons([backToList, retry]),
        ],
      CropStatus.rejected => [
          _Alert(title: l.photoCropErrorRejectedTitle, body: l.photoCropErrorRejectedBody),
          _Buttons([cancel, retry]),
        ],
      CropStatus.offline => [
          _Alert(title: l.photoCropErrorOfflineTitle, body: l.photoCropErrorOfflineBody),
          _Buttons([cancel, retry]),
        ],
    };
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: _pad,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.m),
          children[i],
        ],
      ]),
    );
  }
}

const _bodySize = 13.0, _bodyLine = 18 / 13;
const _bodyStyle = TextStyle(fontFamily: AppFonts.family, fontSize: _bodySize, height: _bodyLine, color: AppColors.inkDim);

class _Buttons extends StatelessWidget {
  const _Buttons(this.buttons);

  final List<Widget> buttons;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(child: buttons[i]),
        ],
      ]);
}

/// Nút cao 48 bo 24: viền `line` chữ ink 500 (icon 18 inkDim), hoặc nền mint chữ bg 700.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onPressed, this.icon, this.primary = false});

  final String label;
  final IconData? icon;
  final bool primary;
  final VoidCallback onPressed;

  static const _height = 48.0, _radius = 24.0, _icon = 18.0;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
    final text = AppFonts.button.copyWith(fontWeight: primary ? FontWeight.w700 : FontWeight.w500);
    final child = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, size: _icon, color: primary ? AppColors.bg : AppColors.inkDim),
        const SizedBox(width: AppSpace.s),
      ],
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
    const size = Size(0, _height);
    const pad = EdgeInsets.symmetric(horizontal: AppSpace.m);
    return primary
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.bg,
              minimumSize: size,
              padding: pad,
              shape: shape,
              textStyle: text,
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line, width: AppSize.hairline),
              minimumSize: size,
              padding: pad,
              shape: shape,
              textStyle: text,
            ),
            child: child,
          );
  }
}

/// Thẻ `panel` bo 14 đệm 16.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpace.l),
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
        child: child,
      );
}

/// `sending`: vòng xoay 24 mint + `photoCropSending` 14 ink + phần trăm 14/700 mint; thanh 6 bo 3; `photoCropKeepOpen`.
class _Sending extends StatelessWidget {
  const _Sending({required this.progress});

  final double progress;

  static const _spinner = 24.0, _stroke = 3.0, _bar = 6.0, _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pct = (progress.clamp(0, 1) * 100).round();
    return _Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const SizedBox.square(
            dimension: _spinner,
            child: CircularProgressIndicator(strokeWidth: _stroke, color: AppColors.mint),
          ),
          const SizedBox(width: AppSpace.m),
          Expanded(child: Text(l.photoCropSending, style: AppFonts.body.copyWith(color: AppColors.ink))),
          Text('$pct%', style: AppFonts.body.copyWith(color: AppColors.mint, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: _gap),
        Semantics(
          value: '$pct%',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSize.radiusUsageBar),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: _bar,
              color: AppColors.mint,
              backgroundColor: AppColors.panel2,
            ),
          ),
        ),
        const SizedBox(height: _gap),
        Text(l.photoCropKeepOpen, style: AppFonts.label.copyWith(letterSpacing: 0)),
      ]),
    );
  }
}

/// `done`: vòng 32 nền mint 16 % dấu tích 20 mint + `photoCropDoneTitle` 15/700, `photoCropDoneBody` 13 inkDim.
class _Done extends StatelessWidget {
  const _Done({required this.count, required this.max});

  final int count, max;

  static const _ring = 32.0, _check = 20.0, _title = 15.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Panel(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: _ring,
          height: _ring,
          decoration: const BoxDecoration(color: AppColors.skillPhotoTint, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: _check, color: AppColors.mint),
        ),
        const SizedBox(width: AppSpace.m),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.photoCropDoneTitle,
                style: const TextStyle(
                    fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: AppSpace.xs),
            Text(l.photoCropDoneBody(count, max), style: _bodyStyle),
          ]),
        ),
      ]),
    );
  }
}

/// Thanh báo lỗi (`role=alert`): `panel2` bo 14 đệm 14 16 — tiêu đề 14/700 coral + nội dung 13 inkDim.
class _Alert extends StatelessWidget {
  const _Alert({required this.title, required this.body});

  final String title, body;

  static const _pad = EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 14);

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: _pad,
          decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: AppFonts.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.coral)),
            const SizedBox(height: AppSpace.xs),
            Text(body, style: _bodyStyle),
          ]),
        ),
      );
}
