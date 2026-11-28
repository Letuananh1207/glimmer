import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/device/device_repository.dart';
import '../domain/models/device_photo.dart';
import 'routes.dart';
import 'screens.dart';

/// R-KN-3: not connected → Kết nối; connected → the 4-tab shell, on tab 1 (Điều khiển). Cài Wi-Fi is allowed either way (its
/// flow forgets and finds the device again), above the shell.
String? redirectFor(bool connected, String location) {
  if (location.endsWith('/${Routes.wifiSetupName}') || location == Routes.scan) return null;
  if (!connected) return location == Routes.connect ? null : Routes.connect;
  return location == Routes.connect ? Routes.control : null;
}

/// Tab switches are instant cuts, like the old app; each visit builds the screen (and its ViewModel)
/// afresh, so Cài đặt reloads from the device every time.
Page<void> _tab(GoRouterState s, Widget child) => NoTransitionPage(key: s.pageKey, child: child);

/// Quét mã → Cài Wi-Fi at [wifiRoute] with what it read ('' = the manual form); × = stay.
Future<void> _scanThenWifi(BuildContext context, String wifiRoute) async {
  final raw = await context.push<String>(Routes.scan);
  if (raw == null || !context.mounted) return;
  await context.push(wifiRoute, extra: raw);
}

GoRouter buildRouter(DeviceRepository device) {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: Routes.connect,
    refreshListenable: device,
    redirect: (_, s) => redirectFor(device.connected, s.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.connect,
        builder: (context, _) => connectScreen(onNewDevice: () => _scanThenWifi(context, Routes.connectWifi)),
        routes: [
          GoRoute(
            path: Routes.wifiSetupName,
            builder: (context, s) => wifiSetupScreen(
              scanned: s.extra is String ? s.extra! as String : null,
              onScan: () => context.push<String>(Routes.scan),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.scan,
        parentNavigatorKey: root,
        builder: (context, _) => wifiScanScreen(
          onFound: (raw) => context.pop(raw),
          onManual: () => context.pop(''),
          onClose: () => context.pop(),
        ),
      ),
      ShellRoute(
        builder: (context, s, child) => homeShell(
          index: Routes.tabOf(s.matchedLocation),
          onSelect: (i) => context.go(i == 0 ? Routes.control : Routes.sharedTabs[i - 1]),
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.control,
            pageBuilder: (context, s) => _tab(
              s,
              controlScreen(
                onOpenDetails: (skill) => context.push(Routes.detailsAt(skill)),
                onUpdateFirmware: () => context.go(Routes.device),
                onSetupWifi: () => _scanThenWifi(context, Routes.deviceWifi),
                onOpenSettings: () => context.go(Routes.settings),
                onOpenSkills: () => context.go(Routes.skills),
              ),
            ),
            routes: [
              // Số liệu: pushed above the tabs (no bottom bar), opens at `?tab=`.
              GoRoute(
                path: Routes.detailsName,
                parentNavigatorKey: root,
                builder: (context, s) => Scaffold(
                  body: SafeArea(
                    child: dashboardScreen(
                      initialTab: s.uri.queryParameters['tab'],
                      onBack: () => context.pop(),
                      onOpenSettings: () => context.push(Routes.weatherLocation),
                      onCropPhoto: (args) => context.push<PhotoPixels>(Routes.photoCrop, extra: args),
                    ),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: Routes.photoCropName,
                    parentNavigatorKey: root,
                    // Needs the picked image: opened any other way (restored, deep link) → back to Số liệu.
                    redirect: (_, s) => s.extra is PhotoCropArgs ? null : Routes.dashboard,
                    builder: (context, s) => photoCropScreen(
                      s.extra! as PhotoCropArgs,
                      onClose: () => context.pop(),
                      onAdd: (pixels) => context.pop(pixels),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Routes.skills,
            pageBuilder: (context, s) => _tab(
              s,
              skillsScreen(
                onOpenDevice: () => context.go(Routes.device),
              ),
            ),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, s) =>
                _tab(s, settingsScreen(onOpenWeatherLocation: () => context.push(Routes.weatherLocation))),
            routes: [
              // Vị trí thời tiết: pushed above the tabs (no bottom bar).
              GoRoute(
                path: Routes.weatherLocationName,
                parentNavigatorKey: root,
                builder: (context, s) => Scaffold(
                  body: SafeArea(child: weatherLocationScreen(onBack: () => context.pop())),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.device,
            pageBuilder: (context, s) =>
                _tab(s, deviceScreen(onChangeWifi: () => context.push(Routes.deviceWifi))),
            routes: [
              GoRoute(
                path: Routes.wifiSetupName,
                parentNavigatorKey: root,
                builder: (context, s) => wifiSetupScreen(
                  scanned: s.extra is String ? s.extra! as String : null,
                  onScan: () => context.push<String>(Routes.scan),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
