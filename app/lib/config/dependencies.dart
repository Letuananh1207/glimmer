import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/backup/backup_repository.dart';
import '../data/repositories/backup/backup_repository_local.dart';
import '../data/repositories/device/device_repository.dart';
import '../data/repositories/device/device_repository_local.dart';
import '../data/repositories/location/location_repository.dart';
import '../data/repositories/location/location_repository_remote.dart';
import '../data/repositories/photo/photo_repository.dart';
import '../data/repositories/photo/photo_repository_local.dart';
import '../data/repositories/release/release_repository.dart';
import '../data/repositories/release/release_repository_local.dart';
import '../data/repositories/skill/skill_repository.dart';
import '../data/repositories/skill/skill_repository_local.dart';
import '../data/repositories/wifi/wifi_password_repository.dart';
import '../data/repositories/wifi/wifi_password_repository_local.dart';
import '../data/services/device_api_service.dart';
import '../data/services/discovery_service.dart';
import '../data/services/file_service.dart';
import '../data/services/geo_search_service.dart';
import '../data/services/local_store_service.dart';
import '../data/services/photo_picker_service.dart';
import '../data/services/photo_store_service.dart';
import '../data/services/position_service.dart';
import '../data/services/releases_service.dart';
import '../data/services/wifi_secrets_service.dart';
import '../data/services/wifi_service.dart';
import '../domain/use_cases/control_device_use_case.dart';
import '../domain/use_cases/delete_photo_use_case.dart';
import '../domain/use_cases/load_photos_use_case.dart';
import '../domain/use_cases/send_photo_use_case.dart';
import '../domain/use_cases/toggle_skill_use_case.dart';
import '../data/repositories/photo/photo_library_repository.dart';
import '../data/repositories/photo/photo_library_repository_local.dart';
import '../data/repositories/photo/photo_server_repository_local.dart';
import '../data/services/network_service.dart';
import '../data/services/photo_library_service.dart';
import '../data/services/photo_server_service.dart';
import '../domain/use_cases/photo_source_use_case.dart';

/// The one place that picks implementations and creates them.
class Dependencies {
  Dependencies({
    required this.device,
    required this.releases,
    required this.backups,
    required this.skills,
    required this.photos,
    required this.library,
    required this.photoSource,
    required this.wifiPasswords,
  });

  final DeviceRepository device;
  final ReleaseRepository releases;
  final BackupRepository backups;
  final SkillRepository skills;
  final PhotoRepository photos;
  final WifiPasswordRepository wifiPasswords;

  /// R-AK-1: the photo library (the app is the memory, the device points at it).
  final PhotoLibraryRepository library;

  /// R-AK-4: serves [library] on the home network and keeps the device's cache.
  final PhotoSourceUseCase photoSource;

  static Future<Dependencies> create() async {
    final store = await LocalStoreService.open();
    final device = DeviceRepositoryLocal(
      api: DeviceApiService(),
      discovery: DiscoveryService(),
      store: store,
      wifi: WifiService(),
    );
    final library = PhotoLibraryRepositoryLocal(files: PhotoLibraryService());
    return Dependencies(
      device: device,
      library: library,
      photoSource: PhotoSourceUseCase(
        device: device,
        library: library,
        server: PhotoServerRepositoryLocal(server: PhotoServerService()),
        phoneIps: NetworkService().ipv4,
      ),
      releases: ReleaseRepositoryLocal(releases: ReleasesService(), store: store),
      backups: BackupRepositoryLocal(files: FileService()),
      skills: SkillRepositoryLocal(store: store),
      photos: PhotoRepositoryLocal(store: PhotoStoreService(), picker: PhotoPickerService()),
      wifiPasswords: await WifiPasswordRepositoryLocal.load(WifiSecretsService()),
    );
  }

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<DeviceRepository>.value(value: device),
    Provider<ReleaseRepository>.value(value: releases),
    Provider<BackupRepository>.value(value: backups),
    ChangeNotifierProvider<SkillRepository>.value(value: skills),
    Provider<ToggleSkillUseCase>(
      create: (_) => ToggleSkillUseCase(skills: skills, device: device),
    ),
    Provider<PhotoRepository>.value(value: photos),
    ChangeNotifierProvider<WifiPasswordRepository>.value(value: wifiPasswords),
    Provider<LoadPhotosUseCase>(
      create: (_) => LoadPhotosUseCase(device: device, photos: photos),
    ),
    Provider<PhotoLibraryRepository>.value(value: library),
    Provider<PhotoSourceUseCase>.value(value: photoSource),
    Provider<SendPhotoUseCase>(
      create: (_) => SendPhotoUseCase(device: device, photos: photos, library: library, source: photoSource),
    ),
    Provider<ControlDeviceUseCase>(create: (_) => ControlDeviceUseCase(device: device)),
    Provider<DeletePhotoUseCase>(
      create: (_) => DeletePhotoUseCase(device: device, photos: photos, library: library, source: photoSource),
    ),
    Provider<LocationRepository>(
      create: (_) => LocationRepositoryRemote(position: PositionService(), search: GeoSearchService()),
    ),
  ];
}
