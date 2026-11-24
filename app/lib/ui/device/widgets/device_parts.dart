import 'package:flutter/material.dart';

import '../../../domain/models/device_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/durations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// "25/11/2026 10:21", "?" when unknown.
String formatDate(DateTime? d) => d == null
    ? '?'
    : '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Body text 13 (design) for values and the update line.
const valueSize = 13.0;

/// Progress card on `panel2` (R-TB-4).
class BusyCard extends StatelessWidget {
  const BusyCard({super.key, required this.text, required this.progress});

  final String text;
  final double? progress;

  /// Gaps (design: 10 under the title, 6 under the bar).
  static const _titleGap = 10.0;
  static const _barGap = 6.0;

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.panel2,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: AppFonts.heading.copyWith(color: AppColors.ink)),
            const SizedBox(height: _titleGap),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: _barGap),
            Text(AppLocalizations.of(context).deviceBusyNote, style: AppFonts.label),
          ]),
        ),
      );
}

/// THIẾT BỊ: firmware, build, Wi-Fi, IP, uptime, heap.
class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key, required this.state});

  final DeviceState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.deviceInfo, style: AppFonts.label),
          const SizedBox(height: AppSpace.s),
          _Kv(l.deviceFirmware, s.fw),
          _Kv(l.deviceBuild, formatDate(s.buildTime)),
          _Kv(l.deviceWifi, s.inSetupMode ? l.deviceSetupMode : l.devWifiRssi(s.ssid, s.rssi)),
          _Kv(l.deviceIp, s.ip),
          _Kv(l.deviceUptime, agoShort(s.uptimeS)),
          _Kv(l.deviceHeap, l.deviceHeapValue('${s.heap ~/ 1024}', '${s.maxBlock ~/ 1024}')),
        ]),
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.k, this.v);

  final String k, v;

  /// Key column (design: 120) and row padding (design: 3).
  static const _keyWidth = 120.0;
  static const _rowPad = 3.0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: _rowPad),
        child: Row(children: [
          SizedBox(width: _keyWidth, child: Text(k, style: AppFonts.label)),
          Expanded(child: Text(v, style: const TextStyle(color: AppColors.ink, fontSize: valueSize))),
        ]),
      );
}
