import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/camera_access.dart';
import 'package:glimmer_app/ui/wifi_setup/view_models/wifi_scan_view_model.dart';

import '../../../testing/fakes/fake_services.dart';

const _code = 'WIFI:T:nopass;S:glimmer-setup;;';

void main() {
  WifiScanViewModel vmFor(FakeCameraRepository camera) =>
      WifiScanViewModel(camera: camera, foundPause: const Duration(milliseconds: 1));

  test('camera allowed → scanning', () async {
    final vm = vmFor(FakeCameraRepository());
    expect(vm.state, ScanState.starting);
    await vm.start();
    expect((vm.state, vm.cameraOn), (ScanState.scanning, true));
  });

  test('refused → noCamera; "Cho phép camera" asks again', () async {
    final cam = FakeCameraRepository(CameraAccess.denied);
    final vm = vmFor(cam);
    await vm.start();
    expect((vm.state, vm.cameraOn, vm.blocked), (ScanState.noCamera, false, false));
    cam.answer = CameraAccess.granted;
    await vm.allow();
    expect((vm.state, cam.asked), (ScanState.scanning, 2));
  });

  test('refused for good → "Cho phép" opens the settings; allowed there → scanning on return', () async {
    final cam = FakeCameraRepository(CameraAccess.blocked);
    final vm = vmFor(cam);
    await vm.start();
    expect(vm.blocked, isTrue);
    await vm.allow();
    expect(cam.settingsOpened, 1);
    cam.afterSettings = CameraAccess.granted;
    await vm.resumed();
    expect(vm.state, ScanState.scanning);
  });

  test('R-WF-4 another code → wrongCode, nothing returned; "Quét lại" scans again', () async {
    final vm = vmFor(FakeCameraRepository());
    await vm.start();
    expect(await vm.detected('https://example.com'), isNull);
    expect(vm.state, ScanState.wrongCode);
    expect(await vm.detected(_code), isNull, reason: 'not scanning');
    vm.scanAgain();
    expect(vm.state, ScanState.scanning);
  });

  test("R-WF-4 glimmer's code → found, then its text to close with", () async {
    final vm = vmFor(FakeCameraRepository());
    await vm.start();
    final f = vm.detected(_code);
    expect(vm.state, ScanState.found);
    expect(await f, _code);
    expect(await vm.detected(_code), isNull, reason: 'read once');
  });
}
