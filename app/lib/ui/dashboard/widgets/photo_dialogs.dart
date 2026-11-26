import 'package:flutter/material.dart';

import '../../../domain/models/device_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import 'photo_grid.dart';

/// Lớp phủ đen 60 % dưới hộp thoại / bảng (screen_specs §2).
const _scrimAlpha = 0.6;
Color get _scrim => Colors.black.withValues(alpha: _scrimAlpha);

/// Hỏi xoá ảnh (components.md `DeletePhotoDialog`): rộng 312, nền `panel`, bo 20, đệm 24, cách 14 —
/// `photoDeleteTitle` 18/700; hình 96 bo 10 + `photoDeleteBody` 13 inkDim; nút chữ Huỷ (inkDim) / Xoá (coral 700) cao 44.
/// Trả true khi chọn Xoá.
Future<bool> showDeletePhotoDialog(BuildContext context, GalleryPhoto photo) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: _scrim,
      builder: (_) => DeletePhotoDialog(photo: photo),
    ) ??
    false;

class DeletePhotoDialog extends StatelessWidget {
  const DeletePhotoDialog({super.key, required this.photo});

  final GalleryPhoto photo;

  static const _width = 312.0;
  static const _radius = 20.0;
  static const _gap = 14.0;
  static const _thumb = 96.0;
  static const _title = 18.0, _body = 13.0, _bodyLine = 18 / 13;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final preview = photo.preview;
    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      insetPadding: const EdgeInsets.all(AppSpace.xxl),
      child: SizedBox(
        width: _width,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.photoDeleteTitle,
                style: const TextStyle(
                    fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: _gap),
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSize.radiusPhotoTile),
                child: SizedBox.square(
                  dimension: _thumb,
                  child: preview != null ? PhotoThumb(bytes: preview) : NoPreviewTile(name: photo.name),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Text(l.photoDeleteBody,
                    style: const TextStyle(
                        fontFamily: AppFonts.family, fontSize: _body, height: _bodyLine, color: AppColors.inkDim)),
              ),
            ]),
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
                child: Text(l.photoDelete),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Bảng chọn nguồn ảnh (components.md `PhotoSourceSheet`): nền `panel`, bo trên 20, đệm 10 20 28 — tay nắm 36×4 `line`,
/// `photoAdd` 16/700, `photoAddHint` 12 muted, hai dòng ≥ 56 (icon 24 mint + 16 + chữ 15 ink, kẻ `line`), nút Huỷ
/// cao 48 bo 14 `panel2`. Trả nguồn đã chọn, null = huỷ.
Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) => showModalBottomSheet<PhotoSource>(
      context: context,
      useRootNavigator: true,
      barrierColor: _scrim,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.radiusSheet)),
      ),
      builder: (_) => const PhotoSourceSheet(),
    );

class PhotoSourceSheet extends StatelessWidget {
  const PhotoSourceSheet({super.key});

  static const _pad = EdgeInsets.fromLTRB(AppSpace.xl, 10, AppSpace.xl, 28);
  static const _handleW = 36.0, _handleH = 4.0, _handleGap = 14.0;
  static const _title = 16.0;
  static const _hintLine = 16 / 12;
  static const _cancelH = 48.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          const SizedBox(height: _handleGap),
          Text(l.photoAdd,
              style: const TextStyle(
                  fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs, bottom: AppSpace.s),
            child: Text(l.photoAddHint, style: AppFonts.label.copyWith(height: _hintLine, letterSpacing: 0)),
          ),
          _SourceRow(
            icon: Icons.photo_library,
            label: l.photoFromGallery,
            onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
          ),
          const Divider(height: AppSize.hairline, thickness: AppSize.hairline, color: AppColors.line),
          _SourceRow(
            icon: Icons.photo_camera,
            label: l.photoFromCamera,
            onTap: () => Navigator.of(context).pop(PhotoSource.camera),
          ),
          const SizedBox(height: AppSpace.s),
          SizedBox(
            height: _cancelH,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.panel2,
                foregroundColor: AppColors.inkDim,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.radiusCard)),
                textStyle: AppFonts.button.copyWith(fontWeight: FontWeight.w400),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.commonCancel),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const _icon = 24.0, _text = 15.0;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.listTile),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Row(children: [
              Icon(icon, size: _icon, color: AppColors.mint),
              const SizedBox(width: AppSpace.l),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontFamily: AppFonts.family, fontSize: _text, color: AppColors.ink)),
              ),
            ]),
          ),
        ),
      );
}
