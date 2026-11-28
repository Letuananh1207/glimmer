import 'package:flutter/material.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/result.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/photo_crop_view_model.dart';
import 'crop_actions.dart';
import 'crop_frame.dart';
import 'device_photo_preview.dart';

/// Cắt ảnh (screen_specs §7, 2026-11-25.4): push từ tab Ảnh, ngoài khung tab. Thanh trên 56, `CropFrame`, gợi ý,
/// `DevicePhotoPreview` cập nhật theo khi kéo / phóng, đáy theo trạng thái gửi.
class PhotoCropScreen extends StatelessWidget {
  const PhotoCropScreen({super.key, required this.viewModel, required this.onClose, this.onAdd});

  final PhotoCropViewModel viewModel;

  /// Back to the Ảnh tab (back arrow, "Xong", "Về danh sách ảnh").
  final VoidCallback onClose;

  /// Kho ảnh (design 2026-11-28.11): "Thêm vào kho" → back to the Ảnh tab with the crop, which adds it.
  final ValueChanged<PhotoPixels>? onAdd;

  Future<void> _addToLibrary() async {
    final pixels = await viewModel.cropped();
    if (pixels != null) onAdd?.call(pixels);
  }

  static const _barH = 56.0;
  static const _back = 48.0, _backIcon = 24.0;
  static const _title = 18.0;
  static const _hintTop = 10.0;
  static const _labelPad = EdgeInsets.fromLTRB(AppSpace.xl, 14, AppSpace.xl, AppSpace.s);
  static const _sideTop = 4.0;
  static const _bodySize = 13.0, _bodyLine = 18 / 13, _noteLine = 16 / 12;

  Future<void> _pickOther(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final r = await viewModel.pickOther();
    if (r is Error<bool>) messenger.showSnackBar(SnackBar(content: Text(l.error(AppError.from(r.error)))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final vm = viewModel;
            final image = vm.image?.image;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                height: _barH,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
                  child: Row(children: [
                    SizedBox.square(
                      dimension: _back,
                      child: IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        icon: const Icon(Icons.arrow_back, size: _backIcon, color: AppColors.ink),
                        onPressed: onClose,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(l.photoCropTitle,
                        style: const TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: _title,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ]),
                ),
              ),
              CropFrame(
                image: image,
                crop: vm.crop,
                busy: vm.status == CropStatus.loading,
                semanticLabel: l.photoCropAreaA11y,
                onPan: vm.pan,
                onZoom: vm.zoom,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: _hintTop),
                      child: Text(l.photoCropHint,
                          textAlign: TextAlign.center, style: AppFonts.label.copyWith(letterSpacing: 0)),
                    ),
                    Padding(padding: _labelPad, child: Text(l.photoCropPreview, style: AppFonts.label)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        DevicePhotoPreview(image: image, crop: vm.crop, meta: '${vm.previewCount}/${vm.previewCount}'),
                        const SizedBox(width: AppSpace.l),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: _sideTop),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.photoCropPreviewBody,
                                  style: const TextStyle(
                                      fontFamily: AppFonts.family,
                                      fontSize: _bodySize,
                                      height: _bodyLine,
                                      color: AppColors.ink)),
                              const SizedBox(height: AppSpace.s),
                              Text(l.photoCropPreviewNote,
                                  style: AppFonts.label.copyWith(height: _noteLine, letterSpacing: 0)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
              CropActions(
                status: vm.status,
                progress: vm.progress,
                sentCount: vm.sent?.count ?? 0,
                maxCount: vm.maxCount,
                onSend: vm.library && onAdd != null ? _addToLibrary : vm.send,
                library: vm.library && onAdd != null,
                onCancel: vm.cancel,
                onBackToCrop: vm.backToCrop,
                onPickOther: () => _pickOther(context),
                onClose: onClose,
              ),
            ]);
          },
        ),
      ),
    );
  }
}
