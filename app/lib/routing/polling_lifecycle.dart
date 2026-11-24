import 'package:flutter/widgets.dart';

import '../data/repositories/device/device_repository.dart';

/// R-KN-2: poll the display only while the app is on screen; refresh at once when it comes back.
class PollingLifecycle extends StatefulWidget {
  const PollingLifecycle({super.key, required this.device, required this.child});

  final DeviceRepository device;
  final Widget child;

  @override
  State<PollingLifecycle> createState() => _PollingLifecycleState();
}

class _PollingLifecycleState extends State<PollingLifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final d = widget.device;
    if (!d.connected) return;
    if (s == AppLifecycleState.resumed) {
      d.startPolling();
      d.refresh();
    } else if (s == AppLifecycleState.paused) {
      d.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
