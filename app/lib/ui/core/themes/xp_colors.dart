// Chép từ design/panel/tokens/panel_tokens.json (themeXP.color + color) — bảng màu màn thiết bị cho DeviceMirror.
// Giá trị `value` (hex) như các file design/panel/source/XP-*.dc.html; không dùng cho giao diện app (AppColors).
// Panel token đổi → chép lại file này.
import 'dart:ui';

/// Màu kiểu XP (Luna) của màn thiết bị (`themeXP.color`).
abstract final class XpColors {
  static const Color welcomeBand = Color(0xFF00309C);
  /// link `glimmer.local`
  static const Color link = Color(0xFF0066CC);
  static const Color titleEdge = Color(0xFF003DB5);
  static const Color groupLabel = Color(0xFF0046D5);
  static const Color frame = Color(0xFF0047D3);
  static const Color titleDark = Color(0xFF0049D6);
  static const Color title = Color(0xFF0058EE);
  static const Color flagBlue = Color(0xFF05A6F0);
  static const Color titleShadow = Color(0xFF0A246A);
  static const Color sky = Color(0xFF0A6ACF);
  static const Color tray = Color(0xFF0F8BE8);
  static const Color trayEdge = Color(0xFF1042AF);
  static const Color btnPressedEdge = Color(0xFF163E91);
  static const Color bootBlockLo = Color(0xFF1A4DB8);
  static const Color btnEdge = Color(0xFF1A50C8);
  static const Color taskDark = Color(0xFF1C4FBF);
  static const Color checkBox = Color(0xFF1C5180);
  static const Color btnPressed = Color(0xFF1E4FB5);
  static const Color startShadow = Color(0xFF1E5E1E);
  static const Color iconInfo = Color(0xFF1F6FE0);
  static const Color check = Color(0xFF21A121);
  static const Color task = Color(0xFF245EDC);
  static const Color welcomeShadow = Color(0xFF2A3F8F);
  static const Color titleLight = Color(0xFF2B80F5);
  static const Color userSel = Color(0xFF2C55C4);
  static const Color startDark = Color(0xFF2E7D2E);
  static const Color green = Color(0xFF2E8A2E);
  static const Color bootBlock = Color(0xFF2F6FE6);
  static const Color select = Color(0xFF316AC5);
  static const Color taskLight = Color(0xFF3A7DEB);
  static const Color start = Color(0xFF3A9E3A);
  static const Color bandEdge = Color(0xFF3B4FA8);
  static const Color btn = Color(0xFF3C81F3);
  static const Color bar = Color(0xFF3CC63C);
  static const Color titleHi = Color(0xFF3D95FF);
  static const Color trayHi = Color(0xFF3FA9F5);
  static const Color label = Color(0xFF4D4D4D);
  static const Color welcome = Color(0xFF5A7EDC);
  static const Color taskHi = Color(0xFF5A9BF6);
  static const Color startHi = Color(0xFF5CC15C);
  static const Color userSelHi = Color(0xFF5F84E3);
  static const Color muted = Color(0xFF6F6F6F);
  static const Color lilac = Color(0xFF7A44C8);
  static const Color dividerFade = Color(0xFF7D9BE8);
  static const Color fieldBorder = Color(0xFF7F9DB9);
  static const Color welcomeLine = Color(0xFF7FA4F0);
  static const Color flagGreen = Color(0xFF81BC06);
  static const Color bootBlockHi = Color(0xFF9BC0FA);
  static const Color bandEdgeWarm = Color(0xFF9C6A6A);
  /// chữ / số liệu mờ (dữ liệu cũ, đang tải) — màu chữ mờ của XP
  static const Color dim = Color(0xFFACA899);
  static const Color statusLine = Color(0xFFACA899);
  static const Color bootGrey = Color(0xFFB2B2B2);
  static const Color flashEdge = Color(0xFFB8661E);
  static const Color emptyIcon = Color(0xFFB8B4A0);
  static const Color divider = Color(0xFFB9CBF5);
  static const Color red = Color(0xFFC1272D);
  static const Color amber = Color(0xFFC98A00);
  static const Color welcomeSub = Color(0xFFC9D6F7);
  static const Color group = Color(0xFFD0D0BF);
  static const Color iconError = Color(0xFFD8341E);
  static const Color rowHi = Color(0xFFDCE6F8);
  static const Color close = Color(0xFFE0523C);
  static const Color rowLine = Color(0xFFE4E4E4);
  static const Color body = Color(0xFFECE9D8);
  static const Color flash = Color(0xFFF0A030);
  static const Color welcomeOrange = Color(0xFFF28F2E);
  static const Color iconWarn = Color(0xFFF2C200);
  static const Color userPic = Color(0xFFF2C27A);
  static const Color flagRed = Color(0xFFF35325);
  static const Color flagYellow = Color(0xFFFFBA08);
  static const Color infoBar = Color(0xFFFFFFE1);
  static const Color white = Color(0xFFFFFFFF);
  /// chữ thường, số to (hạn mức, chi phí), mắt Clawd
  static const Color black = Color(0xFF000000);
  /// nền dự phòng màn desktop
  static const Color desk1A55D0 = Color(0xFF1A55D0);
  /// nền dự phòng màn desktop
  static const Color desk1F5CD4 = Color(0xFF1F5CD4);
  /// nền dự phòng màn desktop
  static const Color desk2665D8 = Color(0xFF2665D8);
  /// nền dự phòng màn desktop
  static const Color desk2F6EDC = Color(0xFF2F6EDC);
  /// nền dự phòng màn desktop
  static const Color desk3A79E0 = Color(0xFF3A79E0);
  /// nền dự phòng màn desktop
  static const Color desk3C8A1E = Color(0xFF3C8A1E);
  /// nền dự phòng màn desktop
  static const Color desk3F8F20 = Color(0xFF3F8F20);
  /// nền dự phòng màn desktop
  static const Color desk4784E4 = Color(0xFF4784E4);
  /// nền dự phòng màn desktop
  static const Color desk4A9C24 = Color(0xFF4A9C24);
  /// nền dự phòng màn desktop
  static const Color desk5690E8 = Color(0xFF5690E8);
  /// nền dự phòng màn desktop
  static const Color desk5FAE2C = Color(0xFF5FAE2C);
  /// nền dự phòng màn desktop
  static const Color desk68A0EC = Color(0xFF68A0EC);
  /// nền dự phòng màn desktop
  static const Color desk76BE37 = Color(0xFF76BE37);
  /// nền dự phòng màn desktop
  static const Color desk7DB0F0 = Color(0xFF7DB0F0);
  /// nền dự phòng màn desktop
  static const Color desk7FA89A = Color(0xFF7FA89A);
  /// nền dự phòng màn desktop
  static const Color desk93C0F3 = Color(0xFF93C0F3);
  /// nền dự phòng màn desktop
  static const Color desk93CF48 = Color(0xFF93CF48);
  /// nền dự phòng màn desktop
  static const Color desk9DBDEE = Color(0xFF9DBDEE);
  /// nền dự phòng màn desktop
  static const Color deskAACFF6 = Color(0xFFAACFF6);
  /// nền dự phòng màn desktop
  static const Color deskB2DE63 = Color(0xFFB2DE63);
  /// nền dự phòng màn desktop
  static const Color deskC2D6F3 = Color(0xFFC2D6F3);
  /// nền dự phòng màn desktop
  static const Color deskDDE6EE = Color(0xFFDDE6EE);
  /// nền dự phòng màn desktop
  static const Color deskE4EDFB = Color(0xFFE4EDFB);
  /// nền dự phòng màn desktop
  static const Color deskF7F9FE = Color(0xFFF7F9FE);
}

