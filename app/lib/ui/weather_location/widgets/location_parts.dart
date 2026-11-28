import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Text in JetBrains Mono at [size] / [weight] / [color] (the screen's many one-off sizes, screen_specs §9).
TextStyle locText(double size, {FontWeight weight = FontWeight.w400, Color color = AppColors.ink}) =>
    AppFonts.body.copyWith(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0);

/// Ô 40 bo 12 với icon 24 (thẻ hiện tại, nút GPS).
class LocationIconBox extends StatelessWidget {
  const LocationIconBox({super.key, required this.child, this.color = AppColors.skillWeatherTint});

  final Widget child;
  final Color color;

  static const _box = 40.0, _radius = 12.0;

  @override
  Widget build(BuildContext context) => Container(
    width: _box,
    height: _box,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(_radius)),
    child: child,
  );
}

/// `LocationGpsButton` (§9): ≥ 68, bo 14, nền `skillWeatherWash`, viền 1 `skillWeather`, đệm 12 14, cách 12 — ô 40 +
/// my_location 24, `weatherLocationUseGps` 15/500 + phụ 12 muted, chevron 24 muted. [loading]: vòng xoay thay icon,
/// viền `line`, không bấm được, chữ đang lấy, không chevron.
class LocationGpsButton extends StatelessWidget {
  const LocationGpsButton({super.key, required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  static const _minH = 68.0, _radius = 14.0, _icon = 24.0, _spinner = 24.0, _stroke = 2.5;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 6),
      child: Material(
        color: AppColors.skillWeatherWash,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: loading ? AppColors.line : AppColors.skillWeather),
        ),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minH),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.m),
              child: Row(
                children: [
                  LocationIconBox(
                    child: loading
                        ? const SizedBox.square(
                            dimension: _spinner,
                            child: CircularProgressIndicator(strokeWidth: _stroke, color: AppColors.skillWeather),
                          )
                        : const Icon(Icons.my_location, size: _icon, color: AppColors.skillWeather),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loading ? l.weatherLocationGpsLoading : l.weatherLocationUseGps,
                          style: locText(15, weight: FontWeight.w500),
                        ),
                        Text(
                          loading ? l.weatherLocationGpsLoadingSub : l.weatherLocationUseGpsSub,
                          style: locText(12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (!loading) const Icon(Icons.chevron_right, size: _icon, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thanh báo (§9): `panel2`, bo 14, đệm 14 16 — tiêu đề 14/700 [color] + thân 13 inkDim + nút căn phải ([outlined] =
/// nút viền, không = nút chữ).
class LocationBanner extends StatelessWidget {
  const LocationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.color,
    this.action,
    this.onAction,
    this.outlined = true,
    this.margin = const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, 6),
  });

  final String title, body;
  final Color color;
  final String? action;
  final VoidCallback? onAction;
  final bool outlined;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 14),
    decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: locText(14, weight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(body, style: locText(13, color: AppColors.inkDim)),
        if (action != null)
          Align(
            alignment: Alignment.centerRight,
            child: outlined
                ? OutlinedButton(
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSize.tapMin),
                      side: const BorderSide(color: AppColors.line),
                      foregroundColor: AppColors.ink,
                    ),
                    child: Text(action!, style: locText(13, weight: FontWeight.w500)),
                  )
                : TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(minimumSize: const Size(0, AppSize.tapMin)),
                    child: Text(
                      action!,
                      style: locText(14, weight: FontWeight.w700, color: AppColors.clawd),
                    ),
                  ),
          ),
      ],
    ),
  );
}

/// `LocationSearchField` (§9): cao 52, bo 12, nền `panel`, viền 1 `line` (có chữ: `skillWeather`), icon search 22
/// inkDim, chữ 16, nút × 44 khi có chữ.
class LocationSearchField extends StatelessWidget {
  const LocationSearchField({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  static const _icon = 22.0, _size = 16.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, v, _) {
        final has = v.text.isNotEmpty;
        final border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.radiusSearchField),
          borderSide: BorderSide(color: has ? AppColors.skillWeather : AppColors.line),
        );
        return SizedBox(
          height: AppSize.searchField,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: locText(_size),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.panel,
              hintText: l.weatherLocationSearchHint,
              hintStyle: locText(_size, color: AppColors.muted),
              prefixIcon: const Icon(Icons.search, size: _icon, color: AppColors.inkDim),
              suffixIcon: has
                  ? IconButton(
                      tooltip: l.weatherLocationSearchClearA11y,
                      icon: const Icon(Icons.close, color: AppColors.inkDim),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              enabledBorder: border,
              focusedBorder: border,
              border: border,
            ),
          ),
        );
      },
    );
  }
}

/// Thông báo nhỏ `done`: nền ink, chữ bg 14/500, bo 12, đệm 14 16.
class LocationDoneNote extends StatelessWidget {
  const LocationDoneNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 14),
    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppSize.radiusSnackbar)),
    child: Text(
      text,
      style: locText(14, weight: FontWeight.w500, color: AppColors.bg),
    ),
  );
}
