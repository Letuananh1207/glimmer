import 'package:flutter/foundation.dart';

/// Skill đang bật, lưu trên máy (R-SK-1). Bật / tắt cùng thiết bị: `ToggleSkillUseCase`.
abstract class SkillRepository extends ChangeNotifier {
  /// Id skill bật, theo thứ tự dock (luôn ít nhất một — thiếu / rỗng thì là mặc định).
  List<String> get enabled;

  void setEnabled(List<String> ids);
}
