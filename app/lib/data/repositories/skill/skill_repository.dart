import 'package:flutter/foundation.dart';

/// Skill đang dùng, lưu trên máy (R-SK-1). Đổi skill cùng thiết bị: `SwitchSkillUseCase`.
abstract class SkillRepository extends ChangeNotifier {
  /// Id skill đang dùng (luôn hợp lệ — không còn trong danh mục thì là mặc định).
  String get active;

  void setActive(String id);
}
