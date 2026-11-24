import 'package:flutter/material.dart';

import '../../../domain/models/app_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/result.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/dashboard_view_model.dart';
import 'dashboard_cards.dart';
import 'dashboard_header.dart';
import 'dashboard_usage.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

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
        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: ListView(padding: const EdgeInsets.only(bottom: AppSpace.xxl), children: [
            DashboardHeader(state: s, mood: viewModel.mood, walking: viewModel.walking),
            if (errorLine != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.xs),
                child: Text(errorLine, style: AppFonts.label.copyWith(color: AppColors.amber, letterSpacing: 0)),
              ),
            if (s.inSetupMode) SetupNote(text: l.dashboardSetupNote),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.s, AppSpace.l, 0),
              child: Wrap(spacing: _gap, runSpacing: _gap, children: [
                FilledButton.tonalIcon(
                  onPressed: () => _act(context, viewModel.refreshNow, l.dashboardDoneRefresh),
                  icon: const Icon(Icons.refresh),
                  label: Text(l.dashboardRefreshNow),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _act(context, viewModel.showClaude, l.dashboardDoneShowClaude),
                  icon: const Icon(Icons.tv),
                  label: Text(l.dashboardShowClaude),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  /// Between the two action buttons (design: 10).
  static const _gap = 10.0;
}
