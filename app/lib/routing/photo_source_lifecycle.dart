import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/repositories/device/device_repository.dart';
import '../domain/use_cases/photo_source_use_case.dart';

/// R-AK-4: the photo library is served while the app is on screen (+ a while after it leaves); the device is told
/// where it is whenever the app comes back or a device that points at libraries connects.
class PhotoSourceLifecycle extends StatefulWidget {
  const PhotoSourceLifecycle({super.key, required this.device, required this.source, required this.child});

  final DeviceRepository device;
  final PhotoSourceUseCase source;
  final Widget child;

  @override
  State<PhotoSourceLifecycle> createState() => _PhotoSourceLifecycleState();
}

class _PhotoSourceLifecycleState extends State<PhotoSourceLifecycle> with WidgetsBindingObserver {
  String? _syncedUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.device.addListener(_onDevice);
    _onDevice();
  }

  @override
  void dispose() {
    widget.device.removeListener(_onDevice);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Once per device the app connects to (a new url, or the firmware just started reporting `photo_source`).
  void _onDevice() {
    if (!widget.source.supported) return;
    if (_syncedUrl == widget.device.url) return;
    _syncedUrl = widget.device.url;
    unawaited(widget.source.sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      unawaited(widget.source.sync());
    } else if (s == AppLifecycleState.paused) {
      widget.source.paused();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