/// Màu chung của màn thiết bị (`color`: nền tối, chữ, màu nhấn kênh).
abstract final class PanelColors {
  /// Nền mọi màn (đừng đổi: #0E0D12 lên panel thành xám xanh)
  static const Color bg = Color(0xFF000000);
  /// Ô ngày Weather, dòng hôm nay Forecast, ô tắt của pixelBar
  static const Color panel = Color(0xFF1F1A28);
  /// Rãnh thanh nhiệt Forecast
  static const Color panel2 = Color(0xFF2A2236);
  /// Viền, kẻ, chấm kẻ, chấm tải tắt
  static const Color line = Color(0xFF34293F);
  /// Chữ chính
  static const Color ink = Color(0xFFFFF8E8);
  /// Chữ phụ sáng, cột ngày cũ
  static const Color inkDim = Color(0xFFD8CDB8);
  /// Nhãn, meta, chữ phụ
  static const Color muted = Color(0xFF8A7F96);
  /// Nhấn Claude; lỗi; còn ≤ 20 %
  static const Color coral = Color(0xFFFF5247);
  /// Nhấn Clock / Home / Setup; cần duyệt; còn ≤ 50 %; dữ liệu cũ
  static const Color amber = Color(0xFFFFD23F);
  /// Nhấn Info / Trend; xong; còn > 50 % · nhấn kênh Ảnh
  static const Color mint = Color(0xFF8FE574);
  /// Nhấn Weather / Forecast; câu hỏi; glimmer.local
  static const Color sky = Color(0xFF54B6FF);
  /// Nhấn Codex; đang chạy / tiến độ
  static const Color lilac = Color(0xFFC385FF);
  /// Linh vật Clawd (Claude)
  static const Color clawd = Color(0xFFD97757);
}
