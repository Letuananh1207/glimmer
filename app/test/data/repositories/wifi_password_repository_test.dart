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

    repo.remember('Nha', 'a'); // không đổi → không ghi, không báo
    repo.remember('', 'x'); // tên rỗng → bỏ qua
    expect(notified, 1);

    repo.forget('Nha');
    expect((repo.passwordFor('Nha'), secrets.stored.containsKey('Nha'), notified), (null, false, 2));
    repo.forget('Nha');
    expect(notified, 2);
  });
}
