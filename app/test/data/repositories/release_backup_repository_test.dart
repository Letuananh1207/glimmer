import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/backup/backup_repository_local.dart';
import 'package:glimmer_app/data/repositories/release/release_repository_local.dart';
import 'package:glimmer_app/data/services/releases_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/release.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_services.dart';

void main() {
  test('release JSON → Release: assets, SHA only when target is a commit', () {
    final r = ReleaseRepositoryLocal.parse({
      'published_at': '2026-11-25T03:00:00Z',
      'target_commitish': '162923dabcdef',
      'assets': [
        {'name': 'firmware.bin', 'browser_download_url': 'https://x/firmware.bin'},
        {'name': 'broken'},
      ],
    });
    expect(r.commit, '162923d');
    expect(r.assets, {'firmware.bin': 'https://x/firmware.bin'});
    expect(r.published.toUtc(), DateTime.utc(2026, 11, 25, 3));
    expect(ReleaseRepositoryLocal.parse({'target_commitish': 'main'}).commit, '');
  });

  test('download of a missing asset → noAsset', () async {
    final repo = ReleaseRepositoryLocal(releases: ReleasesService(), store: await fakeStore());
    final r = await repo.download(Release(DateTime(2026), '', const {}), 'littlefs.bin');
    final e = (r as Error).error as AppError;
    expect((e.kind, e.detail), (AppErrorKind.noAsset, 'littlefs.bin'));
  });

  test('R-TB-2 decode: a glimmer config passes, anything else is invalidBackup', () {
    final ok = BackupRepositoryLocal.decode('b.json', utf8.encode('{"wifi_ssid":"Nha"}'));
    expect((ok as Ok).value.config['wifi_ssid'], 'Nha');
    for (final bad in ['{"a":1}', '[1]', 'not json']) {
      final r = BackupRepositoryLocal.decode('b.json', utf8.encode(bad));
      expect(((r as Error).error as AppError).kind, AppErrorKind.invalidBackup, reason: bad);
    }
  });
}
