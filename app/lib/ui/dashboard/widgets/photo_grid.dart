import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/models/device_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Lưới ảnh tab Ảnh (components.md `PhotoGrid`, screen_specs §2): 3 cột cách 8, ô vuông bo 10 (`photoTile`) — hình
/// thu nhỏ / ô "không có bản xem", rồi [AddPhotoTile] cuối.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.items,
    required this.deleting,
    required this.full,
    required this.maxCount,
    required this.onTap,
    required this.onAdd,
  });

  final List<GalleryPhoto> items;

  /// Names being deleted (spinner over the tile).
  final Set<String> deleting;
  final bool full;
  final int maxCount;
  final ValueChanged<GalleryPhoto> onTap;
  final VoidCallback onAdd;

  static const _columns = 3;
  static const _gap = AppSpace.s;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: _columns,
        mainAxisSpacing: _gap,
        crossAxisSpacing: _gap,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < items.length; i++)
            PhotoTile(
              key: ValueKey(items[i].name),
              item: items[i],
              index: i + 1,
              deleting: deleting.contains(items[i].name),
              onTap: () => onTap(items[i]),
            ),
          AddPhotoTile(locked: full, maxCount: maxCount, onTap: onAdd),
        ],
      );
}

/// One device photo: the app's copy covering the tile, or "không có bản xem". The whole tile asks to delete.
class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.item, required this.index, required this.deleting, required this.onTap});

  final GalleryPhoto item;

  /// 1-based, for "Ảnh 3, bấm để xoá".
  final int index;
  final bool deleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final preview = item.preview;
    return Semantics(
      button: true,
      label: preview != null ? l.photoTileA11y(index) : l.photoUnknownA11y(item.name),
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.radiusPhotoTile),
        child: Stack(fit: StackFit.expand, children: [
          if (preview != null) PhotoThumb(bytes: preview) else NoPreviewTile(name: item.name),
          Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: deleting ? null : onTap),
          ),
          if (deleting) const _Deleting(),
        ]),
      ),
    );
  }
}

/// The app's JPEG copy, covering its box (a damaged copy → plain `panel2`).
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) =>
      Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.panel2),
      );
}

/// A photo the app has no copy of (sent from the device's web page or another phone): `panel2`, photo icon ×1.75
/// muted, file name 11 inkDim, `photoNoPreview` 10 muted.
class NoPreviewTile extends StatelessWidget {
  const NoPreviewTile({super.key, required this.name});

  final String name;

  static const _iconScale = 1.75;
  static const _name = 11.0, _note = 10.0;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ColoredBox(
      color: AppColors.panel2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SkillStyle.dockIcon('photo', color: AppColors.muted, scale: _iconScale),
          const SizedBox(height: _gap),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: AppFonts.family, fontSize: _name, color: AppColors.inkDim)),
          const SizedBox(height: _gap),
          Text(l.photoNoPreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: AppFonts.family, fontSize: _note, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

/// `photoDeleting`: bg 66 % over the tile, spinner 24 mint + "Đang xoá" 11 ink.
class _Deleting extends StatelessWidget {
  const _Deleting();

  static const _veil = 0.66;
  static const _spinner = 24.0, _stroke = 3.0;
  static const _text = 11.0;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.bg.withValues(alpha: _veil),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox.square(
            dimension: _spinner,
            child: CircularProgressIndicator(strokeWidth: _stroke, color: AppColors.mint),
          ),
          const SizedBox(height: _gap),
          Text(AppLocalizations.of(context).photoDeleting,
              style: const TextStyle(fontFamily: AppFonts.family, fontSize: _text, color: AppColors.ink)),
        ]),
      );
}

/// Ô "+ Thêm ảnh" cuối lưới (components.md `AddPhotoTile`): viền 1.5 đứt mint, nền mint 8 %, "+" 28 + `photoAdd`
/// 13/500 mint. [locked] (đủ ảnh): viền 1 đứt `line`, ổ khoá 20 + `photoFullTile` 12 muted, không bấm được.
class AddPhotoTile extends StatelessWidget {
  const AddPhotoTile({super.key, required this.locked, required this.maxCount, required this.onTap});

  final bool locked;
  final int maxCount;
  final VoidCallback onTap;

  static const _tint = 0.08;
  static const _border = 1.5;
  static const _plus = 28.0, _label = 13.0, _lockedLabel = 12.0, _lock = 20.0;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.radiusPhotoTile));
    final content = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (locked)
        const Icon(Icons.lock_outline, size: _lock, color: AppColors.muted)
      else
        const Text('+',
            style: TextStyle(fontFamily: AppFonts.family, fontSize: _plus, height: 1, color: AppColors.mint)),
      const SizedBox(height: _gap),
      Text(
        locked ? l.photoFullTile(maxCount) : l.photoAdd,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: locked ? _lockedLabel : _label,
          fontWeight: locked ? FontWeight.w400 : FontWeight.w500,
          color: locked ? AppColors.muted : AppColors.mint,
        ),
      ),
    ]);
    return Semantics(
      button: !locked,
      enabled: !locked,
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: locked ? AppColors.line : AppColors.mint,
          width: locked ? AppSize.hairline : _border,
          radius: AppSize.radiusPhotoTile,
        ),
        child: Material(
          color: locked ? Colors.transparent : AppColors.mint.withValues(alpha: _tint),
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: locked ? null : onTap, child: content),
        ),
      ),
    );
  }
}

/// Dashed rounded-rect outline (CSS `border: dashed`).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.width, required this.radius});

  final Color color;
  final double width;
  final double radius;

  static const _dash = 4.0, _space = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += _dash + _space) {
        canvas.drawPath(m.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color || old.width != width || old.radius != radius;
}
