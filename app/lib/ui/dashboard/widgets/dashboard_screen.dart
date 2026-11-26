import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/labels.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/dock_tab_bar.dart';
import '../../core/widgets/show_on_device_button.dart';
import '../view_models/dashboard_view_model.dart';
import '../view_models/photo_tab_view_model.dart';
import 'clock_tab.dart';
import 'dashboard_cards.dart';
import 'dashboard_header.dart';
import 'dashboard_usage.dart';
import 'photo_tab.dart';
import 'weather_tab.dart';

/// Số liệu (screen_specs §2; màn phụ đẩy từ Điều khiển từ 2026-11-26.5): thanh trên "← Số liệu" + refresh, `DockTabBar` theo skill đang bật (≥ 2), thân tab đang chọn
/// + `ShowOnDeviceButton`.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.viewModel,
    required this.photos,
    required this.onOpenSettings,
    required this.onCropPhoto,
    required this.onBack,
  });

  final DashboardViewModel viewModel;

  /// Tab Ảnh (R-SK-6: shown only while skill Ảnh is on).
  final PhotoTabViewModel photos;

  /// `weatherSetLocation`: tab Cài đặt (ô vị trí chưa vẽ).
  final VoidCallback onOpenSettings;

  /// Tab Ảnh: open PhotoCrop (push, above the tabs); completes when it closes.
  final Future<void> Function(PhotoCropArgs args) onCropPhoto;

  /// Back to Điều khiển (Số liệu is pushed from it, 2026-11-26.5).
  final VoidCallback onBack;

  Future<void> _crop(Uint8List image, PhotoInfo info) => onCropPhoto((image: image, info: info));

  /// Dock icons in the tab bar: ×1.25.
  static const _tabIconScale = 1.25;

  /// Show [done] or the error once [action] finishes.
  Future<void> _act(BuildContext context, Future<Result<void>> Function() action, String done) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final r = await action();
    final text = switch (r) {
      Ok() => done,
      Error(:final error) => l.error(AppError.from(error)),
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final s = viewModel.state;
        if (s == null) return const Center(child: CircularProgressIndicator());
        final error = viewModel.error;
        final errorLine = error != null ? l.error(error) : (viewModel.cardsNeedToken ? l.devCardsNeedToken : null);
        final selected = viewModel.selected;
        final skillName = SkillStyle.name(l, selected);
        final badge = viewModel.waitingBadge;
        return RefreshIndicator(
          onRefresh: () => Future.wait([viewModel.refresh(), if (selected == 'photo') photos.load()]),
          child: ListView(padding: EdgeInsets.zero, children: [
            DetailsTopBar(
              onBack: onBack,
              onRefresh: () => _act(context, viewModel.refreshNow, l.dashboardDoneRefresh),
            ),
            if (errorLine != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.xs),
                child: Text(errorLine, style: AppFonts.label.copyWith(color: AppColors.amber, letterSpacing: 0)),
              ),
            if (s.inSetupMode) SetupNote(text: l.dashboardSetupNote),
            if (viewModel.showTabs)
              DockTabBar(
                semanticLabel: l.homeTabsA11y,
                selected: selected,
                onSelect: viewModel.select,
                tabs: [
                  for (final id in viewModel.tabs)
                    DockTabItem(
                      id: id,
                      label: SkillStyle.name(l, id),
                      icon: SkillStyle.dockIcon(id,
                          color: id == 'agent' ? AppColors.clawd : AppColors.inkDim, scale: _tabIconScale),
                      accent: SkillStyle.of(id).accent,
                      badge: id == 'agent' ? badge : null,
                    ),
                ],
              ),
            ...switch (selected) {
              'photo' => [PhotoTab(viewModel: photos, deviceCount: viewModel.photoCount, onCrop: _crop)],
              'weather' => [WeatherCard(view: viewModel.weather, onSetLocation: onOpenSettings)],
              'clock' => [ClockCard(view: viewModel.clock)],
              _ => [
                  UsageCard(meta: viewModel.meta, week: viewModel.week, session: viewModel.session),
                  ProjectsCard(
                    projects: viewModel.rows,
                    onClear: () => _act(context, viewModel.clearProjects, l.dashboardDoneProjectsCleared),
                  ),
                  CardsCard(
                    cards: viewModel.cards,
                    onClear: (id) => _act(context, () => viewModel.clearCard(id), l.dashboardDoneCardCleared),
                    onClearAll: () => _act(context, viewModel.clearAllCards, l.dashboardDoneCardsCleared),
                  ),
                ],
            },
            // weatherNoLoc: no button (nothing to show yet).
            if (!(selected == 'weather' && viewModel.weather.status == WeatherStatus.noLocation))
              ShowOnDeviceButton(
                label: l.homeShowOnDevice(skillName),
                onPressed: () => _act(context, viewModel.showOnDevice, l.devShowOnDeviceDone(skillName)),
              ),
          ]),
        );
      },
    );
  }
}
