import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Màn Ảnh của thiết bị thu nhỏ ×0.75 (components.md `DevicePhotoPreview`, screen_specs §7; panel `Photo.png`): ô 180
/// nền đen bo 6 viền `line` — tiêu đề "Ảnh" 12 ink giữa, meta "6/6" 10 muted phải, kẻ mint, dock dọc trái (tab Ảnh nền
/// `panel2` + vạch mint), vùng ảnh 141 tại (30, 21) = đúng vùng đang cắt, vạch tiến độ 2 mint ở đáy.
class DevicePhotoPreview extends StatelessWidget {
  const DevicePhotoPreview({super.key, required this.image, required this.crop, required this.meta});

  final ui.Image? image;
  final Rect crop;

  /// "6/6".
  final String meta;

  static const _radius = 6.0;
  static const _title = 12.0, _meta = 10.0;
  static const _titleTop = 2.0, _metaTop = 3.0, _metaRight = 5.0, _ruleTop = 18.0;
  static const _photoLeft = 30.0, _photoTop = 21.0;
  static const _barBottom = 6.0, _barH = 2.0, _barShare = 0.4;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      image: true,
      label: l.photoCropPreview,
      excludeSemantics: true,
      child: Container(
        width: AppSize.devicePreview,
        height: AppSize.devicePreview,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: AppColors.line, width: AppSize.hairline),
        ),
        child: Stack(children: [
          Positioned(
            top: _titleTop,
            left: 0,
            right: 0,
            child: Text(l.skillPhotoName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: AppFonts.family, fontSize: _title, height: 1.2, color: AppColors.ink)),
          ),
          Positioned(
            top: _metaTop,
            right: _metaRight,
            child: Text(meta,
                style: const TextStyle(fontFamily: AppFonts.family, fontSize: _meta, height: 1.2, color: AppColors.muted)),
          ),
          const Positioned(
            top: _ruleTop,
            left: 0,
            right: 0,
            height: AppSize.hairline,
            child: ColoredBox(color: AppColors.mint),
          ),
          const Positioned(left: 2, top: 26, child: _Dock()),
          Positioned(
            left: _photoLeft,
            top: _photoTop,
            width: AppSize.devicePreviewPhoto,
            height: AppSize.devicePreviewPhoto,
            child: CustomPaint(painter: _PhotoPainter(image, crop)),
          ),
          const Positioned(
            left: 0,
            bottom: _barBottom,
            width: AppSize.devicePreview * _barShare,
            height: _barH,
            child: ColoredBox(color: AppColors.mint),
          ),
        ]),
      ),
    );
  }
}

/// Dock dọc của thiết bị ×0.75: rộng 22, đệm 3 1, viền `line` bo 3, ô 24 cách 4.
class _Dock extends StatelessWidget {
  const _Dock();

  static const _width = 22.0, _cell = 24.0, _gap = 4.0, _radius = 3.0;
  static const _scale = 0.75;
  static const _barW = 2.0, _barH = 12.0, _barTop = 6.0;

  static const _tabs = ['agent', 'photo', 'weather', 'clock'];

  @override
  Widget build(BuildContext context) => Container(
        width: _width,
        padding: const EdgeInsets.symmetric(vertical: _radius, horizontal: 1),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line, width: AppSize.hairline),
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Column(children: [
          for (var i = 0; i < _tabs.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            Stack(clipBehavior: Clip.none, children: [
              Container(
                height: _cell,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tabs[i] == 'photo' ? AppColors.panel2 : null,
                  borderRadius: BorderRadius.circular(_radius),
                ),
                child: SkillStyle.dockIcon(_tabs[i],
                    color: switch (_tabs[i]) {
                      'agent' => AppColors.clawd,
                      'photo' => AppColors.ink,
                      _ => AppColors.inkDim,
                    },
                    scale: _scale),
              ),
              if (_tabs[i] == 'photo')
                const Positioned(
                  left: -_barW,
                  top: _barTop,
                  width: _barW,
                  height: _barH,
                  child: ColoredBox(color: AppColors.mint),
                ),
            ]),
          ],
        ]),
      );
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.image, this.crop);

  final ui.Image? image;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null || crop.isEmpty) return;
    canvas.drawImageRect(img, crop, Offset.zero & size, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_PhotoPainter old) => old.image != image || old.crop != crop;
}
