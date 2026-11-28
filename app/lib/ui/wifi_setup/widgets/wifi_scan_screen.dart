import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/wifi_scan_view_model.dart';
import 'scan_panel.dart';
import 'scan_viewfinder.dart';

/// Quét mã (screen_specs §10, design 2026-11-28.12): camera toàn màn, khung ngắm 240 giữa, thanh trên × + tiêu đề, bảng
/// dưới theo trạng thái. Đọc được mã glimmer → rung nhẹ, ~0,6 s rồi [onFound]; "Không có mã? Nhập tay" → [onManual].
class WifiScanScreen extends StatefulWidget {
  const WifiScanScreen({
    super.key,
    required this.viewModel,
    required this.onFound,
    required this.onManual,
    required this.onClose,
  });

  final WifiScanViewModel viewModel;

  /// The display's setup code (R-WF-4): close and go on to Cài Wi-Fi at the right step.
  final ValueChanged<String> onFound;

  /// Cài Wi-Fi `form`.
  final VoidCallback onManual;

  /// × — back to the screen that opened it.
  final VoidCallback onClose;

  @override
  State<WifiScanScreen> createState() => _WifiScanScreenState();
}

class _WifiScanScreenState extends State<WifiScanScreen> {
  late final AppLifecycleListener _life;
  MobileScannerController? _camera;

  WifiScanViewModel get _vm => widget.viewModel;

  static const _barH = 64.0;
  static const _close = 48.0, _closeIcon = 26.0;
  static const _title = 18.0;
  static const _barShade = 0.55;
  static const _noCamIcon = 56.0, _noCamTitle = 16.0, _noCamBody = 13.0, _bodyLine = 18 / 13;
  static const _noCamGap = 10.0;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: _vm.resumed);
    _vm.addListener(_syncCamera);
    _vm.start();
  }

  /// The preview runs only while the camera is allowed.
  void _syncCamera() {
    if (_vm.cameraOn && _camera == null) {
      setState(() => _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode]));
    }
  }

  Future<void> _detect(BarcodeCapture capture) async {
    for (final b in capture.barcodes) {
      final before = _vm.state;
      final raw = await _vm.detected(b.rawValue);
      if (_vm.state != before && _vm.state == ScanState.found) await HapticFeedback.lightImpact();
      if (raw != null && mounted) widget.onFound(raw);
      if (_vm.state != ScanState.scanning) return;
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_syncCamera);
    _life.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final camera = _camera;
          final state = _vm.state;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (camera != null && _vm.cameraOn)
                MobileScanner(controller: camera, onDetect: _detect, fit: BoxFit.cover),
              if (_vm.cameraOn) ScanViewfinder(state: state),
              if (state == ScanState.noCamera)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: _noCamIcon, color: AppColors.muted),
                        const SizedBox(height: _noCamGap),
                        Text(
                          l.wifiScanCameraTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: _noCamTitle,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: _noCamGap),
                        Text(
                          l.wifiScanCameraBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: _noCamBody,
                            height: _bodyLine,
                            color: AppColors.inkDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: _barShade),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: _barH,
                      child: Row(
                        children: [
                          const SizedBox(width: AppSpace.s),
                          SizedBox.square(
                            dimension: _close,
                            child: IconButton(
                              tooltip: l.wifiScanCloseA11y,
                              icon: const Icon(Icons.close, size: _closeIcon, color: AppColors.ink),
                              onPressed: widget.onClose,
                            ),
                          ),
                          const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: Text(
                              l.wifiScanTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppFonts.family,
                                fontSize: _title,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ScanPanel(
                  state: state,
                  blocked: _vm.blocked,
                  onManual: widget.onManual,
                  onScanAgain: _vm.scanAgain,
                  onAllow: _vm.allow,
                  onOpenSettings: _vm.openSettings,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
