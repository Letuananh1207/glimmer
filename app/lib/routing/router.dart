import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/device/device_repository.dart';
import 'routes.dart';
import 'screens.dart';

/// R-KN-3: not connected → Kết nối; connected → the 4-tab shell, on tab 1 (Điều khiển). Cài Wi-Fi is allowed either way (its
/// flow forgets and finds the device again), above the shell.
String? redirectFor(bool connected, String location) {
  if (location.endsWith('/${Routes.wifiSetupName}')) return null;
  if (!connected) return location == Routes.connect ? null : Routes.connect;
  return location == Routes.connect ? Routes.control : null;
}

/// Tab switches are instant cuts, like the old app; each visit builds the screen (and its ViewModel)
/// afresh, so Cài đặt reloads from the device every time.
Page<void> _tab(GoRouterState s, Widget child) => NoTransitionPage(key: s.pageKey, child: child);

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
        builder: (context, _) => connectScreen(onNewDevice: () => context.push(Routes.connectWifi)),
        routes: [GoRoute(path: Routes.wifiSetupName, builder: (_, _) => wifiSetupScreen())],
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
                onSetupWifi: () => context.push(Routes.deviceWifi),
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
                      onCropPhoto: (args) => context.push(Routes.photoCrop, extra: args),
                    ),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: Routes.photoCropName,
                    parentNavigatorKey: root,
                    // Needs the picked image: opened any other way (restored, deep link) → back to Số liệu.
                    redirect: (_, s) => s.extra is PhotoCropArgs ? null : Routes.dashboard,
                    builder: (context, s) => photoCropScreen(s.extra! as PhotoCropArgs, onClose: () => context.pop()),
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
                builder: (_, _) => wifiSetupScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
