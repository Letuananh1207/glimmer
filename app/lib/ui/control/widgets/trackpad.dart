import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// `Trackpad` (§8, design 2026-11-27.10, R-DK-17/18): lề 6 16 0, cao [height] (280; 190 dưới thẻ agent, 220 dưới thanh
/// báo), viền 1 `line` không viền dưới, bo 20 20 0 0, gradient `trackpadTop` → `trackpadBottom`, bóng trong; icon chuột
/// 40 ink 18 % ở giữa. Rê một ngón → [onMove] (dp, thời gian), chạm nhẹ → [onTap] (click trái). Đang rê: viền mint 55 %,
/// vệt ngón mint 35 % rộng 10, quầng mint 22 % ở đầu ngón. Không vẽ con trỏ trên app. [onPowerOn] ≠ null (máy tắt):
/// giữa bàn rê nút tròn 120 "Bật máy" coral. [enabled] false: mờ 35 %, không nhận chạm.
class Trackpad extends StatefulWidget {
  const Trackpad({
    super.key,
    required this.height,
    required this.enabled,
    required this.onMove,
    required this.onTap,
    this.onPowerOn,
  });

  final double height;
  final bool enabled;
  final void Function(double dx, double dy, Duration dt) onMove;
  final VoidCallback onTap;
  final VoidCallback? onPowerOn;

  static const dimOpacity = 0.35;

  @override
  State<Trackpad> createState() => _TrackpadState();
}

class _TrackpadState extends State<Trackpad> {
  final _trail = <Offset>[];
  Duration? _last;
  // L-6: the pad owns every touch from the first contact; a touch that barely moved and lifted soon is a click.
  final _held = Stopwatch();
  double _travel = 0;

  static const _trailMax = 14;
  static const _mouseIcon = 40.0;
  static const _mouseAlpha = 0.18;
  static const _dragBorder = 0.55;
  static const _innerShadow = 0.45, _innerShadowH = 8.0;
  static const _offButton = 120.0, _offIcon = 40.0, _offLabel = 14.0, _offGap = 6.0, _offWash = 0.10;

  bool get _dragging => _trail.isNotEmpty;

  void _start(DragStartDetails d) {
    _last = d.sourceTimeStamp;
    _travel = 0;
    _held
      ..reset()
      ..start();
    setState(
      () => _trail
        ..clear()
        ..add(d.localPosition),
    );
  }

  void _update(DragUpdateDetails d) {
    final t = d.sourceTimeStamp;
    final dt = t != null && _last != null ? t - _last! : const Duration(milliseconds: 16);
    _last = t;
    _travel += d.delta.distance;
    widget.onMove(d.delta.dx, d.delta.dy, dt);
    setState(() {
      _trail.add(d.localPosition);
      if (_trail.length > _trailMax) _trail.removeAt(0);
    });
  }

  void _end([Object? _]) => setState(_trail.clear);

