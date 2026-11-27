import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/control/widgets/trackpad.dart';

void main() {
  late List<Offset> moves;
  late int taps;
  late ScrollController scroll;

  Future<void> pump(WidgetTester t) async {
    moves = [];
    taps = 0;
    scroll = ScrollController();
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          // As the Điều khiển screen: the trackpad inside a scrolling list.
          body: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 100),
              Trackpad(
                height: 280,
                enabled: true,
                onMove: (dx, dy, _) => moves.add(Offset(dx, dy)),
                onTap: () => taps++,
              ),
              const SizedBox(height: 1500),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('R-DK-17 (L-6): a mostly vertical stroke on the trackpad moves the cursor, the screen does not scroll', (
    t,
  ) async {
    await pump(t);
    final g = await t.startGesture(t.getCenter(find.byType(Trackpad)));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(1, 6));
      await t.pump();
    }
    await g.up();
    await t.pumpAndSettle();
    expect(scroll.offset, 0, reason: 'the list must not take the stroke');
    final total = moves.fold(Offset.zero, (a, b) => a + b);
    expect(total.dy, closeTo(60, 0.01), reason: 'every pixel of the stroke goes to the cursor');
    expect(total.dx, closeTo(10, 0.01));
  });

  testWidgets('R-DK-18 (L-6): a light touch is still a left click, without moving the cursor', (t) async {
    await pump(t);
    await t.tap(find.byType(Trackpad));
    await t.pumpAndSettle();
    expect(taps, 1);
    expect(moves.fold(Offset.zero, (a, b) => a + b), Offset.zero);
  });

  testWidgets('(L-6): outside the trackpad the screen still scrolls', (t) async {
    await pump(t);
    await t.dragFrom(const Offset(200, 50), const Offset(0, -200)); // the space above the trackpad
    await t.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
  });
}
