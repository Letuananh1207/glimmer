import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'l10n/app_localizations.dart';
import 'routing/photo_source_lifecycle.dart';
import 'routing/polling_lifecycle.dart';
import 'routing/router.dart';
import 'ui/core/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = await Dependencies.create();
  runApp(GlimmerApp(deps));
  deps.device.discover();
}

class GlimmerApp extends StatefulWidget {
  const GlimmerApp(this.deps, {super.key});
  final Dependencies deps;

  @override
  State<GlimmerApp> createState() => _GlimmerAppState();
}

class _GlimmerAppState extends State<GlimmerApp> {
  late final _router = buildRouter(widget.deps.device);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: widget.deps.providers,
    child: PollingLifecycle(
      device: widget.deps.device,
      child: PhotoSourceLifecycle(
        device: widget.deps.device,
        source: widget.deps.photoSource,
        child: MaterialApp.router(
          title: 'glimmer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    ),
  );
}