  void _lift(DragEndDetails _) {
    _held.stop();
    final click = _travel < kTouchSlop && _held.elapsed < kLongPressTimeout;
    _end();
    if (click) {
      HapticFeedback.lightImpact();
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final border = BorderSide(color: _dragging ? AppColors.mint.withValues(alpha: _dragBorder) : AppColors.line);
    final pad = Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSize.radiusTrackpad)),
        border: Border(top: border, left: border, right: border),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.trackpadTop, AppColors.trackpadBottom],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSize.radiusTrackpad)),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _innerShadowH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: _innerShadow),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.mouse_outlined,
                size: _mouseIcon,
                color: AppColors.ink.withValues(alpha: _mouseAlpha),
              ),
            ),
            if (_dragging) Positioned.fill(child: CustomPaint(painter: _TrailPainter(List.of(_trail)))),
            if (widget.onPowerOn != null) Center(child: _powerOn(l)),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, 6, AppSpace.l, 0),
      child: Semantics(
        label: l.controlTrackpadA11y,
        child: widget.onPowerOn != null
            ? pad
            : Opacity(
                opacity: widget.enabled ? 1 : Trackpad.dimOpacity,
                child: IgnorePointer(
                  ignoring: !widget.enabled,
                  // L-6: claims the touch at once — a plain pan loses a mostly vertical stroke to the list's
                  // scroll (36 px pan slop vs 18 px vertical), and the whole screen scrolled under the finger.
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      _EagerPan: GestureRecognizerFactoryWithHandlers<_EagerPan>(
                        _EagerPan.new,
                        (r) => r
                          ..dragStartBehavior = DragStartBehavior.down
                          ..onStart = _start
                          ..onUpdate = _update
                          ..onEnd = _lift
                          ..onCancel = _end,
                      ),
                    },
                    child: pad,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _powerOn(AppLocalizations l) => Semantics(
    button: true,
    label: l.powerOn,
    child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPowerOn!();
      },
      child: Container(
        width: _offButton,
        height: _offButton,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.coral, width: 2),
          color: AppColors.coral.withValues(alpha: _offWash),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power_settings_new, size: _offIcon, color: AppColors.coral),
            const SizedBox(height: _offGap),
            Text(
              l.powerOn,
              style: const TextStyle(
                fontFamily: AppFonts.family,
                fontSize: _offLabel,
                fontWeight: FontWeight.w700,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A pan that wins the gesture arena on the first contact (L-6): nothing under or around the trackpad (the screen's
/// list) can take the stroke.
class _EagerPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// The finger's trail (mint 35 %, 10 wide) and its glow (mint 22 %, 120 across).
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points);

  final List<Offset> points;
  static const _trailAlpha = 0.35, _glowAlpha = 0.22, _width = 10.0, _glow = 60.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final tip = points.last;
    canvas.drawCircle(
      tip,
      _glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.mint.withValues(alpha: _glowAlpha),
            Colors.transparent,
          ],
          stops: const [0, 0.7],
        ).createShader(Rect.fromCircle(center: tip, radius: _glow)),
    );
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.mint.withValues(alpha: _trailAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

/// `MouseButtons` (§8): liền dưới bàn rê, hai nửa bằng nhau cao 60, khe 2 màu `line`, viền ngoài `line`, bo 0 0 20 20,
/// nền `panel`, chữ 13/500 inkDim. Đang bấm: nền `panel2` + bóng trong (lõm). [pressedRight] vẽ nửa Phải lõm (menu
/// chuột phải vừa mở, trạng thái `clickRight`).
class MouseButtons extends StatelessWidget {
  const MouseButtons({
    super.key,
    required this.enabled,
    required this.onLeft,
    required this.onRight,
    this.pressedRight = false,
  });

  final bool enabled;
  final VoidCallback onLeft, onRight;
  final bool pressedRight;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
      child: Opacity(
        opacity: enabled ? 1 : Trackpad.dimOpacity,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.line,
              border: Border.all(color: AppColors.line),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSize.radiusTrackpad)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: _MouseHalf(
                    label: l.controlMouseLeft,
                    a11y: l.controlMouseLeftA11y,
                    radius: const BorderRadius.only(bottomLeft: Radius.circular(AppSize.radiusTrackpad)),
                    onTap: onLeft,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _MouseHalf(
                    label: l.controlMouseRight,
                    a11y: l.controlMouseRightA11y,
                    radius: const BorderRadius.only(bottomRight: Radius.circular(AppSize.radiusTrackpad)),
                    onTap: onRight,
                    held: pressedRight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MouseHalf extends StatefulWidget {
  const _MouseHalf({
    required this.label,
    required this.a11y,
    required this.radius,
    required this.onTap,
    this.held = false,
  });

  final String label, a11y;
  final BorderRadius radius;
  final VoidCallback onTap;
  final bool held;

  @override
  State<_MouseHalf> createState() => _MouseHalfState();
}

class _MouseHalfState extends State<_MouseHalf> {
  bool _down = false;

  static const _label = 13.0;
  static const _shadow = 0.5;

  @override
  Widget build(BuildContext context) {
    final pressed = _down || widget.held;
    return Semantics(
      button: true,
      label: widget.a11y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          height: AppSize.mouseButton,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            color: pressed ? AppColors.panel2 : AppColors.panel,
            gradient: pressed
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: _shadow),
                      AppColors.panel2,
                    ],
                  )
                : null,
          ),
          child: ExcludeSemantics(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: AppFonts.family,
                fontSize: _label,
                fontWeight: FontWeight.w500,
                color: AppColors.inkDim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
