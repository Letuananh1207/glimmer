import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_text.dart';
import '../../../core/themes/xp_colors.dart';
import '../../../../domain/models/mirror_frame.dart';
import 'mirror_channel.dart';
import 'xp_canvas.dart';
import 'xp_taskbar.dart';

/// Ô màn thiết bị (components.md `DeviceMirror`, screen_specs §8): vỏ 312 bo 22 gradient 160° `deviceShellTop` →
/// `deviceShellBottom`, viền sáng trong 1 px trắng 8 %, bóng 0 10 24 đen 50 %, đệm 10; màn 292 đen bo 6 đệm 2; vùng vẽ
/// 288 = 240 px thiết bị × 1.2, vẽ bằng [MirrorChannel] của kênh đang hiện + thanh tác vụ. Cả ô là một nút: chạm →
/// [onTap], vuốt trái → [onNext], vuốt phải → [onPrev].
class DeviceMirror extends StatelessWidget {
  const DeviceMirror({
    super.key,
    required this.frame,
    required this.semanticLabel,
    this.onTap,
    this.onNext,
    this.onPrev,
    this.dim = 0,
    this.offline = false,
    this.chip,
    this.channels,
  });

  /// What the device shows; null = nothing read yet (black screen).
  final MirrorFrame? frame;
  final String semanticLabel;
  final VoidCallback? onTap, onNext, onPrev;

  /// Black veil 0…1 over the screen (brightness being dragged, illustration only).
  final double dim;

  /// No answer from the device: last picture under a bg 72 % veil + "Mất kết nối".
  final bool offline;

  /// Floating chip on the shell's top right (top −10, right 10), e.g. "Đang gửi…".
  final Widget? chip;

  /// Painter registry (tests); default [mirrorChannels].
  final Map<String, MirrorChannel>? channels;

  static const _pad = 10.0;
  static const _screenPad = 2.0;
  static const _screenRadius = 6.0;
  static const _rim = 0.08;
  static const _shadowBlur = 24.0;
  static const _shadowY = 10.0;
  static const _shadowAlpha = 0.5;
  static const _chipTop = -10.0;
  static const _chipRight = 10.0;
  static const _offlineVeil = 0.72;
  static const _offlineGap = 6.0;

  /// Swipe speed (logical px / s) that counts as a channel step.
  static const _flingSpeed = 200.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = frame;
    Widget screen = SizedBox.square(
      dimension: AppSize.deviceScreen,
      child: f == null
          ? const ColoredBox(color: XpColors.black)
          : f.screenOff
          ? _ScreenOff(label: l.controlScreenOffOverlay)
          : RepaintBoundary(child: CustomPaint(painter: _MirrorPainter(f, l, channels ?? mirrorChannels))),
    );
    if (dim > 0 && f != null && !f.screenOff) {
      screen = Stack(
        children: [
          screen,
          Positioned.fill(
            child: ColoredBox(color: XpColors.black.withValues(alpha: dim.clamp(0.0, 1.0))),
          ),
        ],
      );
    }
    if (offline) {
      screen = Stack(
        children: [
          screen,
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.bg.withValues(alpha: _offlineVeil),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.controlOfflineOverlay,
                    style: AppFonts.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: _offlineGap),
                  Text(l.controlOfflineOverlayNote, style: AppFonts.label.copyWith(letterSpacing: 0)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final shell = Container(
      width: AppSize.deviceShell,
      height: AppSize.deviceShell,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.radiusDeviceShell),
        gradient: const LinearGradient(
          // 160°: from the top (slightly left) to the bottom (slightly right).
          begin: Alignment(-0.36, -1),
          end: Alignment(0.36, 1),
          colors: [AppColors.deviceShellTop, AppColors.deviceShellBottom],
        ),
        boxShadow: [
          BoxShadow(
            color: XpColors.black.withValues(alpha: _shadowAlpha),
            blurRadius: _shadowBlur,
            offset: const Offset(0, _shadowY),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -_flingSpeed) onNext?.call();
            if (v > _flingSpeed) onPrev?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(_screenPad),
            decoration: BoxDecoration(color: XpColors.black, borderRadius: BorderRadius.circular(_screenRadius)),
            clipBehavior: Clip.antiAlias,
            child: screen,
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        shell,
        // Inner top highlight (inset 0 1 0 white 8 %), between the rounded corners.
        Positioned(
          top: 0,
          left: AppSize.radiusDeviceShell,
          right: AppSize.radiusDeviceShell,
          height: AppSize.hairline,
          child: IgnorePointer(
            child: ColoredBox(color: AppColors.outline.withValues(alpha: _rim)),
          ),
        ),
        if (chip != null) Positioned(top: _chipTop, right: _chipRight, child: chip!),
      ],
    );
  }
}

/// Backlight off: `screenOff` plate + "MÀN ĐANG TẮT" 12.
class _ScreenOff extends StatelessWidget {
  const _ScreenOff({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.screenOff,
    child: Center(
      child: Text(label, style: AppFonts.label.copyWith(color: AppColors.line)),
    ),
  );
}

/// Paints [frame] at device pixels × [AppSize.deviceScale]: the channel's painter, then the taskbar (unless the
/// channel has none). Unknown channels fall back to a titled window.
class _MirrorPainter extends CustomPainter {
  _MirrorPainter(this.frame, this.l, this.channels);

  final MirrorFrame frame;
  final AppLocalizations l;
  final Map<String, MirrorChannel> channels;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / XpCanvas.side);
    final c = XpCanvas(canvas);
    c.fill(0, 0, XpCanvas.side, XpCanvas.side, XpColors.black);
    final ch = channels[frame.channel] ?? fallbackChannel(frame.channel);
    ch.paint(c, frame, l);
    if (ch.hasTaskbar) XpTaskbar.paint(c, frame.taskbar, frame.trayClock);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MirrorPainter old) => old.frame != frame || old.l != l || old.channels != channels;
}
