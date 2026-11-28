import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../domain/models/library_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/result.dart';
import '../../core/labels.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/status_banner.dart';
import '../view_models/library_tab_view_model.dart';
import 'library_grid.dart';
import 'photo_dialogs.dart';

/// Tab Ảnh as Kho ảnh (screen_specs §2, 2026-11-28.11; R-AK-1…5): thanh báo thêm / xoá lỗi, thẻ "KHO ẢNH" (dòng nguồn
/// ảnh, lưới mới nhất trước / kho trống), ghi chú bộ đệm và nút "Hiện Ảnh trên thiết bị" (không có khi kho trống).
class LibraryTab extends StatefulWidget {
  const LibraryTab({
    super.key,
    required this.viewModel,
    required this.source,
    required this.onCrop,
    required this.showButton,
  });

  final LibraryTabViewModel viewModel;

  /// `photo_source` of `/api/state`.
  final PhotoSourceInfo source;

  /// Open PhotoCrop in library mode; completes with the crop on "Thêm vào kho", null when closed.
  final Future<PhotoPixels?> Function(Uint8List image) onCrop;

  /// `ShowOnDeviceButton`, under the note.
  final Widget showButton;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  LibraryTabViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    Future.microtask(_vm.load);
    _resumeLost();
  }

  Future<void> _resumeLost() async {
    final lost = await _vm.lostPick();
    if (lost != null && mounted) await _crop(lost);
  }

  Future<void> _crop(Uint8List image) async {
    final pixels = await widget.onCrop(image);
    if (pixels != null) await _vm.add(pixels);
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

  Future<void> _askDelete(LibraryItem item) async {
    if (await showDeleteLibraryPhotoDialog(context, item.preview)) await _vm.delete(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final items = _vm.items;
        final empty = items != null && _vm.count == 0;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_vm.addError != null)
            StatusBanner(
              title: l.photoLibraryAddErrorTitle,
              titleColor: AppColors.coral,
              body: l.photoLibraryAddErrorBody,
              trailing: TextButton(onPressed: _vm.retryAdd, child: Text(l.commonRetry)),
            ),
          if (_vm.deleteError != null)
            StatusBanner(
              title: l.photoDeleteErrorTitle,
              titleColor: AppColors.coral,
              body: l.photoLibraryDeleteErrorBody,
              trailing: TextButton(onPressed: _vm.retryDelete, child: Text(l.commonRetry)),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Header(count: items == null ? null : _vm.count, cacheMax: _vm.cacheMax),
                if (items == null)
                  const _Loading()
                else if (empty)
                  _Empty(onAdd: _add)
                else ...[
                  const SizedBox(height: AppSpace.m),
                  PhotoSourceStatus(source: widget.source),
                  const SizedBox(height: AppSpace.m),
                  LibraryGrid(
                    items: items,
                    adding: _vm.adding != null,
                    deleting: _vm.deleting,
                    onDevice: _vm.onDevice,
                    showingId: _vm.showingId(widget.source),
                    onTap: _askDelete,
                    onAdd: _add,
                  ),
                ],
              ]),
            ),
          ),
          if (items != null && !empty) ...[const _Note(), widget.showButton],
        ]);
      },
    );
  }
}

/// "KHO ẢNH" + meta muted: "23 ảnh · 8 trên máy" (> 8), "5 ảnh · cả 5 trên máy", "chưa có ảnh"; none while loading.
class _Header extends StatelessWidget {
  const _Header({required this.count, required this.cacheMax});

  final int? count;
  final int cacheMax;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = count;
    final meta = switch (n) {
      null => '',
      0 => l.photoLibraryCountEmpty,
      _ when n > cacheMax => l.photoLibraryCount('$n', '$cacheMax'),
      _ => l.photoLibraryCountAll('$n'),
    };
    return Row(children: [
      Text(l.photoLibraryTitle, style: AppFonts.label),
      const SizedBox(width: AppSpace.s),
      Expanded(
        child: Text(meta, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.label),
      ),
    ]);
  }
}

/// `libraryEmpty`: đệm 28 8 8, cách 10 — icon ảnh ×3 muted, `photoLibraryEmptyTitle` 16/700, `photoLibraryEmptyBody`
/// 13 inkDim; nút đặc mint cao 48 bo 24 "+ Thêm ảnh".
class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  static const _pad = EdgeInsets.fromLTRB(AppSpace.s, 28, AppSpace.s, AppSpace.s);
  static const _iconScale = 3.0;
  static const _gap = 10.0;
  static const _title = 16.0, _plus = 20.0, _body = 13.0, _bodyLine = 18 / 13;
  static const _buttonH = 48.0, _buttonRadius = 24.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: _pad,
      child: Column(children: [
        SkillStyle.dockIcon('photo', color: AppColors.muted, scale: _iconScale),
        const SizedBox(height: _gap),
        Text(l.photoLibraryEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: AppFonts.family, fontSize: _title, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: _gap),
        Text(l.photoLibraryEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: AppFonts.family, fontSize: _body, height: _bodyLine, color: AppColors.inkDim)),
        const SizedBox(height: _gap),
        FilledButton(
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
      ]),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  static const _height = 120.0;

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: _height, child: Center(child: CircularProgressIndicator()));
}

/// Icon tv 12 mint + `photoLibraryNote` 12 muted (lề 6 20 0).
class _Note extends StatelessWidget {
  const _Note();

  static const _icon = 12.0, _iconTop = 2.0;
  static const _pad = EdgeInsets.fromLTRB(AppSpace.xl, 6, AppSpace.xl, 0);
  static const _line = 16 / 12;

  @override
  Widget build(BuildContext context) => Padding(
        padding: _pad,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: _iconTop),
            child: Icon(Icons.tv, size: _icon, color: AppColors.mint),
          ),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Text(AppLocalizations.of(context).photoLibraryNote,
                style: AppFonts.label.copyWith(height: _line, letterSpacing: 0)),
          ),
        ]),
      );
}
