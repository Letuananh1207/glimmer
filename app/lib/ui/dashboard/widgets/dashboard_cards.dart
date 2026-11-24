import 'package:flutter/material.dart';

import '../../../domain/models/attention_card.dart';
import '../../../domain/models/project.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/durations.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/themes/status_colors.dart';

/// Card padding: 16 left, 12 top, 8 right / bottom (design).
const _cardPad = EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.s, AppSpace.s);

/// Small text button in a card title row (design: 12).
final _smallButton = TextStyle(fontSize: AppFonts.label.fontSize);

/// PROJECT board (R-PRJ-1).
class ProjectsCard extends StatelessWidget {
  const ProjectsCard({super.key, required this.projects, required this.onClear});

  final List<Project> projects;
  final VoidCallback onClear;

  /// State square (design: 12).
  static const _square = 12.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: _cardPad,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l.dashboardProjects, style: AppFonts.label),
            const Spacer(),
            if (projects.isNotEmpty)
              TextButton(onPressed: onClear, child: Text(l.dashboardProjectsClear, style: _smallButton)),
          ]),
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
              child: Text(l.dashboardProjectsEmpty, style: AppFonts.body),
            ),
          for (final p in projects)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.square, size: _square, color: StatusColors.projectState(p.state)),
              minLeadingWidth: _square,
              title: Text(p.project, style: const TextStyle(color: AppColors.ink)),
              subtitle: Text(
                [l.projectState(p.state), if (p.detail.isNotEmpty) p.detail, if (p.agent != 'claude') p.agent]
                    .join(' · '),
                style: AppFonts.label.copyWith(color: StatusColors.projectState(p.state), letterSpacing: 0),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: AppSpace.s),
                child: Text(agoShort(p.ageS), style: AppFonts.label),
              ),
            ),
        ]),
      ),
    );
  }
}

/// THẺ TRÊN MÀN HÌNH — the device's attention queue; hidden when empty.
class CardsCard extends StatelessWidget {
  const CardsCard({super.key, required this.cards, required this.onClear, required this.onClearAll});

  final List<AttentionCard> cards;
  final void Function(String id) onClear;
  final VoidCallback onClearAll;

  /// Close icon (design: 18).
  static const _close = 18.0;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: _cardPad,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l.dashboardCards, style: AppFonts.label),
            const Spacer(),
            TextButton(onPressed: onClearAll, child: Text(l.dashboardCardsClearAll, style: _smallButton)),
          ]),
          for (final k in cards)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(k.title.isEmpty ? l.cardKind(k.kind) : k.title,
                  style: TextStyle(color: StatusColors.cardKind(k.kind))),
              subtitle: Text(
                [l.cardKind(k.kind), if (k.project.isNotEmpty) k.project, if (k.body.isNotEmpty) k.body, l.ago(k.ageS)]
                    .join(' · '),
                style: AppFonts.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(icon: const Icon(Icons.close, size: _close), onPressed: () => onClear(k.id)),
            ),
        ]),
      ),
    );
  }
}
