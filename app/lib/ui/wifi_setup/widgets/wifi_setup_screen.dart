import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/clawd.dart';
import '../view_models/wifi_setup_view_model.dart';

/// Put the display on a Wi-Fi network (screen_specs §5).
class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key, required this.viewModel});

  final WifiSetupViewModel viewModel;

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _ssid = TextEditingController();
  final _pass = TextEditingController();
  bool _show = false;

  /// Gap under the status line (design: 10).
  static const _statusGap = 10.0;

  WifiSetupViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.addListener(_takeSuggestion);
    vm.prefill();
  }

  void _takeSuggestion() {
    final s = vm.suggestedSsid;
    if (s != null && _ssid.text.isEmpty) _ssid.text = s;
  }

  @override
  void dispose() {
    vm.removeListener(_takeSuggestion);
    _ssid.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _status(AppLocalizations l) => switch (vm.status) {
        WifiStatus.direct => l.wifiStepDirect,
        WifiStatus.joinAp => l.wifiStepJoinAp,
        WifiStatus.send => l.wifiStepSend(vm.ssid),
        WifiStatus.wait => l.wifiStepWait(vm.ssid),
        WifiStatus.done => l.wifiDone(vm.ssid),
        WifiStatus.failed => l.wifiFailed,
      };

  String _detail(AppLocalizations l) => switch (vm.status) {
        WifiStatus.joinAp => l.wifiStepJoinApDetail,
        WifiStatus.wait => l.wifiStepWaitDetail,
        WifiStatus.done => l.wifiDoneDetail(vm.ip),
        WifiStatus.failed => vm.error == null ? '' : l.error(vm.error!),
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final step = vm.step;
        return PopScope(
          canPop: !vm.busy,
          child: Scaffold(
            appBar: AppBar(title: Text(l.wifiTitle)),
            body: ListView(padding: const EdgeInsets.all(AppSpace.xl), children: [
              Center(
                child: Clawd(
                  mood: switch (step) {
                    WifiStep.done => ClawdMood.happy,
                    WifiStep.failed => ClawdMood.sad,
                    _ => ClawdMood.open,
                  },
                  walking: vm.busy,
                  size: AppSize.clawdWifi,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              if (step == WifiStep.form) ...[
                Text(l.wifiNote, style: AppFonts.label),
                const SizedBox(height: AppSpace.l),
                TextField(controller: _ssid, decoration: InputDecoration(labelText: l.wifiSsid)),
                const SizedBox(height: AppSpace.m),
                TextField(
                  controller: _pass,
                  obscureText: !_show,
                  decoration: InputDecoration(
                    labelText: l.wifiPass,
                    suffixIcon: IconButton(
                      icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _show = !_show),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                FilledButton.icon(
                  onPressed: () => vm.send(_ssid.text, _pass.text),
                  icon: const Icon(Icons.send),
                  label: Text(l.wifiSend),
                ),
              ] else ...[
                Text(
                  _status(l),
                  textAlign: TextAlign.center,
                  style: AppFonts.heading.copyWith(
                    color: switch (step) {
                      WifiStep.done => AppColors.mint,
                      WifiStep.failed => AppColors.coral,
                      _ => AppColors.ink,
                    },
                  ),
                ),
                const SizedBox(height: _statusGap),
                Text(_detail(l), textAlign: TextAlign.center, style: AppFonts.body),
                const SizedBox(height: AppSpace.xxl),
                if (vm.busy) const Center(child: CircularProgressIndicator()),
                if (step == WifiStep.failed) FilledButton(onPressed: vm.backToForm, child: Text(l.commonRetry)),
                if (step == WifiStep.done)
                  FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.wifiDoneButton)),
              ],
            ]),
          ),
        );
      },
    );
  }
}
