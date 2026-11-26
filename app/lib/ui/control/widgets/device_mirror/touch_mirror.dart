import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_text.dart';
import '../../../core/themes/xp_colors.dart';
import '../../../../domain/models/mirror_frame.dart';
import 'mirror_channel.dart';
import 'xp_canvas.dart';
import 'xp_taskbar.dart';

/// Ô màn thiết bị chạm được (components.md `TouchMirror`, screen_specs §8, design 2026-11-26.6): vỏ 376 bo 20 gradient
/// 160° `deviceShellTop` → `deviceShellBottom`, viền sáng trong 1 px trắng 8 %, bóng 0 10 24 đen 50 %, đệm 6; màn 364
/// đen bo 6 đệm 2; vùng vẽ 360 = 240 px thiết bị × 1.5, vẽ bằng [MirrorChannel] của kênh đang hiện + thanh tác vụ.
/// Cả vùng là bề mặt chạm như chuột: chạm → [onTap] với toạ độ px thiết bị (÷ 1.5), giữ ≥ 500 ms → [onHold] (chuột
/// phải). Mỗi lần chạm hiện `TapRipple` tại điểm chạm.
class TouchMirror extends StatefulWidget {
  const TouchMirror({
    super.key,
    required this.frame,
    required this.semanticLabel,
    this.onTap,
    this.onHold,
    this.dim = 0,
    this.offline = false,
    this.chip,
    this.channels,
  });

  /// What the device shows; null = nothing read yet (black screen).
  final MirrorFrame? frame;
  final String semanticLabel;

  /// A touch at device pixels (x, y); null = touches off (ripple not shown either).
  final void Function(double x, double y)? onTap, onHold;

  /// Black veil 0…1 over the screen (brightness being dragged, illustration only).
  final double dim;

  /// No answer from the device: last picture under a bg 72 % veil + "Mất kết nối".
  final bool offline;

  /// `StatusChip` on the shell's top left (top −12, left 14).
  final Widget? chip;

  /// Painter registry (tests); default [mirrorChannels].
  final Map<String, MirrorChannel>? channels;

  @override
  State<TouchMirror> createState() => _TouchMirrorState();
}

class _TouchMirrorState extends State<TouchMirror> {
  static const _pad = 6.0;
  static const _screenPad = 2.0;
  static const _screenRadius = 6.0;
  static const _rim = 0.08;
  static const _shadowBlur = 24.0;
  static const _shadowY = 10.0;
  static const _shadowAlpha = 0.5;
  static const _chipTop = -12.0;
  static const _chipLeft = 14.0;
  static const _offlineVeil = 0.72;
  static const _offlineGap = 6.0;

  /// How long the ripple stays after a touch.
  static const _rippleFor = Duration(milliseconds: 450);

  Offset? _ripple;
  Timer? _rippleTimer;

  void _show(Offset p) {
    _rippleTimer?.cancel();
    setState(() => _ripple = p);
    _rippleTimer = Timer(_rippleFor, () {
      if (mounted) setState(() => _ripple = null);
    });
  }

  @override
  void dispose() {
    _rippleTimer?.cancel();
    super.dispose();
  }

  void _touch(Offset p, void Function(double x, double y)? on) {
    if (on == null) return;
    _show(p);
    on(p.dx / AppSize.deviceScale, p.dy / AppSize.deviceScale);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = widget.frame;
    Widget screen = SizedBox.square(
      dimension: AppSize.deviceScreen,
      child: f == null
          ? const ColoredBox(color: XpColors.black)
          : f.screenOff
          ? _ScreenOff(label: l.controlScreenOffOverlay)
          : RepaintBoundary(child: CustomPaint(painter: _MirrorPainter(f, l, widget.channels ?? mirrorChannels))),
    );
    final dim = widget.dim;
    screen = Stack(
      children: [
        screen,
        if (dim > 0 && f != null && !f.screenOff)
          Positioned.fill(
            child: ColoredBox(color: XpColors.black.withValues(alpha: dim.clamp(0.0, 1.0))),
          ),
        if (widget.offline)
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
        if (_ripple != null)
          Positioned(
            left: _ripple!.dx - AppSize.tapRipple / 2,
            top: _ripple!.dy - AppSize.tapRipple / 2,
            child: const IgnorePointer(child: TapRipple()),
          ),
      ],
    );
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
      child: Container(
        padding: const EdgeInsets.all(_screenPad),
        decoration: BoxDecoration(color: XpColors.black, borderRadius: BorderRadius.circular(_screenRadius)),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          label: widget.semanticLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.onTap == null ? null : (d) => _touch(d.localPosition, widget.onTap),
            onLongPressStart: widget.onHold == null ? null : (d) => _touch(d.localPosition, widget.onHold),
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
        if (widget.chip != null) Positioned(top: _chipTop, left: _chipLeft, child: widget.chip!),
      ],
    );
  }
}

/// `TapRipple` (§8): vòng 44 (`tapRipple`) viền 2 trắng, nền trắng 28 %, viền ngoài 4 `tapRing`.
class TapRipple extends StatelessWidget {
  const TapRipple({super.key});

  static const _border = 2.0;
  static const _fill = 0.28;
  static const _ring = 4.0;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSize.tapRipple,
    height: AppSize.tapRipple,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: XpColors.white.withValues(alpha: _fill),
      border: Border.all(color: XpColors.white, width: _border),
      boxShadow: const [BoxShadow(color: AppColors.tapRing, spreadRadius: _ring)],
    ),
  );
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
