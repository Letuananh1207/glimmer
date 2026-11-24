import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_text.dart';

/// Thanh báo trạng thái (components.md): thẻ `panel2` đầu màn — tiêu đề màu loại, hoặc vòng xoay + chữ;
/// thân 13 inkDim; nút căn phải ([trailing]) hoặc nút viền ([action]).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.title,
    this.titleColor = AppColors.ink,
    this.body,
    this.busy = false,
    this.trailing,
    this.action,
  });

  final String title;
  final Color titleColor;
  final String? body;

  /// Spinner + plain title (14 ink), body as a label underneath.
  final bool busy;

  /// Text button at the bottom right.
  final Widget? trailing;

  /// Full-width outlined button at the bottom.
  final Widget? action;

  static const _pad = EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 14);
  static const _margin = EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 6);
  static const _spinner = 24.0;
  static const _titleSize = 14.0;
  static const _bodySize = 13.0;
  static const _bodyLine = 18 / 13;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(fontSize: _bodySize, height: _bodyLine, color: AppColors.inkDim);
    return Container(
      margin: _margin,
      padding: _pad,
      decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (busy)
          Row(children: [
            const SizedBox.square(dimension: _spinner, child: CircularProgressIndicator()),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: _titleSize, color: AppColors.ink)),
                if (body != null) ...[const SizedBox(height: 2), Text(body!, style: AppFonts.label)],
              ]),
            ),
          ])
        else ...[
          Text(title, style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.w700, color: titleColor)),
          if (body != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(body!, style: bodyStyle),
          ],
          if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
          if (action != null) ...[const SizedBox(height: AppSpace.m), action!],
        ],
      ]),
    );
  }
}
