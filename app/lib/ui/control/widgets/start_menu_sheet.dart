import 'package:flutter/material.dart';

import '../../../domain/models/touch.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/clawd.dart';
import 'all_programs_sheet.dart';
import 'program_style.dart';
import 'start_parts.dart';

/// What Start and Tất cả chương trình can do; each closes the sheet first.
class StartActions {
  const StartActions({
    required this.programs,
    required this.open,
    required this.onOpen,
    required this.onDesktop,
    required this.onDetails,
    required this.onControlPanel,
    required this.onAddRemove,
    required this.onDevice,
    required this.onTurnOff,
    required this.onRestart,
    this.programsEnabled = true,
  });

  /// R-DK-9: installed programs by group.
  final Map<ProgramGroup, List<String>> programs;

  /// Programs with an open window (the mint dot).
  final Set<String> open;

  /// Opening a program reaches the device (connected, screen on, not the night face).
  final bool programsEnabled;

  final ValueChanged<String> onOpen;
  final VoidCallback onDesktop, onDetails, onControlPanel, onAddRemove, onDevice, onTurnOff, onRestart;
}

/// Opens Start (`StartMenuSheet`, with Tất cả chương trình one level in) above the whole screen, bottom bar included.
Future<void> showStartMenu(BuildContext context, StartActions actions) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  barrierColor: AppColors.bg.withValues(alpha: _overlay),
  backgroundColor: AppColors.panel,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.radiusSheet))),
  builder: (_) => _StartHost(actions: actions),
);

/// Black 60 % over the screen.
const _overlay = 0.6;

class _StartHost extends StatefulWidget {
  const _StartHost({required this.actions});

  final StartActions actions;

  @override
  State<_StartHost> createState() => _StartHostState();
}

class _StartHostState extends State<_StartHost> {
  bool _all = false;

  /// Close the sheet, then act.
  void Function() _then(VoidCallback f) => () {
    Navigator.of(context).pop();
    f();
  };

  @override
  Widget build(BuildContext context) {
    final a = widget.actions;
    void open(String p) => _then(() => a.onOpen(p))();
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: _all
            ? AllProgramsSheet(
                actions: a,
                onBack: () => setState(() => _all = false),
                onProgram: open,
                onAddRemove: _then(a.onAddRemove),
              )
            : StartMenuSheet(
                actions: a,
                onProgram: open,
                onAllPrograms: () => setState(() => _all = true),
                onDesktop: _then(a.onDesktop),
                onDetails: _then(a.onDetails),
                onControlPanel: _then(a.onControlPanel),
                onAddRemove: _then(a.onAddRemove),
                onDevice: _then(a.onDevice),
                onTurnOff: _then(a.onTurnOff),
                onRestart: _then(a.onRestart),
              ),
      ),
    );
  }
}

/// `StartMenuSheet` (§8, design 2026-11-26.6): bảng `panel` bo trên 20 đệm 10 12 20, tay nắm. Đầu: ô 44 bo 10 nền
/// `skillAgentTint` + Clawd, "glimmer" 16/700, `startSubtitle` 11 muted. Lưới 2 cột cách 8: trái `panel2` bo 14 —
/// Claude, Codex đậm; kẻ; Thời tiết, Ảnh, Đồng hồ; phải `bg` bo 14 — Desktop, Số liệu; kẻ; Bảng điều khiển → Cài đặt,
/// Thêm / gỡ → Skill, Thiết bị. Hàng `startAllPrograms`. Chân: Tắt màn (amber), Khởi động lại (coral), cao 44.
class StartMenuSheet extends StatelessWidget {
  const StartMenuSheet({
    super.key,
    required this.actions,
    required this.onProgram,
    required this.onAllPrograms,
    required this.onDesktop,
    required this.onDetails,
    required this.onControlPanel,
    required this.onAddRemove,
    required this.onDevice,
    required this.onTurnOff,
    required this.onRestart,
  });

