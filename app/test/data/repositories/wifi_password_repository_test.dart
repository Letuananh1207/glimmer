import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/wifi/wifi_password_repository_local.dart';

import '../../../testing/fakes/fake_services.dart';

void main() {
  test('R-WF-5 nạp từ kho bảo mật, nhớ / thay / quên theo tên mạng', () async {
    final secrets = FakeWifiSecretsService({'Nha': 'a'});
    final repo = await WifiPasswordRepositoryLocal.load(secrets);
    var notified = 0;
    repo.addListener(() => notified++);
    expect(repo.passwordFor('Nha'), 'a');

    repo.remember(' Co quan ', 'b');
    expect((repo.passwordFor('Co quan'), secrets.stored['Co quan']), ('b', 'b'));
    expect(repo.networks, ['Co quan', 'Nha']);

    repo.remember('', 'x'); // tên rỗng → bỏ qua
    expect(notified, 1);

    repo.forget('Nha');
    expect((repo.passwordFor('Nha'), secrets.stored.containsKey('Nha'), notified), (null, false, 2));
    repo.forget('Nha');
    expect(notified, 2);
  });

  test('2026-11-28.12 "dùng lần cuối": mỗi lần nhớ (kể cả cùng mật khẩu) ghi ngày; nạp lại; quên thì xoá', () async {
    final secrets = FakeWifiSecretsService({'Nha': 'a'});
    var now = DateTime(2026, 11, 12, 9);
    final repo = WifiPasswordRepositoryLocal(secrets, {'Nha': 'a'}, now: () => now);
    expect(repo.lastUsed('Nha'), isNull, reason: 'kept before the date was');
    repo.remember('Nha', 'a');
    expect(repo.lastUsed('Nha'), DateTime(2026, 11, 12, 9));
    now = DateTime(2026, 11, 28, 20);
    repo.remember('Nha', 'a');
    expect(secrets.used['Nha'], DateTime(2026, 11, 28, 20));
    final again = await WifiPasswordRepositoryLocal.load(secrets);
    expect(again.lastUsed(' Nha '), DateTime(2026, 11, 28, 20));
    again.forget('Nha');
    expect((again.lastUsed('Nha'), secrets.used.containsKey('Nha')), (null, false));
  });
}
