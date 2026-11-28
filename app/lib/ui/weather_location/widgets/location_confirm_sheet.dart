import 'package:flutter/material.dart';

import '../../../domain/models/weather_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/weather_location_view_model.dart';
import 'location_parts.dart';

/// Black 60 % behind the sheet.
const _overlay = 0.6;

/// `LocationConfirmSheet` (§9, state `confirm` / `sending` / `sendFailed` / `oldFw`): sets [place] (or, [place] null,
/// renames the current one). Completes true when the device took it.
Future<bool> showLocationConfirm(BuildContext context, WeatherLocationViewModel vm, {PlaceResult? place}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    barrierColor: AppColors.bg.withValues(alpha: _overlay),
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.radiusSheet))),
    builder: (_) => _ConfirmSheet(vm: vm, place: place),
  );
  vm.sheetClosed();
  return ok ?? false;
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.vm, required this.place});

  final WeatherLocationViewModel vm;
  final PlaceResult? place;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.place?.name ?? widget.vm.current.place);

  static const _handleW = 36.0, _handleH = 4.0, _btnH = 48.0, _spinner = 18.0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final vm = widget.vm, p = widget.place;
    final ok = p == null ? await vm.rename(_name.text) : await vm.apply(p, _name.text);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final vm = widget.vm;
    final p = widget.place;
    final named = vm.placeSupported;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpace.xl, 10, AppSpace.xl, 28 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: _handleW,
                  height: _handleH,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(_handleH / 2)),
                ),
              ),
              if (vm.sendFailed)
                LocationBanner(
                  title: l.weatherLocationRejectedTitle,
                  body: l.weatherLocationRejectedBody,
                  color: AppColors.coral,
                  margin: const EdgeInsets.only(bottom: 14),
                ),
              Text(
                p == null ? l.weatherLocationRenameTitle : l.weatherLocationConfirmTitle,
                style: locText(16, weight: FontWeight.w700),
              ),
              if (p != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, AppSpace.xs, 0, AppSpace.l),
                  child: Text(
                    [if (p.area.isNotEmpty) p.area, l.weatherLocationCoords(_c(p.lat), _c(p.lon))].join(' · '),
                    style: locText(12, color: AppColors.muted),
                  ),
                )
              else
                const SizedBox(height: AppSpace.l),
              if (named) ...[
                Text(l.weatherLocationNameLabel, style: AppFonts.label),
                const SizedBox(height: AppSpace.s),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _name,
                  builder: (context, v, _) => TextField(
                    controller: _name,
                    maxLength: AppSize.locationNameMax,
                    enabled: !vm.sending,
                    style: locText(16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bg,
                      counterText: '',
                      suffixText: l.weatherLocationNameCount('${v.text.trim().runes.length}'),
                      suffixStyle: locText(12, color: AppColors.muted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.l),
                      enabledBorder: _border(),
                      focusedBorder: _border(),
                      disabledBorder: _border(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s),
                Text(l.weatherLocationNameHint, style: locText(11, color: AppColors.muted)),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _name,
                  builder: (context, v, _) => _Preview(vm: vm, name: v.text.trim()),
                ),
              ] else
                Text(l.weatherLocationOldFwSheet, style: locText(13, color: AppColors.amber)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: _SheetButton(
                      label: l.commonCancel,
                      color: AppColors.panel2,
                      text: AppColors.ink,
                      onTap: vm.sending ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 14,
                    child: _SheetButton(
                      label: vm.sending
                          ? l.weatherLocationSending
                          : vm.sendFailed
                          ? l.commonRetry
                          : p == null
                          ? l.weatherLocationSaveName
                          : named
                          ? l.weatherLocationApply
                          : l.weatherLocationApplyCoords,
                      color: AppColors.skillWeather,
                      text: AppColors.bg,
                      busy: vm.sending,
                      onTap: vm.sending ? null : _go,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _c(double v) => v.toStringAsFixed(2);

  static OutlineInputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSize.radiusSearchField),
    borderSide: const BorderSide(color: AppColors.skillWeather),
  );
}

/// Xem trước (§9): `panel2` bo 12, đệm 12 14, lề trên 14 — `weatherLocationPreview` + hai dòng 13 ink, tên 700
/// `skillWeather`.
class _Preview extends StatelessWidget {
  const _Preview({required this.vm, required this.name});

  final WeatherLocationViewModel vm;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shown = name.isEmpty ? '…' : name;
    final tz = vm.tzMinutes, a = tz.abs();
    final offset = '${tz < 0 ? '-' : '+'}${a ~/ 60}${a % 60 == 0 ? '' : ':${(a % 60).toString().padLeft(2, '0')}'}';
    Widget line(String full) {
      final i = full.lastIndexOf(shown);
      return Text.rich(
        TextSpan(
          style: locText(13),
          children: [
            TextSpan(text: i < 0 ? full : full.substring(0, i)),
            if (i >= 0)
              TextSpan(
                text: shown,
                style: locText(13, weight: FontWeight.w700, color: AppColors.skillWeather),
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.m),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(AppSize.radiusSearchField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.weatherLocationPreview, style: AppFonts.label),
          const SizedBox(height: AppSpace.xs),
          line(l.weatherLocationPreviewWeather(vm.weatherDesc.isEmpty ? '--' : vm.weatherDesc, shown)),
          line(l.weatherLocationPreviewClock(offset, shown)),
        ],
      ),
    );
  }
}

/// Nút cao 48 bo 14; [busy] = vòng xoay 18 màu [text] trước chữ.
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.color,
    required this.text,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final Color color, text;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _ConfirmSheetState._btnH,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.radiusCard)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            SizedBox.square(
              dimension: _ConfirmSheetState._spinner,
              child: CircularProgressIndicator(strokeWidth: 2, color: text),
            ),
            const SizedBox(width: AppSpace.s),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: locText(14, weight: FontWeight.w700, color: text),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Hộp thoại xoá (§9 `clear`): rộng 312, `panel`, bo 20, đệm 24 — tiêu đề 18/700, thân 13 inkDim, Hủy / Xoá (coral 700).
Future<bool> askClearLocation(BuildContext context, String place) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.radiusSheet)),
      child: SizedBox(
        width: 312,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.weatherLocationClearTitle, style: locText(18, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              Text(l.weatherLocationClearBody(place), style: locText(13, color: AppColors.inkDim)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(c).pop(false),
                    child: Text(l.commonCancel, style: locText(14, color: AppColors.inkDim)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(c).pop(true),
                    child: Text(
                      l.weatherLocationClearOk,
                      style: locText(14, weight: FontWeight.w700, color: AppColors.coral),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}
