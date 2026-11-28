import 'package:flutter/material.dart';

import '../../../domain/models/app_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/result.dart';
import '../../core/labels.dart';
import '../../core/themes/app_text.dart';
import '../view_models/settings_view_model.dart';
import 'settings_tiles.dart';

/// Device settings (screen_specs §3).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.viewModel, required this.onOpenWeatherLocation});

  final SettingsViewModel viewModel;

  /// THỜI TIẾT › Vị trí thời tiết (2026-11-26.9): pushes the screen, completes when it closes.
  final Future<void> Function() onOpenWeatherLocation;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsViewModel get vm => widget.viewModel;

  /// Room under the list for the save bar (design: 96).
  static const _barRoom = 96.0;

  @override
  void initState() {
    super.initState();
    vm.load();
  }

  String _hhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Future<void> _pickTime(String key, int fallback) async {
    final m = vm.value<int>(key, fallback);
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    if (t != null) vm.set(key, t.hour * 60 + t.minute);
  }

  /// THỜI TIẾT row: the place name, "chưa đặt", or the coordinates (old firmware / no name).
  String _placeSub(AppLocalizations l) {
    final lat = vm.value<double>('weatherLat', 0), lon = vm.value<double>('weatherLon', 0);
    if (lat == 0 && lon == 0) return l.settingsWeatherLocationNone;
    final place = vm.value<String>('weatherPlace', '');
    return place.isNotEmpty ? place : l.weatherLocationCoords(lat.toStringAsFixed(2), lon.toStringAsFixed(2));
  }

  String _secretSub(AppLocalizations l, String key) => switch (vm.secret(key)) {
        SecretState.pending => l.settingsSecretPending,
        SecretState.set => l.settingsSecretSet,
        SecretState.unset => l.settingsSecretUnset,
      };

  Future<void> _secret(String key, String title, String hint) async {
    final v = await askText(context, title: title, hint: hint, obscure: true);
    if (v != null) vm.set(key, v);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final r = await vm.save();
    messenger.showSnackBar(SnackBar(
      content: Text(switch (r) {
        Ok() => l.settingsSaved,
        Error(:final error) => l.error(AppError.from(error)),
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (!vm.loaded) {
          final e = vm.loadError;
          return Center(
            child: e == null
                ? const CircularProgressIndicator()
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(l.error(e), style: AppFonts.body),
                    TextButton(onPressed: vm.load, child: Text(l.commonRetry)),
                  ]),
          );
        }
        return Stack(children: [
          ListView(padding: const EdgeInsets.only(bottom: _barRoom), children: _rows(l)),
          if (vm.hasChanges)
            Positioned(
              left: AppSpace.l,
              right: AppSpace.l,
              bottom: AppSpace.l,
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(onPressed: vm.saving ? null : vm.discard, child: Text(l.settingsDiscard)),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: FilledButton(
                    onPressed: vm.saving ? null : _save,
                    child: Text(vm.saving ? l.settingsSaving : l.settingsSaveCount('${vm.changeCount}')),
                  ),
                ),
              ]),
            ),
        ]);
      },
    );
  }

  List<Widget> _rows(AppLocalizations l) {
    final night = vm.nightMode;
    Widget sw(String key, String title, [String? sub]) =>
        SettingsSwitch(title: title, sub: sub, value: vm.value<bool>(key, false), onChanged: (v) => vm.set(key, v));
    Widget choice(String key, String title, Map<int, String> options) => SettingsChoice(
        title: title, value: vm.value<int>(key, options.keys.first), options: options, onChanged: (v) => vm.set(key, v));
    Widget slider(String key, String title) => SettingsSlider(
        title: title, value: vm.value<int>(key, 5), min: 5, max: 100, onChanged: (v) => vm.set(key, v));
    final userName = vm.value<String>('userName', '');
    return [
      SettingsSection(title: l.settingsSectionDisplay),
      slider('brightness', l.settingsBrightness),
      sw('idleDim', l.settingsIdleDim, l.settingsIdleDimSub),
      sw('claudeWeeklyHero', l.settingsWeeklyHero, l.settingsWeeklyHeroSub),
      sw('clock24h', l.settingsClock24h),
      SettingsSection(title: l.settingsSectionNight),
      choice('nightMode', l.settingsNightMode, {
        0: l.settingsNightNone,
        1: l.settingsNightDim,
        2: l.settingsNightClock,
        3: l.settingsNightOff,
      }),
      // R-CD-3.
      if (night != 0) ...[
        ListTile(
          title: Text(l.settingsNightFrom),
          trailing: Text(_hhmm(vm.value<int>('nightStartMin', 1380))),
          onTap: () => _pickTime('nightStartMin', 1380),
        ),
        ListTile(
          title: Text(l.settingsNightTo),
          trailing: Text(_hhmm(vm.value<int>('nightEndMin', 420))),
          onTap: () => _pickTime('nightEndMin', 420),
        ),
        if (night == 1) slider('nightBright', l.settingsNightBright),
      ],
      // THỜI TIẾT (2026-11-26.9): one row to Vị trí thời tiết; not part of Lưu (the screen sends on its own).
      SettingsSection(title: l.settingsSectionWeather),
      SettingsEditTile(
        title: l.settingsWeatherLocation,
        sub: _placeSub(l),
        icon: Icons.chevron_right,
        onTap: () async {
          await widget.onOpenWeatherLocation();
          await vm.refreshLocation();
        },
      ),
      SettingsSection(title: l.settingsSectionClaude),
      SettingsEditTile(
        title: l.settingsClaudeKey,
        sub: _secretSub(l, 'claudeKey'),
        onTap: () => _secret('claudeKey', l.settingsClaudeKey, l.settingsClaudeKeyHint),
      ),
      choice('refreshMin', l.settingsRefresh, {for (final m in [1, 2, 3, 5, 10, 15]) m: l.settingsMinutes('$m')}),
      SettingsEditTile(
        title: l.settingsUserName,
        sub: userName.isEmpty ? l.settingsSecretUnset : userName,
        onTap: () async {
          final v = await askText(context, title: l.settingsUserName, initial: userName, maxLength: 16, cancel: false);
          if (v != null) vm.set('userName', v);
        },
      ),
      SettingsSection(title: l.settingsSectionAgent),
      sw('showAgents', l.settingsShowAgents, l.settingsShowAgentsSub),
      sw('pinApprovals', l.settingsPinApprovals),
      sw('agentDoneCards', l.settingsDoneCards),
      choice('approvalTtlMin', l.settingsApprovalTtl, {
        5: l.settingsMinutes('5'),
        15: l.settingsMinutes('15'),
        30: l.settingsMinutes('30'),
        60: l.settingsHour,
        0: l.settingsNever,
      }),
      SettingsEditTile(
        title: l.settingsApiToken,
        sub: _secretSub(l, 'apiToken'),
        onTap: () => _secret('apiToken', l.settingsApiToken, l.settingsApiTokenHint),
      ),
      SettingsEditTile(
        title: l.settingsAppToken,
        sub: vm.appTokenSaved ? l.settingsSecretSet : l.settingsNone,
        icon: Icons.key,
        onTap: () async {
          final v = await askText(context,
              title: l.settingsAppTokenTitle,
              initial: vm.appToken,
              obscure: true,
              cancel: false,
              autofocus: false,
              trim: false,
              okLabel: l.commonSave);
          if (v != null) vm.setAppToken(v);
        },
      ),
    ];
  }
}
