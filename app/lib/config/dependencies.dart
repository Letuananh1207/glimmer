import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/backup/backup_repository.dart';
import '../data/repositories/backup/backup_repository_local.dart';
import '../data/repositories/device/device_repository.dart';
import '../data/repositories/device/device_repository_local.dart';
import '../data/repositories/photo/photo_repository.dart';
import '../data/repositories/photo/photo_repository_local.dart';
import '../data/repositories/release/release_repository.dart';
import '../data/repositories/release/release_repository_local.dart';
import '../data/repositories/skill/skill_repository.dart';
import '../data/repositories/skill/skill_repository_local.dart';
import '../data/services/device_api_service.dart';
import '../data/services/discovery_service.dart';
import '../data/services/file_service.dart';
import '../data/services/local_store_service.dart';
import '../data/services/photo_picker_service.dart';
import '../data/services/photo_store_service.dart';
import '../data/services/releases_service.dart';
import '../data/services/wifi_service.dart';
import '../domain/use_cases/control_device_use_case.dart';
import '../domain/use_cases/delete_photo_use_case.dart';
import '../domain/use_cases/load_photos_use_case.dart';
import '../domain/use_cases/send_photo_use_case.dart';
import '../domain/use_cases/toggle_skill_use_case.dart';

/// The one place that picks implementations and creates them.
class Dependencies {
  Dependencies({
    required this.device,
    required this.releases,
    required this.backups,
    required this.skills,
    required this.photos,
  });

  final DeviceRepository device;
  final ReleaseRepository releases;
  final BackupRepository backups;
  final SkillRepository skills;
  final PhotoRepository photos;

  static Future<Dependencies> create() async {
    final store = await LocalStoreService.open();
    return Dependencies(
      device: DeviceRepositoryLocal(
        api: DeviceApiService(),
        discovery: DiscoveryService(),
        store: store,
        wifi: WifiService(),
      ),
      releases: ReleaseRepositoryLocal(releases: ReleasesService(), store: store),
      backups: BackupRepositoryLocal(files: FileService()),
      skills: SkillRepositoryLocal(store: store),
      photos: PhotoRepositoryLocal(store: PhotoStoreService(), picker: PhotoPickerService()),
    );
  }

  List<SingleChildWidget> get providers => [
        ChangeNotifierProvider<DeviceRepository>.value(value: device),
        Provider<ReleaseRepository>.value(value: releases),
        Provider<BackupRepository>.value(value: backups),
        ChangeNotifierProvider<SkillRepository>.value(value: skills),
        Provider<ToggleSkillUseCase>(create: (_) => ToggleSkillUseCase(skills: skills, device: device)),
        Provider<PhotoRepository>.value(value: photos),
        Provider<LoadPhotosUseCase>(create: (_) => LoadPhotosUseCase(device: device, photos: photos)),
        Provider<SendPhotoUseCase>(create: (_) => SendPhotoUseCase(device: device, photos: photos)),
        Provider<ControlDeviceUseCase>(create: (_) => ControlDeviceUseCase(device: device)),
        Provider<DeletePhotoUseCase>(create: (_) => DeletePhotoUseCase(device: device, photos: photos)),
      ];
}