  final StartActions actions;
  final ValueChanged<String> onProgram;
  final VoidCallback onAllPrograms, onDesktop, onDetails, onControlPanel, onAddRemove, onDevice, onTurnOff, onRestart;

  static const _pad = EdgeInsets.fromLTRB(AppSpace.m, 10, AppSpace.m, AppSpace.xl);
  static const _badge = 44.0, _badgeRadius = 10.0, _clawd = 28.0;
  static const _titleSize = 16.0, _subSize = 11.0, _icon = 20.0;
  static const _pinned = ['Claude', 'Codex'];
  static const _often = ['Weather', 'Photo', 'Clock'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final installed = {for (final g in actions.programs.values) ...g};
    final pinned = [
      for (final p in _pinned)
        if (installed.contains(p)) p,
    ];
    final often = [
      for (final p in _often)
        if (installed.contains(p)) p,
    ];
    StartRow program(String p, {String? sub, bool bold = false}) => StartRow(
      icon: ProgramStyle.icon(p, size: _icon),
      title: ProgramStyle.name(l, p),
      sub: sub,
      bold: bold,
      onTap: actions.programsEnabled ? () => onProgram(p) : null,
    );
    return Padding(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.s, AppSpace.xs, AppSpace.s, AppSpace.m),
            child: Row(
              children: [
                Container(
                  width: _badge,
                  height: _badge,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.skillAgentTint,
                    borderRadius: BorderRadius.circular(_badgeRadius),
                  ),
                  child: const Clawd(size: _clawd, color: AppColors.clawd),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'glimmer',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: _titleSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(l.startSubtitle, style: AppFonts.label.copyWith(fontSize: _subSize, letterSpacing: 0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StartColumn(
                    color: AppColors.panel2,
                    children: [
                      for (final p in pinned)
                        program(p, sub: p == 'Claude' ? l.startClaudeSub : l.startCodexSub, bold: true),
                      if (pinned.isNotEmpty && often.isNotEmpty) const StartRule(),
                      for (final p in often) program(p),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: StartColumn(
                    color: AppColors.bg,
                    children: [
                      StartRow(
                        icon: const Icon(Icons.desktop_windows_outlined, size: _icon, color: AppColors.inkDim),
                        title: l.startDesktop,
                        onTap: actions.programsEnabled ? onDesktop : null,
                      ),
                      StartRow(
                        icon: const Icon(Icons.bar_chart, size: _icon, color: AppColors.inkDim),
                        title: l.startDetails,
                        onTap: onDetails,
                      ),
                      const StartRule(),
                      StartRow(
                        icon: const Icon(Icons.tune, size: _icon, color: AppColors.inkDim),
                        title: l.startControlPanel,
                        sub: l.startControlPanelSub,
                        onTap: onControlPanel,
                      ),
                      StartRow(
                        icon: const Icon(Icons.add, size: _icon, color: AppColors.clawd),
                        title: l.startAddRemove,
                        sub: l.startAddRemoveSub,
                        onTap: onAddRemove,
                      ),
                      StartRow(
                        icon: const Icon(Icons.memory, size: _icon, color: AppColors.inkDim),
                        title: l.startDevice,
                        sub: l.startDeviceSub,
                        onTap: onDevice,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s),
          StartColumn(
            color: AppColors.panel2,
            vertical: 2,
            children: [
              StartRow(
                icon: const Icon(Icons.apps, size: _icon, color: AppColors.mint),
                title: l.startAllPrograms,
                bold: true,
                trailing: const Icon(Icons.chevron_right, size: _icon, color: AppColors.mint),
                onTap: onAllPrograms,
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpace.xs,
              children: [
                StartFootButton(
                  icon: Icons.power_settings_new,
                  label: l.startTurnOff,
                  color: AppColors.amber,
                  onTap: onTurnOff,
                ),
                StartFootButton(icon: Icons.replay, label: l.startRestart, color: AppColors.coral, onTap: onRestart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
