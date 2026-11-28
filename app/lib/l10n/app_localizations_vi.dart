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
  String get connectNewDevice => 'Quét mã QR trên màn thiết bị';

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
      'Thiết bị phải đang hiện màn cài Wi-Fi có mã QR. Android sẽ hỏi bạn xác nhận kết nối.';

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
  String wifiDoneDetail(String ip, String ssid) {
    return 'IP $ip · đã nhớ mật khẩu \"$ssid\".';
  }

  @override
  String get wifiDoneButton => 'Xong';

  @override
  String get wifiFailed => 'Chưa xong';

  @override
  String wifiNotFound(String ssid) {
    return 'Chưa thấy thiết bị trên \"$ssid\". Sai mật khẩu, mạng chỉ có 5 GHz, hoặc mạng phải đăng nhập web — khi đó thiết bị sẽ lại hiện mã QR. Mật khẩu vừa gửi không được nhớ.';
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
  String get devErrNotGlimmerQr =>
      'Đây không phải mã của glimmer. Quét mã trên màn cài đặt Wi-Fi của thiết bị.';

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
  String get skillAgentDesc => 'Mức dùng và thẻ duyệt';

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
  String get skillFunDesc => 'Dò mìn, chơi bằng app';

  @override
  String get skillsTitle => 'Skill';

  @override
  String get skillsSubtitle => 'Mỗi skill bật là một chương trình trên máy.';

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
  String get skillsLegacyTitle => 'Firmware chưa có dock';

  @override
  String skillsLegacyBody(String fw) {
    return 'Thiết bị đang chạy $fw — chỉ có skill Agent, không bật / tắt được. Cập nhật firmware để dùng dock.';
  }

  @override
  String get skillsChannelsTitle => 'MÀN THIẾT BỊ ĐANG XOAY';

  @override
  String get skillsChannelsSystem =>
      '+ luôn có: Đồng hồ · Thời tiết · Dự báo · Thông tin · Ban đêm';

  @override
  String get skillsAttentionNote =>
      'Thẻ cần duyệt / chờ trả lời của agent vẫn chen ngang ở mọi skill.';

  @override
  String get navHome => 'Màn hình';

  @override
  String navHomeBadgeA11y(String count) {
    return '$count agent đang chờ';
  }

  @override
  String get homeTabsA11y => 'Tab của Màn hình';

  @override
  String homeShowOnDevice(String skill) {
    return 'Hiện $skill trên thiết bị';
  }

  @override
  String get skillWeatherName => 'Thời tiết';

  @override
  String get skillWeatherDesc => 'Hôm nay và 3 ngày tới';

  @override
  String get skillClockName => 'Đồng hồ';

  @override
  String get skillClockDesc => 'Giờ, ngày, giờ ban đêm';

  @override
  String get skillChatName => 'Tin nhắn';

  @override
  String skillsToggleA11y(String skill) {
    return 'Bật / tắt skill $skill';
  }

  @override
  String get skillsSending => 'Đang gửi thiết bị…';

  @override
  String skillsErrorOffTitle(String skill) {
    return 'Chưa tắt được $skill';
  }

  @override
  String skillsErrorOnTitle(String skill) {
    return 'Chưa bật được $skill';
  }

  @override
  String skillsErrorOffBody(String skill) {
    return 'Thiết bị không trả lời. $skill vẫn bật trên thiết bị.';
  }

  @override
  String skillsErrorOnBody(String skill) {
    return 'Thiết bị không trả lời. $skill vẫn tắt trên thiết bị.';
  }

  @override
  String get skillsLastOne => 'Cần ít nhất một skill bật';

  @override
  String get skillsAlwaysOn => 'Luôn có (firmware cũ)';

  @override
  String get skillsOrderNote =>
      'Mỗi skill bật thêm chương trình vào desktop và Start của thiết bị. Thẻ cần duyệt vẫn chen ngang mọi màn.';

  @override
  String get skillsSoonTitle => 'SẮP CÓ';

  @override
  String get weatherTitle => 'THỜI TIẾT';

  @override
  String weatherMeta(String place, String age) {
    return '$place · $age trước';
  }

  @override
  String weatherHiLo(String hi, String lo) {
    return 'cao $hi° · thấp $lo°';
  }

  @override
  String weatherFeels(String t) {
    return 'cảm giác $t°';
  }

  @override
  String get weatherDayTomorrow => 'MAI';

  @override
  String get weatherDayAfter => 'KIA';

  @override
  String get weatherNoLocationMeta => 'chưa có vị trí';

  @override
  String get weatherNoLocationTitle => 'Chưa đặt vị trí';

  @override
  String get weatherNoLocationBody =>
      'Thiết bị cần vĩ độ / kinh độ để lấy thời tiết và dự báo.';

  @override
  String get weatherSetLocation => 'Đặt vị trí thời tiết';

  @override
  String get clockTitle => 'ĐỒNG HỒ';

  @override
  String clockDate(String weekday, String date, String week) {
    return '$weekday $date · tuần $week';
  }

  @override
  String get clockTz => 'Múi giờ';

  @override
  String get clockFormat => 'Kiểu giờ';

  @override
  String get clockFormat24 => '24 giờ';

  @override
  String get clockFormat12 => '12 giờ';

  @override
  String get clockNight => 'Ban đêm';

  @override
  String clockNightValue(String start, String end, String mode) {
    return '$start – $end · $mode';
  }

  @override
  String devWeekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'T2',
      '2': 'T3',
      '3': 'T4',
      '4': 'T5',
      '5': 'T6',
      '6': 'T7',
      'other': 'CN',
    });
    return '$_temp0';
  }

  @override
  String devWeekdayLong(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'THỨ HAI',
      '2': 'THỨ BA',
      '3': 'THỨ TƯ',
      '4': 'THỨ NĂM',
      '5': 'THỨ SÁU',
      '6': 'THỨ BẢY',
      'other': 'CHỦ NHẬT',
    });
    return '$_temp0';
  }

  @override
  String get devClockNightDim => 'làm tối';

  @override
  String get devClockNightClock => 'chỉ đồng hồ';

  @override
  String get devClockNightOff => 'tắt màn';

  @override
  String get devClockAm => 'SA';

  @override
  String get devClockPm => 'CH';

  @override
  String get devWeatherNoData => 'chưa có số liệu';

  @override
  String devShowOnDeviceDone(String skill) {
    return 'Đã chuyển sang màn $skill';
  }

  @override
  String get skillPhotoName => 'Ảnh';

  @override
  String get skillPhotoDesc => 'Ảnh của bạn, gửi từ điện thoại';

  @override
  String skillsPhotoHint(int count) {
    return '$count ảnh đã có trên thiết bị. Bật để xoay.';
  }

  @override
  String get skillsNeedFirmware => 'Cần firmware mới';

  @override
  String get skillsUpdateFirmware => 'Cập nhật';

  @override
  String get photoOnDevice => 'ẢNH TRÊN THIẾT BỊ';

  @override
  String photoCount(int count, int max, int free) {
    return '$count/$max · còn $free chỗ';
  }

  @override
  String photoCountFull(int max) {
    return '$max/$max · hết chỗ';
  }

  @override
  String photoCountEmpty(int max) {
    return '0/$max';
  }

  @override
  String get photoAdd => 'Thêm ảnh';

  @override
  String photoFullTile(int max) {
    return 'Đủ $max ảnh';
  }

  @override
  String photoFullBody(int max) {
    return 'Thiết bị giữ tối đa $max ảnh. Xoá bớt một ảnh để thêm ảnh mới.';
  }

  @override
  String photoTileA11y(int index) {
    return 'Ảnh $index, bấm để xoá';
  }

  @override
  String photoUnknownA11y(String name) {
    return 'Ảnh $name, gửi từ nơi khác, bấm để xoá';
  }

  @override
  String get photoNoPreview => 'không có bản xem';

  @override
  String get photoNote =>
      'Bấm vào ảnh để xoá. Cập nhật đầy đủ ở tab Thiết bị sẽ xoá hết ảnh trên thiết bị.';

  @override
  String get photoEmptyTitle => 'Chưa có ảnh';

  @override
  String photoEmptyBody(int max) {
    return 'Chọn ảnh trong máy, cắt vuông rồi gửi lên. Thiết bị xoay từng ảnh, tối đa $max ảnh.';
  }

  @override
  String get photoAddHint => 'Ảnh sẽ được cắt vuông 188 × 188 trước khi gửi.';

  @override
  String get photoFromGallery => 'Chọn trong thư viện';

  @override
  String get photoFromCamera => 'Chụp ảnh';

  @override
  String get photoDeleteTitle => 'Xoá ảnh này?';

  @override
  String get photoDeleteBody => 'Ảnh bị xoá khỏi thiết bị, không lấy lại được.';

  @override
  String get photoDelete => 'Xoá';

  @override
  String get photoDeleting => 'Đang xoá';

  @override
  String get photoDeleteErrorTitle => 'Chưa xoá được ảnh';

  @override
  String get photoDeleteErrorBody =>
      'Thiết bị không trả lời. Ảnh vẫn còn trên thiết bị.';

  @override
  String get photoCropTitle => 'Cắt ảnh';

  @override
  String get photoCropAreaA11y => 'Vùng cắt, kéo để dời, chụm để phóng';

  @override
  String get photoCropHint => 'Kéo để dời · chụm hai ngón để phóng';

  @override
  String get photoCropPreview => 'XEM TRƯỚC TRÊN THIẾT BỊ';

  @override
  String get photoCropPreviewBody =>
      'Ảnh 188 × 188, đúng như màn thiết bị hiện.';

  @override
  String get photoCropPreviewNote =>
      'App tự thu nhỏ và nén dưới 40 KB trước khi gửi.';

  @override
  String get photoCropPickOther => 'Chọn ảnh khác';

  @override
  String get photoCropSend => 'Gửi ảnh';

  @override
  String get photoCropSending => 'Đang gửi ảnh…';

  @override
  String get photoCropKeepOpen => 'Giữ app mở tới khi xong.';

  @override
  String get photoCropDoneTitle => 'Đã gửi lên thiết bị';

  @override
  String photoCropDoneBody(int count, int max) {
    return 'Ảnh $count/$max. Thiết bị hiện ảnh này ở lượt xoay tới.';
  }

  @override
  String get photoCropAddAnother => 'Thêm ảnh khác';

  @override
  String get photoCropDone => 'Xong';

  @override
  String get photoCropBackToList => 'Về danh sách ảnh';

  @override
  String get photoCropRecrop => 'Cắt lại';

  @override
  String photoCropErrorFullTitle(int max) {
    return 'Thiết bị đã đủ $max ảnh';
  }

  @override
  String get photoCropErrorFullBody =>
      'Xoá bớt một ảnh rồi gửi lại. Vùng cắt này được giữ.';

  @override
  String get photoCropErrorTooBigTitle => 'Ảnh vẫn quá lớn';

  @override
  String get photoCropErrorTooBigBody =>
      'Đã giảm chất lượng mà ảnh vẫn trên 40 KB. Chọn vùng ít chi tiết hơn, hoặc ảnh khác.';

  @override
  String get photoCropErrorNoSpaceTitle => 'Thiết bị hết chỗ lưu';

  @override
  String get photoCropErrorNoSpaceBody =>
      'Bộ nhớ thiết bị gần đầy. Xoá bớt ảnh rồi thử lại.';

  @override
  String get photoCropErrorRejectedTitle => 'Thiết bị không nhận ảnh';

  @override
  String get photoCropErrorRejectedBody =>
      'Ảnh app tạo ra bị lỗi. Thử lại; nếu vẫn lỗi, hãy báo lỗi app.';

  @override
  String get photoCropErrorOfflineTitle => 'Mất kết nối với thiết bị';

  @override
  String get photoCropErrorOfflineBody =>
      'Kiểm tra thiết bị còn bật và cùng mạng Wi-Fi với điện thoại.';

  @override
  String get devPhotoUnreadableTitle => 'Không mở được ảnh này';

  @override
  String get devPhotoUnreadableBody => 'Chọn ảnh khác (JPEG, PNG hoặc HEIC).';

  @override
  String get devPhotoLoadErrorTitle => 'Chưa tải được danh sách ảnh';

  @override
  String get navControl => 'Điều khiển';

  @override
  String get controlRefreshA11y => 'Làm mới số liệu';

  @override
  String controlScreenA11y(String app) {
    return 'Màn thiết bị đang hiện $app. Chạm như chuột: nút cửa sổ, thanh tác vụ, start, biểu tượng';
  }

  @override
  String controlNextIn(int seconds) {
    return '· đổi kênh sau $seconds s';
  }

  @override
  String get controlJustSwitched => '· vừa chuyển';

  @override
  String get controlPausedNote => '· đã dừng xoay, giữ kênh này';

  @override
  String get controlScreenOffTitle => 'Màn đang tắt';

  @override
  String get controlScreenOffNote => '· bấm Bật màn để mở lại';

  @override
  String get controlScreenOffOverlay => 'MÀN ĐANG TẮT';

  @override
  String get controlNightTitle => 'Chế độ đêm';

  @override
  String controlNightNote(String time) {
    return '· tới $time, không xoay kênh';
  }

  @override
  String get controlPrev => 'Kênh trước';

  @override
  String get controlNext => 'Kênh sau';

  @override
  String get controlPause => 'Dừng xoay';

  @override
  String get controlResume => 'Tiếp tục xoay';

  @override
  String get controlJumpGroupA11y => 'Nhảy tới tab';

  @override
  String controlJumpA11y(String skill) {
    return 'Hiện $skill trên thiết bị';
  }

  @override
  String get controlBrightness => 'Độ sáng';

  @override
  String get controlScreenOff => 'Tắt màn';

  @override
  String get controlScreenOn => 'Bật màn';

  @override
  String get controlNight => 'Chế độ đêm';

  @override
  String get controlDetails => 'Số liệu';

  @override
  String get controlSending => 'Đang gửi…';

  @override
  String controlFailed(String command) {
    return 'Thiết bị không nhận lệnh \"$command\".';
  }

  @override
  String get controlCardLabel => 'THẺ AGENT ĐANG CHIẾM MÀN';

  @override
  String controlCardBody(String agent, String project, String tool) {
    return '$agent · $project cần bạn duyệt $tool';
  }

  @override
  String controlCardBodyInput(String agent, String project) {
    return '$agent · $project đang chờ bạn trả lời';
  }

  @override
  String get controlCardNote =>
      'Duyệt trên máy tính. Bỏ thẻ chỉ gỡ nó khỏi màn thiết bị.';

  @override
  String get controlDismissCard => 'Bỏ thẻ khỏi màn';

  @override
  String controlSingleNote(String skill) {
    return 'Chỉ skill $skill đang bật — ‹ › đi qua các kênh của skill này và Thông tin.';
  }

  @override
  String get controlOldFwTitle => 'Firmware chưa có chuột';

  @override
  String controlOldFwBody(String version) {
    return 'Thiết bị đang chạy $version: chưa nhận chuột, phím và nút nguồn từ app.';
  }

  @override
  String get controlUpdateFirmware => 'Cập nhật firmware';

  @override
  String get controlSetupTitle => 'Thiết bị đang ở glimmer-setup';

  @override
  String get controlSetupBody =>
      'Thiết bị chưa vào được Wi-Fi nên chưa điều khiển được.';

  @override
  String get controlSetupAction => 'Quét mã trên màn';

  @override
  String get controlOfflineTitle => 'Không thấy thiết bị';

  @override
  String controlOfflineBody(String ip, String ago) {
    return 'Không trả lời ở $ip từ $ago trước.';
  }

  @override
  String get controlOfflineOverlay => 'Mất kết nối';

  @override
  String get controlOfflineOverlayNote => 'hình cuối cùng app nhận được';

  @override
  String get detailsTitle => 'Số liệu';

  @override
  String get detailsBackA11y => 'Về Điều khiển';

  @override
  String get devErrControlUnsupported =>
      'Firmware chưa có lệnh này — cập nhật firmware.';

  @override
  String devControlCmdOpen(String app) {
    return 'Mở $app';
  }

  @override
  String get devControlCmdDesktop => 'Desktop';

  @override
  String devControlCmdClose(String app) {
    return 'Tắt $app';
  }

  @override
  String devControlCmdMinimize(String app) {
    return 'Thu nhỏ $app';
  }

  @override
  String devXpZoneName(String index) {
    String _temp0 = intl.Intl.selectLogic(index, {
      '0': 'Los Angeles',
      '1': 'New York',
      '2': 'Brasília',
      '3': 'London',
      '4': 'Paris, Berlin',
      '5': 'Moskva',
      '6': 'Dubai',
      '7': 'New Delhi',
      '8': 'Hà Nội',
      '9': 'Singapore',
      '10': 'Tokyo, Seoul',
      'other': 'Sydney',
    });
    return '$_temp0';
  }

  @override
  String get controlOpenOnDevice => '· đang mở trên thiết bị';

  @override
  String get controlJustOpened => '· vừa chạm trên thanh tác vụ';

  @override
  String get controlDesktop => 'Desktop';

  @override
  String controlMinimizedNote(String app) {
    return '· $app đã thu nhỏ';
  }

  @override
  String controlInstalledNote(String skill) {
    return '· $skill vừa cài';
  }

  @override
  String get controlTapIconNote => '· chạm biểu tượng để mở';

  @override
  String get controlMinimizing => 'Thu nhỏ…';

  @override
  String controlClosing(String app) {
    return 'Đang tắt $app…';
  }

  @override
  String get controlOpening => 'Đang mở…';

  @override
  String controlOpeningApp(String app) {
    return 'Đang mở $app…';
  }

  @override
  String controlInstalled(String skill) {
    return 'Đã cài $skill';
  }

  @override
  String get controlLegendTitle => 'CHẠM MÀN NHƯ DÙNG CHUỘT';

  @override
  String get controlLegendMin => 'thu nhỏ';

  @override
  String get controlLegendMax => 'phóng to';

  @override
  String get controlLegendClose => 'tắt app';

  @override
  String get controlLegendTaskbar => 'nút dưới: đổi app';

  @override
  String get controlLegendStartKey => 'start';

  @override
  String get controlLegendStart => 'mở Start';

  @override
  String get controlLegendHoldKey => 'giữ';

  @override
  String get controlLegendHold => 'chuột phải';

  @override
  String get startSubtitle => 'Start · mở chương trình trên thiết bị';

  @override
  String get startA11y => 'Start';

  @override
  String get startClaudeSub => 'mức dùng, project';

  @override
  String get startCodexSub => 'mức dùng';

  @override
  String get startDesktop => 'Desktop';

  @override
  String get startDetails => 'Số liệu';

  @override
  String get startControlPanel => 'Bảng điều khiển';

  @override
  String get startControlPanelSub => 'Cài đặt';

  @override
  String get startAddRemove => 'Thêm / gỡ';

  @override
  String get startAddRemoveSub => 'chương trình · Skill';

  @override
  String get startDevice => 'Thiết bị';

  @override
  String get startDeviceSub => 'firmware, sao lưu';

  @override
  String get startAllPrograms => 'Tất cả chương trình';

  @override
  String get startTurnOff => 'Tắt màn';

  @override
  String get startRestart => 'Khởi động lại';

  @override
  String get allProgramsTitle => 'Tất cả chương trình';

  @override
  String get allProgramsBackA11y => 'Về Start';

  @override
  String get allProgramsGroupAgent => 'AGENT';

  @override
  String get allProgramsGroupOther => 'THỜI TIẾT · ĐỒNG HỒ · ẢNH';

  @override
  String get allProgramsGroupSystem => 'HỆ THỐNG';

  @override
  String get allProgramsOpenLegend => '● = đang mở';

  @override
  String get allProgramsAddRemove => 'Thêm / gỡ chương trình';

  @override
  String allProgramsAddRemoveSub(String names) {
    return 'bật skill mới: $names sắp có';
  }

  @override
  String get appClaude => 'Claude';

  @override
  String get appCodex => 'Codex';

  @override
  String get appAi => 'AI';

  @override
  String get appTrend => 'Xu hướng';

  @override
  String get appAgents => 'Agents';

  @override
  String get appPhoto => 'Ảnh';

  @override
  String get appWeather => 'Thời tiết';

  @override
  String get appForecast => 'Dự báo';

  @override
  String get appClock => 'Đồng hồ';

  @override
  String get appInfo => 'Thông tin';

  @override
  String get appChat => 'Tin nhắn';

  @override
  String get settingsSectionWeather => 'THỜI TIẾT';

  @override
  String get settingsWeatherLocation => 'Vị trí thời tiết';

  @override
  String get settingsWeatherLocationNone => 'chưa đặt';

  @override
  String get weatherLocationTitle => 'Vị trí thời tiết';

  @override
  String get weatherLocationCurrent => 'THIẾT BỊ ĐANG DÙNG';

  @override
  String weatherLocationCoords(String lat, String lon) {
    return '$lat, $lon';
  }

  @override
  String get weatherLocationRename => 'Sửa tên';

  @override
  String get weatherLocationClear => 'Xoá vị trí';

  @override
  String get weatherLocationUnsetBody =>
      'Thiết bị chưa lấy được thời tiết. Chọn một nơi bên dưới.';

  @override
  String get weatherLocationOldFwNote =>
      'Firmware này chưa hiện tên nơi — thiết bị chỉ nhận toạ độ. Cập nhật firmware để thấy tên trên màn Thời tiết và Đồng hồ.';

  @override
  String get weatherLocationUseGps => 'Dùng vị trí hiện tại';

  @override
  String get weatherLocationUseGpsSub =>
      'Chỉ lấy khi bạn bấm, rồi hỏi lại trước khi gửi.';

  @override
  String get weatherLocationGpsLoading => 'Đang lấy vị trí…';

  @override
  String get weatherLocationGpsLoadingSub =>
      'Chờ định vị của điện thoại, vài giây.';

  @override
  String get weatherLocationGpsDeniedTitle => 'Chưa cho phép vị trí';

  @override
  String get weatherLocationGpsDeniedBody =>
      'App cần quyền vị trí để lấy toạ độ của điện thoại. Hoặc tìm thành phố bên dưới.';

  @override
  String get weatherLocationOpenAppSettings => 'Mở cài đặt điện thoại';

  @override
  String get weatherLocationGpsOffTitle => 'Định vị đang tắt';

  @override
  String get weatherLocationGpsOffBody =>
      'Bật định vị (GPS) của điện thoại rồi bấm lại.';

  @override
  String get weatherLocationTurnOnGps => 'Bật định vị';

  @override
  String get weatherLocationGpsFailTitle => 'Không lấy được vị trí';

  @override
  String get weatherLocationGpsFailBody =>
      'Điện thoại chưa định vị được (trong nhà, sóng yếu). Thử lại hoặc tìm thành phố.';

  @override
  String get weatherLocationSearchSection => 'HOẶC TÌM THÀNH PHỐ';

  @override
  String get weatherLocationSearchHint => 'Tên thành phố, vd Đà Nẵng';

  @override
  String get weatherLocationSearchPrivacy =>
      'Chữ bạn gõ được gửi tới Open-Meteo để tìm (như trang web của thiết bị).';

  @override
  String get weatherLocationSearchClearA11y => 'Xoá chữ';

  @override
  String get weatherLocationSearching => 'Đang tìm…';

  @override
  String weatherLocationResultSub(String area, String lat, String lon) {
    return '$area · $lat, $lon';
  }

  @override
  String weatherLocationNoResultsTitle(String query) {
    return 'Không thấy “$query”';
  }

  @override
  String get weatherLocationNoResultsBody =>
      'Kiểm tra chính tả, hoặc thử tên không dấu / tên tiếng Anh.';

  @override
  String get weatherLocationSearchErrorTitle => 'Không tìm được';

  @override
  String get weatherLocationSearchErrorBody =>
      'Điện thoại không tới được Open-Meteo. Kiểm tra mạng rồi thử lại.';

  @override
  String get weatherLocationConfirmTitle => 'Đặt vị trí này?';

  @override
  String get weatherLocationRenameTitle => 'Sửa tên nơi';

  @override
  String get weatherLocationNameLabel => 'TÊN HIỆN TRÊN THIẾT BỊ';

  @override
  String weatherLocationNameCount(String n) {
    return '$n/16';
  }

  @override
  String get weatherLocationNameHint =>
      'Tối đa 16 ký tự để vừa khe trên màn thiết bị.';

  @override
  String get weatherLocationPreview => 'TRÊN THIẾT BỊ';

  @override
  String weatherLocationPreviewWeather(String desc, String place) {
    return 'Thời tiết: $desc · $place';
  }

  @override
  String weatherLocationPreviewClock(String offset, String place) {
    return 'Đồng hồ: Múi giờ: GMT$offset · $place';
  }

  @override
  String get weatherLocationApply => 'Đặt cho thiết bị';

  @override
  String get weatherLocationApplyCoords => 'Đặt toạ độ cho thiết bị';

  @override
  String get weatherLocationSaveName => 'Lưu tên';

  @override
  String get weatherLocationSending => 'Đang gửi…';

  @override
  String get weatherLocationRejectedTitle => 'Thiết bị không nhận';

  @override
  String get weatherLocationRejectedBody =>
      'Vị trí trên thiết bị chưa đổi. Kiểm tra thiết bị còn cùng mạng rồi thử lại.';

  @override
  String get weatherLocationOldFwSheet =>
      'Firmware này chưa hiện tên nơi: thiết bị chỉ nhận toạ độ.';

  @override
  String weatherLocationDone(String place) {
    return 'Đã đặt $place cho thiết bị.';
  }

  @override
  String get weatherLocationClearTitle => 'Xoá vị trí thời tiết?';

  @override
  String weatherLocationClearBody(String place) {
    return 'Thiết bị sẽ không lấy thời tiết và dự báo nữa, tên “$place” cũng bỏ khỏi màn Thời tiết và Đồng hồ. Mọi điện thoại cùng thấy thay đổi này.';
  }

  @override
  String get weatherLocationClearOk => 'Xoá';

  @override
  String get controlTrackpadA11y =>
      'Bàn rê: rê một ngón để di chuột trên thiết bị, chạm nhẹ để click';

  @override
  String get controlMouseLeft => 'Trái';

  @override
  String get controlMouseRight => 'Phải';

  @override
  String get controlMouseLeftA11y => 'Chuột trái';

  @override
  String get controlMouseRightA11y => 'Chuột phải';

  @override
  String get controlKeysA11y => 'Phím';

  @override
  String get keyWindows => 'Windows';

  @override
  String get keyAltTab => 'Alt+Tab';

  @override
  String get keyAltF4 => 'Alt+F4';

  @override
  String get keyEsc => 'Esc';

  @override
  String get keyTab => 'Tab';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyLeft => 'Trái';

  @override
  String get keyUp => 'Lên';

  @override
  String get keyDown => 'Xuống';

  @override
  String get keyRight => 'Phải';

  @override
  String get keyText => 'Chữ';

  @override
  String get keyTextSoon => 'sắp có';

  @override
  String get powerOff => 'Tắt máy';

  @override
  String get powerOn => 'Bật máy';

  @override
  String get powerShutting => 'Đang tắt máy';

  @override
  String get powerBooting => 'Đang khởi động';

  @override
  String get controlNightA11y => 'Chế độ đêm';

  @override
  String get controlDetailsA11y => 'Số liệu';

  @override
  String get photoLibraryTitle => 'KHO ẢNH';

  @override
  String photoLibraryCount(String count, String cached) {
    return '$count ảnh · $cached trên máy';
  }

  @override
  String photoLibraryCountAll(String count) {
    return '$count ảnh · cả $count trên máy';
  }

  @override
  String get photoLibraryCountEmpty => 'chưa có ảnh';

  @override
  String get photoSourceOnline => 'Thiết bị đang lấy ảnh từ điện thoại';

  @override
  String photoSourceShowing(String index, String count) {
    return 'đang chiếu $index/$count';
  }

  @override
  String get photoSourceOffline => 'Thiết bị chỉ chiếu 8 ảnh đã giữ';

  @override
  String get photoSourceOfflineBody =>
      'Điện thoại khác mạng, hoặc app đã tắt quá 2 phút.';

  @override
  String get photoLibraryShowingTag => 'ĐANG CHIẾU';

  @override
  String photoLibraryTileA11y(String n, String onDevice, String showing) {
    return 'Ảnh $n$onDevice$showing, bấm để xoá';
  }

  @override
  String get photoLibraryOnDeviceA11y => ', đang ở trên thiết bị';

  @override
  String get photoLibraryShowingA11y => ', thiết bị đang chiếu';

  @override
  String get photoLibraryNote =>
      '8 ảnh mới nhất được giữ trên thiết bị để chiếu cả khi điện thoại vắng. Bấm ảnh để xoá khỏi kho.';

  @override
  String get photoLibraryEmptyTitle => 'Kho ảnh trống';

  @override
  String get photoLibraryEmptyBody =>
      'Thêm ảnh từ thư viện hoặc máy ảnh. Ảnh nằm trên điện thoại, không giới hạn số ảnh; thiết bị lấy ảnh từ đây để chiếu.';

  @override
  String get photoLibraryAdding => 'Đang thêm…';

  @override
  String get photoLibraryAddErrorTitle => 'Chưa thêm được ảnh';

  @override
  String get photoLibraryAddErrorBody =>
      'Thiết bị không nhận bản đệm nên ảnh chưa vào kho. Vùng cắt được giữ.';

  @override
  String get photoLibraryDeleteTitle => 'Xoá ảnh khỏi kho?';

  @override
  String get photoLibraryDeleteBody =>
      'Ảnh bị xoá khỏi điện thoại, và khỏi thiết bị nếu đang được giữ trên máy. Không lấy lại được.';

  @override
  String get photoLibraryDeleting => 'Đang xoá…';

  @override
  String get photoLibraryDeleteErrorBody =>
      'Thiết bị không nhận lệnh xoá bản đệm. Ảnh vẫn còn trong kho.';

  @override
  String get photoCropAddToLibrary => 'Thêm vào kho';

  @override
  String get wifiScanEntry => 'Quét mã trên màn thiết bị';

  @override
  String get wifiScanEntrySub =>
      'Nhanh nhất: app tự gửi mạng điện thoại đang dùng.';

  @override
  String get wifiOrManual => 'HOẶC NHẬP TAY';

  @override
  String wifiSavedLink(String count) {
    return 'Mật khẩu đã nhớ ($count)';
  }

  @override
  String get wifiScannedTitle => 'Đã đọc mã của thiết bị';

  @override
  String get wifiScannedBody => 'Thiết bị sẽ vào mạng điện thoại đang dùng.';

  @override
  String get wifiScannedNoNetwork =>
      'Điện thoại chưa ở mạng Wi-Fi nào nên app không biết mạng để gửi. Nhập tên mạng và mật khẩu.';

  @override
  String get wifiNetworkToSend => 'MẠNG SẼ GỬI';

  @override
  String get wifiChangeNetwork => 'Đổi mạng';

  @override
  String wifiPassFor(String ssid) {
    return 'Mật khẩu Wi-Fi “$ssid”';
  }

  @override
  String get wifiRememberNote =>
      'App nhớ mật khẩu này trong kho bảo mật của máy khi thiết bị vào được mạng — lần sau quét là xong.';

  @override
  String get wifiSavedTitle => 'Mật khẩu đã nhớ';

  @override
  String get wifiSavedBody =>
      'Chỉ trên điện thoại này, trong kho bảo mật. Quét mã ở các mạng này sẽ gửi luôn, không hỏi.';

  @override
  String wifiSavedLastUsed(String when) {
    return 'dùng lần cuối $when';
  }

  @override
  String get wifiForget => 'Quên';

  @override
  String wifiForgetTitle(String ssid) {
    return 'Quên mật khẩu “$ssid”?';
  }

  @override
  String get wifiForgetBody =>
      'Lần sau quét mã ở mạng này, app sẽ hỏi lại mật khẩu. Thiết bị không bị ảnh hưởng.';

  @override
  String get wifiScanTitle => 'Quét mã trên thiết bị';

  @override
  String get wifiScanCloseA11y => 'Đóng';

  @override
  String get wifiScanHelpTitle => 'Đưa mã QR vào khung';

  @override
  String get wifiScanHelpBody =>
      'Thiết bị hiện màn này khi chưa vào được Wi-Fi. Giữ máy cách màn khoảng một gang tay.';

  @override
  String get wifiScanHelpImageA11y => 'Màn cài Wi-Fi của thiết bị có mã QR';

  @override
  String get wifiScanManual => 'Không có mã? Nhập tay';

  @override
  String get wifiScanFound => 'Đã đọc mã glimmer-setup';

  @override
  String get wifiScanFoundBody => 'Đang chuyển sang bước tiếp…';

  @override
  String get wifiScanWrongTitle => 'Đây không phải mã của glimmer';

  @override
  String get wifiScanWrongBody =>
      'Quét mã trên màn cài đặt Wi-Fi của thiết bị. App không làm gì với mã này.';

  @override
  String get wifiScanAgain => 'Quét lại';

  @override
  String get wifiScanCameraTitle => 'Cần quyền camera';

  @override
  String get wifiScanCameraBody =>
      'App chỉ dùng camera để đọc mã QR trên màn thiết bị, không chụp hay lưu ảnh.';

  @override
  String get wifiScanAllowCamera => 'Cho phép camera';

  @override
  String get wifiScanOpenSettings => 'Mở cài đặt điện thoại';

  @override
  String get commonClose => 'Đóng';

  @override
  String get devWifiUsedToday => 'hôm nay';
}
