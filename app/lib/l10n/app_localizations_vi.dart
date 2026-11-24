// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get navDashboard => 'Tổng quan';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get navDevice => 'Thiết bị';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonSet => 'Đặt';

  @override
  String get commonSave => 'Lưu';

  @override
  String commonAgo(String time) {
    return '$time trước';
  }

  @override
  String get connectSearchingTitle => 'Đang tìm thiết bị…';

  @override
  String get connectSearchingBody =>
      'Tìm glimmer trên mạng Wi-Fi của điện thoại.';

  @override
  String get connectIdleTitle => 'Chưa kết nối';

  @override
  String get connectIdleBody =>
      'Điện thoại cần ở cùng mạng Wi-Fi với thiết bị.';

  @override
  String get connectNotFound => 'Không tìm thấy thiết bị trên mạng này.';

  @override
  String connectNoDeviceAt(String url) {
    return 'Không có thiết bị glimmer ở $url.';
  }

  @override
  String get connectRetry => 'Tìm lại';

  @override
  String get connectManual => 'Nhập địa chỉ IP';

  @override
  String get connectNewDevice => 'Thiết bị mới / đang hiện glimmer-setup';

  @override
  String get connectManualTitle => 'Nhập địa chỉ thiết bị';

  @override
  String get connectManualHint =>
      'IP hiện trên kênh Thông tin của thiết bị, ví dụ 192.168.1.50.';

  @override
  String get connectManualIp => 'Địa chỉ IP';

  @override
  String get connectManualToken => 'API token (nếu có)';

  @override
  String get connectManualOk => 'Kết nối';

  @override
  String dashboardSetupMode(String ip) {
    return 'chế độ cài đặt · $ip';
  }

  @override
  String get dashboardSetupNote =>
      'Thiết bị đang ở chế độ cài đặt Wi-Fi (glimmer-setup). Vào tab Thiết bị → Wi-Fi.';

  @override
  String get dashboardUsageTitle => 'MỨC DÙNG CLAUDE';

  @override
  String get dashboardUsageNoKey => 'chưa có khóa Claude — thêm trong Cài đặt';

  @override
  String get dashboardUsageKeyBad => 'khóa Claude lỗi — cập nhật trong Cài đặt';

  @override
  String get dashboardUsageBlocked =>
      'claude.ai đang chặn thiết bị — tự thử lại';

  @override
  String dashboardUsageStale(String time) {
    return 'số liệu cũ ($time trước)';
  }

  @override
  String get dashboardWeek => 'Tuần';

  @override
  String get dashboardSession => 'Phiên 5 giờ';

  @override
  String dashboardResetIn(String time) {
    return 'đặt lại sau $time';
  }

  @override
  String get dashboardProjects => 'PROJECT';

  @override
  String get dashboardProjectsClear => 'Xóa bảng';

  @override
  String get dashboardProjectsEmpty =>
      'Chưa có hoạt động. Hook của Claude Code sẽ gửi trạng thái lên đây.';

  @override
  String get dashboardCards => 'THẺ TRÊN MÀN HÌNH';

  @override
  String get dashboardCardsClearAll => 'Xóa hết';

  @override
  String get dashboardRefreshNow => 'Tải số liệu ngay';

  @override
  String get dashboardShowClaude => 'Hiện màn Claude';

  @override
  String get dashboardDoneProjectsCleared => 'Đã xóa bảng project';

  @override
  String get dashboardDoneCardCleared => 'Đã xóa thẻ';

  @override
  String get dashboardDoneCardsCleared => 'Đã xóa mọi thẻ';

  @override
  String get dashboardDoneRefresh => 'Thiết bị đang tải số liệu mới';

  @override
  String get dashboardDoneShowClaude => 'Đã chuyển sang màn Claude';

  @override
  String get stateApproval => 'Cần duyệt';

  @override
  String get stateInput => 'Chờ bạn';

  @override
  String get stateError => 'Lỗi';

  @override
  String get stateWorking => 'Đang chạy';

  @override
  String get stateDone => 'Xong';

  @override
  String get cardProgress => 'Tiến độ';

  @override
  String get cardWarning => 'Cảnh báo';

  @override
  String get cardInfo => 'Thông tin';

  @override
  String get settingsSectionDisplay => 'MÀN HÌNH';

  @override
  String get settingsBrightness => 'Độ sáng';

  @override
  String get settingsIdleDim => 'Tự giảm sáng khi rảnh';

  @override
  String get settingsIdleDimSub => '15 phút không có hoạt động agent → 15%';

  @override
  String get settingsWeeklyHero => 'Số lớn là mức dùng tuần';

  @override
  String get settingsWeeklyHeroSub => 'tắt: số lớn là phiên 5 giờ';

  @override
  String get settingsClock24h => 'Đồng hồ 24 giờ';

  @override
  String get settingsSectionNight => 'BAN ĐÊM';

  @override
  String get settingsNightMode => 'Chế độ';

  @override
  String get settingsNightNone => 'Không';

  @override
  String get settingsNightDim => 'Giảm sáng';

  @override
  String get settingsNightClock => 'Đồng hồ';

  @override
  String get settingsNightOff => 'Tắt màn';

  @override
  String get settingsNightFrom => 'Từ';

  @override
  String get settingsNightTo => 'Đến';

  @override
  String get settingsNightBright => 'Độ sáng ban đêm';

  @override
  String get settingsSectionClaude => 'SỐ LIỆU CLAUDE';

  @override
  String get settingsClaudeKey => 'Khóa Claude (sessionKey)';

  @override
  String get settingsClaudeKeyHint =>
      'Dán sessionKey của claude.ai (bắt đầu bằng sk-ant-…).';

  @override
  String get settingsRefresh => 'Tải số liệu mỗi';

  @override
  String settingsMinutes(String n) {
    return '$n phút';
  }

  @override
  String get settingsHour => '1 giờ';

  @override
  String get settingsNever => 'Không bao giờ';

  @override
  String get settingsUserName => 'Tên của bạn';

  @override
  String get settingsSectionAgent => 'AGENT';

  @override
  String get settingsShowAgents => 'Màn danh sách tác tử';

  @override
  String get settingsShowAgentsSub => 'thẻ duyệt vẫn hiện khi tắt';

  @override
  String get settingsPinApprovals => 'Giữ thẻ duyệt tới khi trả lời';

  @override
  String get settingsDoneCards => 'Thẻ \"xong\" khi agent dừng';

  @override
  String get settingsApprovalTtl => 'Bỏ thẻ chờ sau';

  @override
  String get settingsApiToken => 'API token của thiết bị';

  @override
  String get settingsApiTokenHint =>
      'Nếu đặt, hook / app phải gửi kèm token này. Để trống để bỏ.';

  @override
  String get settingsAppToken => 'Token app đang dùng';

  @override
  String get settingsAppTokenTitle => 'Token cho app';

  @override
  String get settingsSecretSet => 'đã đặt';

  @override
  String get settingsSecretUnset => 'chưa đặt';

  @override
  String get settingsSecretPending => 'sẽ đổi khi lưu';

  @override
  String get settingsNone => 'không có';

  @override
  String get settingsSaved => 'Đã lưu';

  @override
  String get settingsDiscard => 'Bỏ thay đổi';

  @override
  String settingsSaveCount(String count) {
    return 'Lưu ($count)';
  }

  @override
  String get settingsSaving => 'Đang lưu…';

  @override
  String get deviceInfo => 'THIẾT BỊ';

  @override
  String get deviceFirmware => 'Firmware';

  @override
  String get deviceBuild => 'Bản build';

  @override
  String get deviceWifi => 'Wi-Fi';

  @override
  String get deviceIp => 'IP';

  @override
  String get deviceUptime => 'Đã chạy';

  @override
  String get deviceHeap => 'Bộ nhớ trống';

  @override
  String deviceHeapValue(String free, String block) {
    return '$free KB (khối lớn nhất $block KB)';
  }

  @override
  String get deviceSetupMode => 'chế độ cài đặt';

  @override
  String get deviceChangeWifi => 'Đổi Wi-Fi cho thiết bị';

  @override
  String get deviceChangeWifiSub => 'Khi chuyển nhà / nơi làm';

  @override
  String get deviceReboot => 'Khởi động lại';

  @override
  String get deviceRebootBody =>
      'Thiết bị sẽ tắt màn hình vài giây rồi bật lại.';

  @override
  String get deviceForget => 'Kết nối thiết bị khác';

  @override
  String get deviceUpdates => 'CẬP NHẬT';

  @override
  String get deviceChecking => 'Đang kiểm tra bản mới…';

  @override
  String deviceLatest(String date) {
    return 'Bản mới nhất: $date';
  }

  @override
  String get deviceNewer => 'Có bản mới hơn thiết bị.';

  @override
  String get deviceUpToDate => 'Thiết bị có vẻ đã cập nhật.';

  @override
  String get deviceUpdateFw => 'Cập nhật firmware';

  @override
  String get deviceUpdateFwSub => 'Giữ nguyên cấu hình và lịch sử';

  @override
  String deviceUpdateFwBody(String repo) {
    return 'Tải firmware mới nhất từ $repo và nạp qua Wi-Fi. Cấu hình được giữ nguyên.';
  }

  @override
  String get deviceUpdate => 'Cập nhật';

  @override
  String get deviceUpdateFull => 'Cập nhật đầy đủ';

  @override
  String get deviceUpdateFullSub =>
      'Kèm font + giao diện web; tự sao lưu và khôi phục cấu hình';

  @override
  String get deviceUpdateFullBody =>
      'Nạp firmware và hệ thống tệp (font, giao diện web). Ứng dụng sẽ sao lưu cấu hình, nạp, rồi tự khôi phục qua Wi-Fi glimmer-setup (Android sẽ hỏi xác nhận). Lịch sử mức dùng 7 ngày bị xóa.';

  @override
  String get deviceStart => 'Bắt đầu';

  @override
  String get deviceBackup => 'Sao lưu cấu hình';

  @override
  String get deviceBackupSub => 'Có mật khẩu Wi-Fi và khóa — giữ kín';

  @override
  String get deviceBackupBody =>
      'Tệp chứa mật khẩu Wi-Fi và khóa Claude ở dạng chữ thường. Chỉ lưu ở nơi an toàn.';

  @override
  String get deviceRestore => 'Khôi phục cấu hình';

  @override
  String deviceRestoreBody(String file) {
    return 'Thay toàn bộ cấu hình thiết bị bằng tệp \"$file\"? Thiết bị sẽ khởi động lại.';
  }

  @override
  String get deviceRestoreOk => 'Khôi phục';

  @override
  String get deviceBusyNote => 'Đừng tắt ứng dụng hay rút điện thiết bị.';

  @override
  String get deviceStepFlashFw => 'Nạp firmware…';

  @override
  String get deviceStepFlashFs => 'Nạp hệ thống tệp…';

  @override
  String deviceStepDownload(String name) {
    return 'Tải $name…';
  }

  @override
  String get deviceStepRebooting => 'Thiết bị đang khởi động lại…';

  @override
  String get deviceStepBackup => 'Sao lưu cấu hình…';

  @override
  String get deviceStepSendConfig => 'Gửi cấu hình…';

  @override
  String get wifiTitle => 'Cài Wi-Fi cho thiết bị';

  @override
  String get wifiNote =>
      'Thiết bị chỉ nhớ một mạng, chỉ dùng Wi-Fi 2,4 GHz và không vào được mạng phải đăng nhập qua trang web (khách sạn, sân bay). Khi đó hãy dùng hotspot điện thoại.';

  @override
  String get wifiSsid => 'Tên Wi-Fi (SSID)';

  @override
  String get wifiPass => 'Mật khẩu (để trống nếu mạng mở)';

  @override
  String get wifiSend => 'Gửi cho thiết bị';

  @override
  String get wifiStepDirect => 'Gửi Wi-Fi mới cho thiết bị…';

  @override
  String get wifiStepJoinAp => 'Đang vào Wi-Fi glimmer-setup…';

  @override
  String get wifiStepJoinApDetail =>
      'Thiết bị phải đang hiện KẾT NỐI WI-FI · glimmer-setup (khoảng 1 phút sau khi cắm điện). Android sẽ hỏi bạn xác nhận kết nối.';

  @override
  String wifiStepSend(String ssid) {
    return 'Gửi \"$ssid\" cho thiết bị…';
  }

  @override
  String wifiStepWait(String ssid) {
    return 'Chờ thiết bị vào \"$ssid\"…';
  }

  @override
  String get wifiStepWaitDetail =>
      'Có thể mất tới 4 phút. Điện thoại cần ở cùng mạng này.';

  @override
  String wifiDone(String ssid) {
    return 'Xong! Thiết bị đã vào \"$ssid\".';
  }

  @override
  String wifiDoneDetail(String ip) {
    return 'IP $ip';
  }

  @override
  String get wifiDoneButton => 'Xong';

  @override
  String get wifiFailed => 'Chưa xong';

  @override
  String wifiNotFound(String ssid) {
    return 'Chưa thấy thiết bị trên \"$ssid\". Sai mật khẩu, mạng chỉ có 5 GHz, hoặc mạng phải đăng nhập web — khi đó thiết bị sẽ lại hiện glimmer-setup.';
  }

  @override
  String get devErrUnauthorized => 'Thiết bị yêu cầu API token.';

  @override
  String devErrHttp(int status) {
    return 'Lỗi HTTP $status';
  }

  @override
  String devErrUnreachable(String error) {
    return 'Không kết nối được thiết bị ($error)';
  }

  @override
  String devErrFlashFailed(String detail) {
    return 'Nạp thất bại: $detail';
  }

  @override
  String get devErrRateLimited =>
      'GitHub đang giới hạn lượt gọi, thử lại sau ít phút.';

  @override
  String devErrReleaseHttp(int status) {
    return 'Không đọc được bản phát hành (HTTP $status).';
  }

  @override
  String devErrDownload(int status) {
    return 'Tải thất bại (HTTP $status).';
  }

  @override
  String devErrNoAsset(String name) {
    return 'bản phát hành không có $name';
  }

  @override
  String get devErrWifiPermission =>
      'Cần quyền vị trí / thiết bị Wi-Fi lân cận để vào glimmer-setup.';

  @override
  String get devErrSetupAp =>
      'Không vào được glimmer-setup. Thiết bị có đang hiện màn cài đặt Wi-Fi không?';

  @override
  String get devErrNoAnswerAfterFlash =>
      'thiết bị không trả lời sau khi nạp firmware';

  @override
  String get devErrConfigUnreadable => 'không đọc được cấu hình để sao lưu';

  @override
  String get devErrInvalidBackup =>
      'Tệp không hợp lệ: không phải tệp cấu hình glimmer';

  @override
  String get devCardsNeedToken =>
      'Thiết bị có API token — nhập token trong Cài đặt để xem thẻ.';

  @override
  String get devNow => 'ngay';

  @override
  String devSliderValue(String title, int value) {
    return '$title: $value%';
  }

  @override
  String devWifiRssi(String ssid, int rssi) {
    return '$ssid ($rssi dBm)';
  }

  @override
  String get devBackupShareText => 'Cấu hình glimmer';

  @override
  String devBackupFailed(String error) {
    return 'Sao lưu lỗi: $error';
  }

  @override
  String get devStepJoinApRestore => 'Vào Wi-Fi glimmer-setup để khôi phục…';

  @override
  String get devStepWaitReboot => 'Chờ thiết bị khởi động lại…';

  @override
  String get devStepToSetupAp => 'Thiết bị chuyển sang glimmer-setup…';

  @override
  String get devStepRebootingShort => 'Đang khởi động lại…';

  @override
  String get devRestoreDone => 'Đã khôi phục cấu hình';

  @override
  String get devRestoreSentNotFound =>
      'Đã gửi cấu hình; chưa thấy thiết bị trên mạng';

  @override
  String devRestoreFailed(String error) {
    return 'Khôi phục lỗi: $error';
  }

  @override
  String devRestoreLater(String path) {
    return 'Chưa khôi phục được. Bản sao lưu: $path';
  }

  @override
  String get devUpdateNoAnswer => 'Đã nạp; chưa thấy thiết bị trả lời';

  @override
  String devUpdateDone(String fw) {
    return 'Xong — firmware $fw';
  }

  @override
  String devUpdateFailed(String error) {
    return 'Cập nhật lỗi: $error';
  }

  @override
  String get devErrSkillUnsupported =>
      'Thiết bị chưa hỗ trợ skill này — cập nhật firmware.';

  @override
  String get navSkills => 'Skill';

  @override
  String get skillAgentName => 'Agent';

  @override
  String get skillAgentDesc =>
      'Claude Code & Codex: mức dùng, project, thẻ duyệt.';

  @override
  String get skillAgentChannels =>
      'Trang chủ · Danh sách agent · Claude · Codex · AI · Xu hướng';

  @override
  String get skillMusicName => 'Nhạc';

  @override
  String get skillMusicDesc => 'Bài đang phát và điều khiển nhạc.';

  @override
  String get skillSocialName => 'Mạng xã hội';

  @override
  String get skillSocialDesc => 'Thông báo và số liệu mạng xã hội.';

  @override
  String get skillFunName => 'Giải trí';

  @override
  String get skillFunDesc => 'Nội dung vui cho màn hình.';

  @override
  String get skillsTitle => 'Skill';

  @override
  String get skillsSubtitle =>
      'Chọn gói chức năng cho màn hình glimmer. Mỗi lúc một skill.';

  @override
  String get skillsCurrent => 'Đang dùng';

  @override
  String skillsCurrentA11y(String skill) {
    return '$skill — đang dùng, mở màn chính';
  }

  @override
  String get skillsSoon => 'Sắp có';

  @override
  String get skillsUse => 'Dùng skill này';

  @override
  String get skillsSwitching => 'Đang đổi…';

  @override
  String skillsSwitchingBanner(String skill) {
    return 'Đang chuyển màn thiết bị sang $skill…';
  }

  @override
  String get skillsSwitchingHint => 'Chờ thiết bị nhận, vài giây.';

  @override
  String get skillsErrorTitle => 'Chưa đổi được skill';

  @override
  String skillsErrorBody(String skill) {
    return 'Thiết bị không trả lời. Màn thiết bị vẫn là $skill.';
  }

  @override
  String get skillsLegacyTitle => 'Firmware chưa hỗ trợ skill';

  @override
  String skillsLegacyBody(String fw) {
    return 'Thiết bị đang chạy $fw — chỉ có skill Agent. Cập nhật firmware để đổi skill.';
  }

  @override
  String get skillsChannelsTitle => 'MÀN THIẾT BỊ ĐANG XOAY';

  @override
  String get skillsChannelsSystem =>
      '+ luôn có: Đồng hồ · Thời tiết · Dự báo · Thông tin · Ban đêm';

  @override
  String get skillsAttentionNote =>
      'Thẻ cần duyệt / chờ trả lời của agent vẫn chen ngang ở mọi skill.';
}
