// Dựng mỗi màn kèm ViewModel — router và test widget gọi cùng các hàm này.
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/repositories/backup/backup_repository.dart';
import '../data/repositories/device/device_repository.dart';
import '../data/repositories/release/release_repository.dart';
import '../ui/connect/view_models/connect_view_model.dart';
import '../ui/connect/widgets/connect_screen.dart';
import '../ui/core/widgets/view_model_host.dart';
import '../ui/dashboard/view_models/dashboard_view_model.dart';
import '../ui/dashboard/widgets/dashboard_screen.dart';
import '../ui/device/view_models/device_view_model.dart';
import '../ui/device/widgets/device_screen.dart';
import '../ui/settings/view_models/settings_view_model.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/wifi_setup/view_models/wifi_setup_view_model.dart';
import '../ui/wifi_setup/widgets/wifi_setup_screen.dart';

Widget connectScreen({required VoidCallback onNewDevice}) => ViewModelHost(
      create: (c) => ConnectViewModel(device: c.read<DeviceRepository>()),
      builder: (_, vm) => ConnectScreen(viewModel: vm, onNewDevice: onNewDevice),
    );

Widget wifiSetupScreen() => ViewModelHost(
      create: (c) => WifiSetupViewModel(device: c.read<DeviceRepository>()),
      builder: (_, vm) => WifiSetupScreen(viewModel: vm),
    );

Widget dashboardScreen() => ViewModelHost(
      create: (c) => DashboardViewModel(device: c.read<DeviceRepository>()),
      builder: (_, vm) => DashboardScreen(viewModel: vm),
    );

Widget settingsScreen() => ViewModelHost(
      create: (c) => SettingsViewModel(device: c.read<DeviceRepository>()),
      builder: (_, vm) => SettingsScreen(viewModel: vm),
    );

Widget deviceScreen({required VoidCallback onChangeWifi}) => ViewModelHost(
      create: (c) => DeviceViewModel(
        device: c.read<DeviceRepository>(),
        releases: c.read<ReleaseRepository>(),
        backups: c.read<BackupRepository>(),
      ),
      builder: (_, vm) => DeviceScreen(viewModel: vm, onChangeWifi: onChangeWifi),
    );
