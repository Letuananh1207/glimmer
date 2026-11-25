import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_text.dart';
import 'count_badge.dart';

/// One tab of [DockTabBar].
class DockTabItem {
  const DockTabItem({required this.id, required this.label, required this.icon, required this.accent, this.badge});

  final String id;
  final String label;

  /// Dock pixel icon, already coloured (Clawd `clawd`, others inkDim).
  final Widget icon;

  /// Underline of the selected tab (skill accent).
  final Color accent;

  /// Amber badge text ("2", "9+"); null = none.
  final String? badge;
}

/// Thanh tab của Màn hình, giống dock thiết bị nằm ngang (components.md `DockTabBar`, screen_specs §2): lề 4 16 6,
/// đệm 4, nền `panel`, bo 14, chia đều cách 4. Tab ≥ 48 bo 10: icon + 7 + nhãn 13; đang chọn nền `panel2`, nhãn 700
/// ink, vạch 20×3 màu nhấn cách đáy 3; khác nền trong, nhãn 500 inkDim.
class DockTabBar extends StatelessWidget {
  const DockTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    required this.semanticLabel,
  });

  final List<DockTabItem> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  /// `homeTabsA11y`.
  final String semanticLabel;

  static const _margin = EdgeInsets.fromLTRB(AppSpace.l, AppSpace.xs, AppSpace.l, 6);

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: semanticLabel,
        child: Container(
          margin: _margin,
          padding: const EdgeInsets.all(AppSpace.xs),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppSize.radiusDockBar),
          ),
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.xs),
              Expanded(
                child: _DockTab(
                  item: tabs[i],
                  selected: tabs[i].id == selected,
                  onTap: () => onSelect(tabs[i].id),
                ),
              ),
            ],
          ]),
        ),
      );
}

class _DockTab extends StatelessWidget {
  const _DockTab({required this.item, required this.selected, required this.onTap});

  final DockTabItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _label = 13.0;
  static const _gap = 7.0;
  static const _padH = 6.0;
  static const _barW = 20.0, _barH = 3.0, _barBottom = 3.0, _barRadius = 2.0;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AppColors.panel2 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSize.radiusDockTab),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.dockTab),
              child: Stack(alignment: Alignment.center, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _padH),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    item.icon,
                    const SizedBox(width: _gap),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: _label,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.ink : AppColors.inkDim,
                        ),
                      ),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(width: _gap),
                      CountBadge(item.badge!),
                    ],
                  ]),
                ),
                if (selected)
                  Positioned(
                    bottom: _barBottom,
                    child: Container(
                      width: _barW,
                      height: _barH,
                      decoration: BoxDecoration(
                        color: item.accent,
                        borderRadius: BorderRadius.circular(_barRadius),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
}
