// Dựng mỗi màn kèm ViewModel — router và test widget gọi cùng các hàm này.
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/repositories/backup/backup_repository.dart';
import '../data/repositories/device/device_repository.dart';
import '../data/repositories/release/release_repository.dart';
import '../domain/use_cases/toggle_skill_use_case.dart';
import '../ui/connect/view_models/connect_view_model.dart';
import '../ui/connect/widgets/connect_screen.dart';
import '../ui/core/widgets/view_model_host.dart';
import '../ui/dashboard/view_models/dashboard_view_model.dart';
import '../ui/dashboard/widgets/dashboard_screen.dart';
import '../ui/device/view_models/device_view_model.dart';
import '../ui/device/widgets/device_screen.dart';
import '../ui/home/view_models/home_view_model.dart';
import '../ui/home/widgets/home_shell.dart';
import '../ui/settings/view_models/settings_view_model.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/skills/view_models/skills_view_model.dart';
import '../ui/skills/widgets/skills_screen.dart';
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

Widget dashboardScreen({required VoidCallback onOpenSettings}) => ViewModelHost(
      create: (c) =>
          DashboardViewModel(device: c.read<DeviceRepository>(), toggleSkill: c.read<ToggleSkillUseCase>()),
      builder: (_, vm) => DashboardScreen(viewModel: vm, onOpenSettings: onOpenSettings),
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

Widget skillsScreen({required VoidCallback onOpenDevice}) => ViewModelHost(
      create: (c) => SkillsViewModel(toggleSkill: c.read<ToggleSkillUseCase>(), device: c.read<DeviceRepository>()),
      builder: (_, vm) => SkillsScreen(viewModel: vm, onOpenDevice: onOpenDevice),
    );

/// Khung 4 tab (tab 1 = Màn hình); [onSelect] nhận chỉ số tab.
Widget homeShell({required int index, required ValueChanged<int> onSelect, required Widget child}) => ViewModelHost(
      create: (c) => HomeViewModel(toggleSkill: c.read<ToggleSkillUseCase>(), device: c.read<DeviceRepository>()),
      builder: (_, vm) => ListenableBuilder(
        listenable: vm,
        builder: (_, _) => HomeShell(waiting: vm.waiting, badge: vm.badge, index: index, onSelect: onSelect, child: child),
      ),
    );
