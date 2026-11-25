import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/result.dart';
import '../../core/labels.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/status_banner.dart';
import '../view_models/photo_tab_view_model.dart';
import 'photo_dialogs.dart';
import 'photo_grid.dart';

/// Tab Ảnh của Màn hình (screen_specs §2, 2026-11-25.4): thanh báo xoá lỗi, thẻ "ẢNH TRÊN THIẾT BỊ" (lưới / chưa có
/// ảnh / đủ ảnh), chú thích cập nhật đầy đủ xoá ảnh. Nút "Hiện Ảnh trên thiết bị" do màn thêm sau.
class PhotoTab extends StatefulWidget {
  const PhotoTab({super.key, required this.viewModel, required this.deviceCount, required this.onCrop});

  final PhotoTabViewModel viewModel;

  /// `photos` of `/api/state`: a change (sent / deleted from the device web page) reloads the list.
  final int? deviceCount;

  /// Open PhotoCrop with a picked image; completes when it closes.
  final Future<void> Function(Uint8List image, PhotoInfo info) onCrop;

  @override
  State<PhotoTab> createState() => _PhotoTabState();
}

class _PhotoTabState extends State<PhotoTab> {
  PhotoTabViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    Future.microtask(_vm.load); // every time the tab opens (after this build)
    _resumeLost();
  }

  @override
  void didUpdateWidget(PhotoTab old) {
    super.didUpdateWidget(old);
    if (old.deviceCount != widget.deviceCount) Future.microtask(_vm.load);
  }

  /// Android may kill the app while the camera is open: pick the photo up again.
  Future<void> _resumeLost() async {
    final lost = await _vm.lostPick();
    if (lost != null && mounted) await _crop(lost);
  }

  Future<void> _crop(Uint8List image) async {
    await widget.onCrop(image, _vm.info);
    await _vm.load();
  }

  Future<void> _add() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    final r = await _vm.pick(source);
    if (!mounted) return;
    switch (r) {
      case Ok(:final value):
        if (value != null) await _crop(value);
      case Error(:final error):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).error(AppError.from(error)))));
    }
  }

  Future<void> _askDelete(GalleryPhoto photo) async {
    if (await showDeletePhotoDialog(context, photo)) await _vm.delete(photo.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final g = _vm.gallery;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_vm.deleteError != null)
            StatusBanner(
              title: l.photoDeleteErrorTitle,
              titleColor: AppColors.coral,
              body: l.photoDeleteErrorBody,
              trailing: TextButton(onPressed: _vm.retryDelete, child: Text(l.commonRetry)),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Header(info: g?.info),
                if (g == null && _vm.loadError != null)
                  _LoadError(error: _vm.loadError!, onRetry: _vm.load)
                else if (g == null)
                  const _Loading()
                else if (g.items.isEmpty)
                  _Empty(maxCount: g.info.maxCount, onAdd: _add)
                else ...[
                  const SizedBox(height: _gridTop),
                  PhotoGrid(
                    items: g.items,
                    deleting: _vm.deleting,
                    full: g.info.full,
                    maxCount: g.info.maxCount,
                    onTap: _askDelete,
                    onAdd: _add,
                  ),
                  if (g.info.full)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.m),
                      child: Text(l.photoFullBody(g.info.maxCount), style: _body),
                    ),
                ],
              ]),
            ),
          ),
          if (g != null && g.items.isNotEmpty) const _Note(),
        ]);
      },
    );
  }
}

const _gridTop = 14.0;
const _bodySize = 13.0, _bodyLine = 18 / 13;
const _body = TextStyle(fontFamily: AppFonts.family, fontSize: _bodySize, height: _bodyLine, color: AppColors.inkDim);

/// "ẢNH TRÊN THIẾT BỊ" + meta: "5/8 · còn 3 chỗ" muted, "0/8", "8/8 · hết chỗ" amber; none while loading.
class _Header extends StatelessWidget {
  const _Header({required this.info});

  final PhotoInfo? info;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final i = info;
    final (meta, color) = switch (i) {
      null => ('', AppColors.muted),
      _ when i.count == 0 => (l.photoCountEmpty(i.maxCount), AppColors.muted),
      _ when i.full => (l.photoCountFull(i.maxCount), AppColors.amber),
      _ => (l.photoCount(i.count, i.maxCount, i.left), AppColors.muted),
    };
    return Row(children: [
      Text(l.photoOnDevice, style: AppFonts.label),
      const SizedBox(width: AppSpace.s),
      Expanded(
        child: Text(meta,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.label.copyWith(color: color)),
      ),
    ]);
  }
}

/// `photoEmpty`: đệm 28 8 8 — icon ảnh ×3 muted, cách 10 `photoEmptyTitle` 16/700, `photoEmptyBody` 13 inkDim; nút đặc
/// mint cao 48 bo 24, "+" 20 + `photoAdd` 14/700 màu bg.
class _Empty extends StatelessWidget {
  const _Empty({required this.maxCount, required this.onAdd});

  final int maxCount;
  final VoidCallback onAdd;

  static const _pad = EdgeInsets.fromLTRB(AppSpace.s, 28, AppSpace.s, AppSpace.s);
  static const _iconScale = 3.0;
  static const _titleGap = 10.0;
  static const _title = 16.0, _plus = 20.0;
  static const _buttonH = 48.0, _buttonRadius = 24.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(children: [
      Padding(
        padding: _pad,
        child: Column(children: [
          SkillStyle.dockIcon('photo', color: AppColors.muted, scale: _iconScale),
          const SizedBox(height: _titleGap + AppSpace.s),
          Text(l.photoEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: AppSpace.s),
          Text(l.photoEmptyBody(maxCount), textAlign: TextAlign.center, style: _body),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.s),
        child: FilledButton(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.mint,
            foregroundColor: AppColors.bg,
            minimumSize: const Size(0, _buttonH),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
            textStyle: AppFonts.button.copyWith(fontWeight: FontWeight.w700),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('+', style: TextStyle(fontFamily: AppFonts.family, fontSize: _plus, height: 1)),
            const SizedBox(width: AppSpace.s),
            Text(l.photoAdd),
          ]),
        ),
      ),
    ]);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  static const _height = 120.0;

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: _height, child: Center(child: CircularProgressIndicator()));
}

/// GET /api/photos failed before anything loaded (not drawn in the design): title + reason + retry.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final AppError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: _gridTop),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.devPhotoLoadErrorTitle, style: AppFonts.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.coral)),
        const SizedBox(height: AppSpace.xs),
        Text(l.error(error), style: _body),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onRetry, child: Text(l.commonRetry)),
        ),
      ]),
    );
  }
}

/// Ô vuông 8 amber + `photoNote` 12 muted (lề 6 20 0): a full update erases the photos.
class _Note extends StatelessWidget {
  const _Note();

  static const _square = 8.0;
  static const _pad = EdgeInsets.fromLTRB(AppSpace.xl, 6, AppSpace.xl, 0);
  static const _line = 16 / 12;
  static const _squareTop = 4.0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: _pad,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: _square,
            height: _square,
            margin: const EdgeInsets.only(top: _squareTop),
            color: AppColors.amber,
          ),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Text(AppLocalizations.of(context).photoNote,
                style: AppFonts.label.copyWith(height: _line, letterSpacing: 0)),
          ),
        ]),
      );
}
