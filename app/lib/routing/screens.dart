// Dựng mỗi màn kèm ViewModel — router và test widget gọi cùng các hàm này.
import '../data/repositories/location/location_repository.dart';
import '../ui/weather_location/view_models/weather_location_view_model.dart';
import '../ui/weather_location/widgets/weather_location_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/repositories/backup/backup_repository.dart';
import '../data/repositories/device/device_repository.dart';
import '../data/repositories/photo/photo_repository.dart';
import '../data/repositories/release/release_repository.dart';
import '../data/repositories/wifi/wifi_password_repository.dart';
import '../domain/use_cases/control_device_use_case.dart';
import '../domain/use_cases/delete_photo_use_case.dart';
import '../domain/use_cases/load_photos_use_case.dart';
import '../domain/use_cases/send_photo_use_case.dart';
import '../domain/use_cases/toggle_skill_use_case.dart';
import '../ui/connect/view_models/connect_view_model.dart';
import '../ui/connect/widgets/connect_screen.dart';
import '../ui/control/view_models/control_view_model.dart';
import '../ui/control/widgets/control_screen.dart';
import '../ui/core/widgets/view_model_host.dart';
import '../ui/dashboard/view_models/dashboard_view_model.dart';
import '../ui/dashboard/widgets/dashboard_screen.dart';
import '../ui/device/view_models/device_view_model.dart';
import '../ui/device/widgets/device_screen.dart';
import '../ui/dashboard/view_models/photo_tab_view_model.dart';
import '../ui/home/view_models/home_view_model.dart';
import '../ui/photo_crop/view_models/photo_crop_view_model.dart';
import '../ui/photo_crop/widgets/photo_crop_screen.dart';
import '../ui/home/widgets/home_shell.dart';
import '../ui/settings/view_models/settings_view_model.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/skills/view_models/skills_view_model.dart';
import '../ui/skills/widgets/skills_screen.dart';
import '../ui/wifi_setup/view_models/wifi_setup_view_model.dart';
import '../ui/wifi_setup/widgets/wifi_setup_screen.dart';
import 'routes.dart';

Widget connectScreen({required VoidCallback onNewDevice}) => ViewModelHost(
      create: (c) => ConnectViewModel(device: c.read<DeviceRepository>()),
      builder: (_, vm) => ConnectScreen(viewModel: vm, onNewDevice: onNewDevice),
    );

Widget wifiSetupScreen() => ViewModelHost(
      create: (c) => WifiSetupViewModel(device: c.read<DeviceRepository>(), passwords: c.read<WifiPasswordRepository>()),
      builder: (_, vm) => WifiSetupScreen(viewModel: vm),
    );

/// Điều khiển (tab 1, screen_specs §8). [onOpenDetails] pushes Số liệu at a skill's tab and completes when it closes.
Widget controlScreen({
  required Future<void> Function(String? skill) onOpenDetails,
  required VoidCallback onUpdateFirmware,
  required VoidCallback onSetupWifi,
  required VoidCallback onOpenSettings,
  required VoidCallback onOpenSkills,
}) =>
    ViewModelHost(
      create: (c) => ControlViewModel(
        device: c.read<DeviceRepository>(),
        control: c.read<ControlDeviceUseCase>(),
      ),
      builder: (_, vm) => ControlScreen(
        viewModel: vm,
        onOpenDetails: onOpenDetails,
        onUpdateFirmware: onUpdateFirmware,
        onSetupWifi: onSetupWifi,
        onOpenSettings: onOpenSettings,
        onOpenSkills: onOpenSkills,
      ),
    );

/// Số liệu (screen_specs §2, pushed from Điều khiển) at [initialTab]. [onCropPhoto] opens PhotoCrop and completes
/// when it closes (the Ảnh tab then reloads).
Widget dashboardScreen({
  String? initialTab,
  required VoidCallback onBack,
  required VoidCallback onOpenSettings,
  required Future<void> Function(PhotoCropArgs args) onCropPhoto,
}) =>
    ViewModelHost(
      create: (c) => DashboardViewModel(
        device: c.read<DeviceRepository>(),
        toggleSkill: c.read<ToggleSkillUseCase>(),
        initialTab: initialTab,
      ),
      builder: (_, vm) => ViewModelHost(
        create: (c) => PhotoTabViewModel(
          loadPhotos: c.read<LoadPhotosUseCase>(),
          deletePhoto: c.read<DeletePhotoUseCase>(),
          photos: c.read<PhotoRepository>(),
        ),
        builder: (_, photos) => DashboardScreen(
          viewModel: vm,
          photos: photos,
          onOpenSettings: onOpenSettings,
          onCropPhoto: onCropPhoto,
          onBack: onBack,
        ),
      ),
    );

/// Cắt ảnh (screen_specs §7); [onClose] = back to the Ảnh tab.
Widget photoCropScreen(PhotoCropArgs args, {required VoidCallback onClose}) => ViewModelHost(
      create: (c) => PhotoCropViewModel(
        image: args.image,
        info: args.info,
        send: c.read<SendPhotoUseCase>(),
        photos: c.read<PhotoRepository>(),
      ),
      builder: (_, vm) => PhotoCropScreen(viewModel: vm, onClose: onClose),
    );

Widget settingsScreen({required Future<void> Function() onOpenWeatherLocation}) => ViewModelHost(
      create: (c) => SettingsViewModel(device: c.read<DeviceRepository>()),
      builder: (_, vm) => SettingsScreen(viewModel: vm, onOpenWeatherLocation: onOpenWeatherLocation),
    );

/// Vị trí thời tiết (screen_specs §9).
Widget weatherLocationScreen({required VoidCallback onBack}) => ViewModelHost(
      create: (c) => WeatherLocationViewModel(device: c.read<DeviceRepository>(), location: c.read<LocationRepository>()),
      builder: (_, vm) => WeatherLocationScreen(viewModel: vm, onBack: onBack),
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

/// Khung 4 tab (tab 1 = Điều khiển); [onSelect] nhận chỉ số tab.
Widget homeShell({required int index, required ValueChanged<int> onSelect, required Widget child}) => ViewModelHost(
      create: (c) => HomeViewModel(toggleSkill: c.read<ToggleSkillUseCase>(), device: c.read<DeviceRepository>()),
      builder: (_, vm) => ListenableBuilder(
        listenable: vm,
        builder: (_, _) => HomeShell(waiting: vm.waiting, badge: vm.badge, index: index, onSelect: onSelect, child: child),
      ),
    );
