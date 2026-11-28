import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/rules/setup_qr_rules.dart';

void main() {
  test('R-WF-4 mã trên màn cài đặt → tên AP', () {
    expect(setupApFromQr('WIFI:T:nopass;S:glimmer-setup;;'), 'glimmer-setup');
    expect(setupApFromQr('  WIFI:S:glimmer-setup-2;T:nopass;;\n'), 'glimmer-setup-2');
    expect(setupApFromQr('wifi:S:glimmer-setup;;'), 'glimmer-setup', reason: 'không có T = mạng mở');
    expect(setupApFromQr(r'WIFI:T:nopass;S:glimmer-setup\;x;;'), 'glimmer-setup;x', reason: r'bỏ thoát \;');
  });

  test('R-WF-4 mã khác → null', () {
    expect(setupApFromQr('WIFI:T:WPA;S:CafeABC;P:123;;'), isNull);
    expect(setupApFromQr('WIFI:T:WPA;S:glimmer-setup;P:123;;'), isNull, reason: 'AP glimmer không có mật khẩu');
    expect(setupApFromQr('WIFI:T:nopass;S:Nha;;'), isNull);
    expect(setupApFromQr('https://glimmer.local'), isNull);
    expect(setupApFromQr('WIFI:S;;'), isNull);
    expect(setupApFromQr(''), isNull);
  });
}
