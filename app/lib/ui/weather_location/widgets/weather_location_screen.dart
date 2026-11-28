import 'package:flutter/material.dart';

import '../../../domain/models/weather_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/weather_location_view_model.dart';
import 'location_confirm_sheet.dart';
import 'location_parts.dart';

/// Vị trí thời tiết (screen_specs §9, design 2026-11-26.9): màn đẩy — thanh trên, thẻ "Thiết bị đang dùng", nút "Dùng
/// vị trí hiện tại" (+ thanh báo GPS), tìm thành phố (ô + ghi chú + kết quả), bảng xác nhận, hộp thoại xoá, thông báo
/// nhỏ khi thiết bị nhận.
class WeatherLocationScreen extends StatefulWidget {
  const WeatherLocationScreen({super.key, required this.viewModel, required this.onBack});

  final WeatherLocationViewModel viewModel;
  final VoidCallback onBack;

  @override
  State<WeatherLocationScreen> createState() => _WeatherLocationScreenState();
}

class _WeatherLocationScreenState extends State<WeatherLocationScreen> {
  final _search = TextEditingController();

  static const _barH = 56.0, _back = 48.0, _title = 18.0;

  WeatherLocationViewModel get vm => widget.viewModel;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirm(PlaceResult? place) => showLocationConfirm(context, vm, place: place);

  Future<void> _gps() async {
    final p = await vm.useGps();
    if (p != null && mounted) await _confirm(p);
  }

