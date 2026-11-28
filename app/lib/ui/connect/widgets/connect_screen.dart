import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/clawd.dart';
import '../view_models/connect_view_model.dart';

/// Shown until a display answers (screen_specs §1).
class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key, required this.viewModel, required this.onNewDevice});

  final ConnectViewModel viewModel;

  /// "Quét mã QR trên màn thiết bị" → Quét mã → Cài Wi-Fi (2026-11-28.12).
  final VoidCallback onNewDevice;

  /// Gap between the mascot and the title (design: 28).
  static const _clawdGap = 28.0;

  /// Gap between the stacked buttons (design: 10).
  static const _buttonGap = 10.0;

  Future<void> _manual(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ip = TextEditingController(text: viewModel.savedAddress);
    final token = TextEditingController(text: viewModel.savedToken);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.connectManualTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.connectManualHint, style: AppFonts.label),
          const SizedBox(height: AppSpace.m),
          TextField(controller: ip, decoration: InputDecoration(labelText: l.connectManualIp)),
          const SizedBox(height: AppSpace.m),
          TextField(
            controller: token,
            decoration: InputDecoration(labelText: l.connectManualToken),
            obscureText: true,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.connectManualOk)),
        ],
      ),
    );
    if (ok == true) await viewModel.connect(ip.text, token.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              final searching = viewModel.searching;
              final error = viewModel.error;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Spacer(),
                Center(
                  child: Clawd(
                    mood: searching ? ClawdMood.open : ClawdMood.sleep,
                    walking: searching,
                    size: AppSize.clawdConnect,
                  ),
                ),
                const SizedBox(height: _clawdGap),
                Text(
                  searching ? l.connectSearchingTitle : l.connectIdleTitle,
                  textAlign: TextAlign.center,
                  style: AppFonts.screenTitle.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpace.s),
                Text(
                  searching ? l.connectSearchingBody : (error == null ? l.connectIdleBody : l.error(error)),
                  textAlign: TextAlign.center,
                  style: AppFonts.body,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: searching ? null : viewModel.retry,
                  icon: const Icon(Icons.search),
                  label: Text(l.connectRetry),
                ),
                const SizedBox(height: _buttonGap),
                OutlinedButton.icon(
                  onPressed: searching ? null : () => _manual(context),
                  icon: const Icon(Icons.edit),
                  label: Text(l.connectManual),
                ),
                const SizedBox(height: _buttonGap),
                OutlinedButton.icon(
                  onPressed: searching ? null : onNewDevice,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l.connectNewDevice),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}
