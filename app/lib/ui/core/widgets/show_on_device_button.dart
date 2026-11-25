import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_text.dart';

/// Nút cuối mỗi tab của Màn hình (components.md `ShowOnDeviceButton`): rộng hết, cao ≥ 48, bo 14, nền `panel2`,
/// icon tv 18 inkDim + 10 + chữ 14/500 ink. Đệm ngoài 8 16 24.
class ShowOnDeviceButton extends StatelessWidget {
  const ShowOnDeviceButton({super.key, required this.label, required this.onPressed});

  /// "Hiện {skill} trên thiết bị".
  final String label;
  final VoidCallback onPressed;

  static const _minHeight = 48.0;
  static const _icon = 18.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.s, AppSpace.l, AppSpace.xxl),
        child: Material(
          color: AppColors.panel2,
          borderRadius: BorderRadius.circular(AppSize.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight, minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.m),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.tv, size: _icon, color: AppColors.inkDim),
                  const SizedBox(width: _gap),
                  Flexible(
                    child: Text(label,
                        textAlign: TextAlign.center, style: AppFonts.button.copyWith(color: AppColors.ink)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