  Future<void> _clear() async {
    if (await askClearLocation(context, vm.current.place)) await vm.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: AppSpace.xxl),
            children: [
              SizedBox(
                height: _barH,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpace.s),
                    SizedBox.square(
                      dimension: _back,
                      child: IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s),
                    Text(l.weatherLocationTitle, style: locText(_title, weight: FontWeight.w700)),
                  ],
                ),
              ),
              if (vm.loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpace.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _CurrentCard(vm: vm, onRename: () => _confirm(null), onClear: _clear),
                LocationGpsButton(loading: vm.gps == GpsState.loading, onTap: _gps),
                ?_gpsBanner(l),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.xl, 18, AppSpace.xl, AppSpace.s),
                  child: Text(l.weatherLocationSearchSection, style: AppFonts.label),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                  child: LocationSearchField(controller: _search, onChanged: vm.setQuery),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.l + AppSpace.xs, 6, AppSpace.l + AppSpace.xs, 0),
                  child: Text(l.weatherLocationSearchPrivacy, style: locText(11, color: AppColors.muted)),
                ),
                ?_searchBody(l),
              ],
            ],
          ),
          if (vm.done != null)
            Positioned(
              left: AppSpace.l,
              right: AppSpace.l,
              bottom: AppSpace.xxl,
              child: LocationDoneNote(text: l.weatherLocationDone(vm.done!)),
            ),
        ],
      ),
    );
  }

  Widget? _gpsBanner(AppLocalizations l) => switch (vm.gps) {
    GpsState.denied => LocationBanner(
      title: l.weatherLocationGpsDeniedTitle,
      body: l.weatherLocationGpsDeniedBody,
      color: AppColors.amber,
    ),
    GpsState.deniedForever => LocationBanner(
      title: l.weatherLocationGpsDeniedTitle,
      body: l.weatherLocationGpsDeniedBody,
      color: AppColors.amber,
      action: l.weatherLocationOpenAppSettings,
      onAction: vm.openAppSettings,
    ),
    GpsState.off => LocationBanner(
      title: l.weatherLocationGpsOffTitle,
      body: l.weatherLocationGpsOffBody,
      color: AppColors.amber,
      action: l.weatherLocationTurnOnGps,
      onAction: vm.openLocationSettings,
    ),
    GpsState.failed => LocationBanner(
      title: l.weatherLocationGpsFailTitle,
      body: l.weatherLocationGpsFailBody,
      color: AppColors.coral,
      action: l.commonRetry,
      onAction: _gps,
      outlined: false,
    ),
    GpsState.idle || GpsState.loading => null,
  };

  Widget? _searchBody(AppLocalizations l) {
    const margin = EdgeInsets.fromLTRB(AppSpace.l, 10, AppSpace.l, 0);
    final card = BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(AppSize.radiusCard));
    switch (vm.search) {
      case SearchState.idle:
        return null;
      case SearchState.searching:
        return Container(
          margin: margin,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
          decoration: card,
          child: Row(
            children: [
              const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: AppSpace.m),
              Text(l.weatherLocationSearching, style: locText(14, color: AppColors.inkDim)),
            ],
          ),
        );
      case SearchState.none:
        return Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 18),
          decoration: card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.weatherLocationNoResultsTitle(vm.query.trim()), style: locText(14, weight: FontWeight.w700)),
              const SizedBox(height: AppSpace.xs),
              Text(l.weatherLocationNoResultsBody, style: locText(13, color: AppColors.inkDim)),
            ],
          ),
        );
      case SearchState.error:
        return LocationBanner(
          title: l.weatherLocationSearchErrorTitle,
          body: l.weatherLocationSearchErrorBody,
          color: AppColors.coral,
          action: l.commonRetry,
          onAction: vm.retrySearch,
          outlined: false,
          margin: margin,
        );
      case SearchState.results:
        return Container(
          margin: margin,
          decoration: card,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, p) in vm.results.indexed) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.line),
                InkWell(
                  onTap: () => _confirm(p),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.s),
                      child: Row(
                        children: [
                          const Icon(Icons.place, size: 20, color: AppColors.muted),
                          const SizedBox(width: AppSpace.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: locText(16)),
                                Text(
                                  l.weatherLocationResultSub(
                                    p.area,
                                    p.lat.toStringAsFixed(2),
                                    p.lon.toStringAsFixed(2),
                                  ),
                                  style: locText(12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }
}

/// Thẻ "Thiết bị đang dùng" (§9): `panel`, bo 14, đệm 16, lề 6 16 — label, ô 40 + place, tên 20/700, toạ độ 12 muted;
/// kẻ `line`, Sửa tên / Xoá vị trí. Chưa đặt: ô `panel2`, icon muted, tiêu đề + thân, không nút. Firmware cũ: tên =
/// toạ độ + ghi chú amber.
class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.vm, required this.onRename, required this.onClear});

  final WeatherLocationViewModel vm;
  final VoidCallback onRename, onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = vm.current;
    final set = c.isSet;
    final lat = c.lat.toStringAsFixed(2), lon = c.lon.toStringAsFixed(2);
    final name = !vm.placeSupported || c.place.isEmpty ? l.weatherLocationCoords(lat, lon) : c.place;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 6),
      padding: const EdgeInsets.all(AppSpace.l),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.weatherLocationCurrent, style: AppFonts.label),
          const SizedBox(height: AppSpace.m),
          Row(
            children: [
              LocationIconBox(
                color: set ? AppColors.skillWeatherTint : AppColors.panel2,
                child: Icon(Icons.place, size: 24, color: set ? AppColors.skillWeather : AppColors.muted),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: set
                      ? [
                          Text(name, style: locText(20, weight: FontWeight.w700)),
                          if (vm.placeSupported && c.place.isNotEmpty)
                            Text(l.weatherLocationCoords(lat, lon), style: locText(12, color: AppColors.muted)),
                        ]
                      : [
                          Text(l.weatherNoLocationTitle, style: locText(16, weight: FontWeight.w700)),
                          Text(l.weatherLocationUnsetBody, style: locText(13, color: AppColors.inkDim)),
                        ],
                ),
              ),
            ],
          ),
          if (set && !vm.placeSupported)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(l.weatherLocationOldFwNote, style: locText(12, color: AppColors.amber)),
            ),
          if (set) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 14, 0, AppSpace.xs),
              child: Divider(height: 1, thickness: 1, color: AppColors.line),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (vm.placeSupported)
                  TextButton(
                    onPressed: onRename,
                    style: TextButton.styleFrom(minimumSize: const Size(0, AppSize.tapMin)),
                    child: Text(
                      l.weatherLocationRename,
                      style: locText(13, weight: FontWeight.w500, color: AppColors.inkDim),
                    ),
                  ),
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(minimumSize: const Size(0, AppSize.tapMin)),
                  child: Text(
                    l.weatherLocationClear,
                    style: locText(13, weight: FontWeight.w500, color: AppColors.coral),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
