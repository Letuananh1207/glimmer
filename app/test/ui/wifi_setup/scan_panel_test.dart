import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/wifi_setup/view_models/wifi_scan_view_model.dart';
import 'package:glimmer_app/ui/wifi_setup/widgets/scan_panel.dart';

final _vi = lookupAppLocalizations(const Locale('vi'));

void main() {
  late List<String> taps;

  Future<void> pump(WidgetTester t, ScanState state, {bool blocked = false}) async {
    taps = [];
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ScanPanel(
            state: state,
            blocked: blocked,
            onManual: () => taps.add('manual'),
            onScanAgain: () => taps.add('again'),
            onAllow: () => taps.add('allow'),
            onOpenSettings: () => taps.add('settings'),
          ),
        ),
      ),
    ));
  }

  testWidgets('scanning: the device screen picture, help, "Nhập tay"', (t) async {
    await pump(t, ScanState.scanning);
    expect(find.bySemanticsLabel(_vi.wifiScanHelpImageA11y), findsOneWidget);
    expect(find.text(_vi.wifiScanHelpTitle), findsOneWidget);
    await t.tap(find.text(_vi.wifiScanManual));
    expect(taps, ['manual']);
  });

  testWidgets('found: "Đã đọc mã", no buttons', (t) async {
    await pump(t, ScanState.found);
    expect(find.text(_vi.wifiScanFound), findsOneWidget);
    expect(find.text(_vi.wifiScanManual), findsNothing);
  });

  testWidgets('wrongCode: coral title, "Quét lại"', (t) async {
    await pump(t, ScanState.wrongCode);
    expect(find.text(_vi.wifiScanWrongTitle), findsOneWidget);
    await t.tap(find.text(_vi.wifiScanAgain));
    expect(taps, ['again']);
  });

  testWidgets('noCamera: allow; blocked adds "Mở cài đặt điện thoại"', (t) async {
    await pump(t, ScanState.noCamera);
    expect(find.text(_vi.wifiScanOpenSettings), findsNothing);
    await t.tap(find.text(_vi.wifiScanAllowCamera));
    expect(taps, ['allow']);
    await pump(t, ScanState.noCamera, blocked: true);
    await t.tap(find.text(_vi.wifiScanOpenSettings));
    expect(taps, ['settings']);
  });
}
