import 'package:flutter/material.dart';

import '../../../domain/models/library_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import 'photo_grid.dart';

/// Lưới Kho ảnh (screen_specs §2, 2026-11-28.11): 3 cột cách 8 — ô "+ Thêm ảnh" đầu, ô đang thêm, rồi ảnh mới nhất
/// trước (`LibraryTile`).
class LibraryGrid extends StatelessWidget {
  const LibraryGrid({
    super.key,
    required this.items,
    required this.adding,
    required this.deleting,
    required this.onDevice,
    required this.showingId,
    required this.onTap,
    required this.onAdd,
  });

  /// Newest first.
  final List<LibraryItem> items;

  /// A photo is being added (`libraryAdding` tile after the add tile).
  final bool adding;
  final Set<int> deleting;

  /// R-AK-3: tile [i] is in the device's cache.
  final bool Function(int i) onDevice;

  /// The photo the device is showing (online only), null = none.
  final int? showingId;
  final ValueChanged<LibraryItem> onTap;
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
          AddPhotoTile(locked: false, maxCount: 0, onTap: onAdd),
          if (adding) const _AddingTile(),
          for (var i = 0; i < items.length; i++)
            LibraryTile(
              key: ValueKey(items[i].id),
              item: items[i],
              number: items.length - i,
              onDevice: onDevice(i),
              showing: items[i].id == showingId,
              deleting: deleting.contains(items[i].id),
              onTap: () => onTap(items[i]),
            ),
        ],
      );
}

/// Ô ảnh của kho (components.md `LibraryTile`): như `PhotoTile`, thêm dấu "trên máy" (ô 22 bo 6 nền `bg` 78 %, icon
/// tv 14 mint, cách mép 5) và viền trong 2 mint + nhãn ĐANG CHIẾU cho ảnh thiết bị đang chiếu. Cả ô là nút → hỏi xoá.
class LibraryTile extends StatelessWidget {
  const LibraryTile({
    super.key,
    required this.item,
    required this.number,
    required this.onDevice,
    required this.showing,
    required this.deleting,
    required this.onTap,
  });

  final LibraryItem item;

  /// 1-based place as added (oldest = 1), for "Ảnh 3…".
  final int number;
  final bool onDevice, showing, deleting;
  final VoidCallback onTap;

  static const _inset = 5.0;
  static const _badge = 22.0, _badgeRadius = 6.0, _badgeIcon = 14.0, _badgeVeil = 0.78;
  static const _ring = 2.0;
  static const _tag = 9.0, _tagRadius = 4.0;
  static const _tagPad = EdgeInsets.symmetric(vertical: 2, horizontal: 5);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final preview = item.preview;
    return Semantics(
      button: true,
      label: l.photoLibraryTileA11y(
        '$number',
        onDevice ? l.photoLibraryOnDeviceA11y : '',
        showing ? l.photoLibraryShowingA11y : '',
      ),
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.radiusPhotoTile),
        child: Stack(fit: StackFit.expand, children: [
          if (preview != null) PhotoThumb(bytes: preview) else NoPreviewTile(name: '#${item.id}'),
          if (onDevice)
            Positioned(
              right: _inset,
              bottom: _inset,
              child: Container(
                width: _badge,
                height: _badge,
                decoration: BoxDecoration(
                  color: AppColors.bg.withValues(alpha: _badgeVeil),
                  borderRadius: BorderRadius.circular(_badgeRadius),
                ),
                child: const Icon(Icons.tv, size: _badgeIcon, color: AppColors.mint),
              ),
            ),
          if (showing) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.mint, width: _ring),
                borderRadius: BorderRadius.circular(AppSize.radiusPhotoTile),
              ),
            ),
            Positioned(
              left: _inset,
              top: _inset,
              child: Container(
                padding: _tagPad,
                decoration:
                    BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(_tagRadius)),
                child: Text(l.photoLibraryShowingTag,
                    style: const TextStyle(
                        fontFamily: AppFonts.family, fontSize: _tag, fontWeight: FontWeight.w700, color: AppColors.bg)),
              ),
            ),
          ],
          Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: deleting ? null : onTap),
          ),
          if (deleting) _Busy(label: l.photoLibraryDeleting),
        ]),
      ),
    );
  }
}

/// `libraryAdding`: the new photo's tile — `panel2` under bg 66 %, spinner 24 mint + `photoLibraryAdding` 11 ink.
class _AddingTile extends StatelessWidget {
  const _AddingTile();

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.radiusPhotoTile),
        child: ColoredBox(
          color: AppColors.panel2,
          child: _Busy(label: AppLocalizations.of(context).photoLibraryAdding),
        ),
      );
}

/// bg 66 % over a tile, spinner 24 mint + [label] 11 ink (adding / deleting).
class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

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
          Text(label, style: const TextStyle(fontFamily: AppFonts.family, fontSize: _text, color: AppColors.ink)),
        ]),
      );
}

/// Dòng nguồn ảnh (components.md `PhotoSourceStatus`): nền `panel2` bo 10, đệm 10 12; chấm 8 + chữ 12 ink. Online:
/// chấm mint `photoSourceOnline`, phải `photoSourceShowing` 11 muted. Offline / chưa gửi nguồn: chấm muted
/// `photoSourceOffline` + dòng phụ `photoSourceOfflineBody` 11 muted thụt 16.
class PhotoSourceStatus extends StatelessWidget {
  const PhotoSourceStatus({super.key, required this.source});

  final PhotoSourceInfo source;

  static const _radius = 10.0;
  static const _pad = EdgeInsets.symmetric(vertical: 10, horizontal: AppSpace.m);
  static const _dot = 8.0, _dotGap = 8.0;
  static const _text = 12.0, _small = 11.0, _line = 16 / 12;
  static const _subGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = source.online;
    const main = TextStyle(fontFamily: AppFonts.family, fontSize: _text, height: _line, color: AppColors.ink);
    const small = TextStyle(fontFamily: AppFonts.family, fontSize: _small, height: _line, color: AppColors.muted);
    return Container(
      padding: _pad,
      decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(_radius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(color: online ? AppColors.mint : AppColors.muted, shape: BoxShape.circle),
          ),
          const SizedBox(width: _dotGap),
          Expanded(child: Text(online ? l.photoSourceOnline : l.photoSourceOffline, style: main)),
          if (online && source.index > 0 && source.count > 0) ...[
            const SizedBox(width: AppSpace.s),
            Text(l.photoSourceShowing('${source.index}', '${source.count}'), style: small),
          ],
        ]),
        if (!online)
          Padding(
            padding: const EdgeInsets.only(left: _dot + _dotGap, top: _subGap),
            child: Text(l.photoSourceOfflineBody, style: small),
          ),
      ]),
    );
  }
}
