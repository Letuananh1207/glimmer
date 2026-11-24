import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'services/store.dart';
import 'ui/connect_screen.dart';
import 'ui/dashboard_screen.dart';
import 'ui/device_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(await Store.open());
  runApp(GlimmerApp(controller));
  controller.discover();
}

class GlimmerApp extends StatefulWidget {
  const GlimmerApp(this.c, {super.key});
  final AppController c;

  @override
  State<GlimmerApp> createState() => _GlimmerAppState();
}

class _GlimmerAppState extends State<GlimmerApp> with WidgetsBindingObserver {
  int _tab = 0;

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

  // Poll only while the app is on screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (!widget.c.connected) return;
    if (s == AppLifecycleState.resumed) {
      widget.c.startPolling();
      widget.c.refresh();
    } else if (s == AppLifecycleState.paused) {
      widget.c.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'glimmer',
      debugShowCheckedModeBanner: false,
      theme: G.theme(),
      home: ListenableBuilder(
        listenable: widget.c,
        builder: (context, _) {
          if (!widget.c.connected) return ConnectScreen(widget.c);
          final pages = [DashboardScreen(widget.c), SettingsScreen(widget.c), DeviceScreen(widget.c)];
          return Scaffold(
            body: SafeArea(child: pages[_tab]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
                NavigationDestination(icon: Icon(Icons.tune), label: 'Cài đặt'),
                NavigationDestination(icon: Icon(Icons.memory), label: 'Thiết bị'),
              ],
            ),
          );
        },
      ),
    );
  }
}
