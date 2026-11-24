import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Group title (MÀN HÌNH, BAN ĐÊM…) in `clawd`.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title});

  final String title;

  /// Gap under the title (design: 6).
  static const _under = 6.0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, _under),
        child: Text(title, style: AppFonts.label.copyWith(color: AppColors.clawd)),
      );
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({super.key, required this.title, this.sub, required this.value, required this.onChanged});

  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(title),
        subtitle: sub == null ? null : Text(sub!, style: AppFonts.label),
        value: value,
        onChanged: onChanged,
      );
}

class SettingsChoice extends StatelessWidget {
  const SettingsChoice({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final int value;
  final Map<int, String> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title),
        trailing: DropdownButton<int>(
          value: options.containsKey(value) ? value : null,
          items: [for (final e in options.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
}

/// "Độ sáng: 60%" with a 5-step slider.
class SettingsSlider extends StatelessWidget {
  const SettingsSlider({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max);
    return ListTile(
      title: Text(AppLocalizations.of(context).devSliderValue(title, v)),
      subtitle: Slider(
        value: v.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: (max - min) ~/ 5,
        onChanged: (x) => onChanged(x.round()),
      ),
    );
  }
}

/// Row with a sub line and a trailing icon that opens an editor.
class SettingsEditTile extends StatelessWidget {
  const SettingsEditTile({super.key, required this.title, required this.sub, required this.onTap, this.icon = Icons.edit});

  final String title, sub;
  final VoidCallback onTap;
  final IconData icon;

  /// Trailing icon (design: 18).
  static const _icon = 18.0;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title),
        subtitle: Text(sub, style: AppFonts.label),
        trailing: Icon(icon, size: _icon),
        onTap: onTap,
      );
}

/// Text-entry dialog; returns the trimmed text (or as typed with [trim] false), null when cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String? hint,
  String initial = '',
  bool obscure = false,
  int? maxLength,
  bool cancel = true,
  bool autofocus = true,
  bool trim = true,
  String? okLabel,
}) {
  final l = AppLocalizations.of(context);
  final t = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (hint != null) ...[Text(hint, style: AppFonts.label), const SizedBox(height: AppSpace.m)],
        TextField(controller: t, obscureText: obscure, autofocus: autofocus, maxLength: maxLength),
      ]),
      actions: [
        if (cancel) TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, trim ? t.text.trim() : t.text),
          child: Text(okLabel ?? l.commonSet),
        ),
      ],
    ),
  );
}
