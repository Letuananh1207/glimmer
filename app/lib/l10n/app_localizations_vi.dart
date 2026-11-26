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
  String get skillFunDesc => 'Nội dung vui cho màn hình.';

  @override
  String get skillsTitle => 'Skill';

  @override
  String get skillsSubtitle => 'Mỗi skill bật là một tab trên dock thiết bị.';

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
      'Thiết bị xoay các tab theo thứ tự trên. Thẻ cần duyệt vẫn chen ngang mọi tab.';

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
  String get weatherSetLocation => 'Đặt vị trí trong Cài đặt';

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
  String get controlOldFwTitle => 'Firmware chưa nhận chạm';

  @override
  String controlOldFwBody(String version) {
    return 'Thiết bị đang chạy $version: chạm trên màn chưa dùng được, chỉ đổi app qua Start.';
  }

  @override
  String get controlUpdateFirmware => 'Cập nhật firmware';

  @override
  String get controlSetupTitle => 'Thiết bị đang ở glimmer-setup';

  @override
  String get controlSetupBody =>
      'Thiết bị chưa vào được Wi-Fi nên chưa điều khiển được.';

  @override
  String get controlSetupAction => 'Cài Wi-Fi';

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
  String devControlCmdClose(String app) {
    return 'Tắt $app';
  }

  @override
  String devControlCmdMinimize(String app) {
    return 'Thu nhỏ $app';
  }

  @override
  String devXpWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Thứ Hai',
      '2': 'Thứ Ba',
      '3': 'Thứ Tư',
      '4': 'Thứ Năm',
      '5': 'Thứ Sáu',
      '6': 'Thứ Bảy',
      'other': 'Chủ Nhật',
    });
    return '$_temp0';
  }

  @override
  String get devXpTitleAi => 'AI hôm nay';

  @override
  String get devXpTitleAgents => 'Tác tử';

  @override
  String get devXpTitleClock => 'Đồng hồ';

  @override
  String get devXpTitleForecast => 'Dự báo';

  @override
  String get devXpTitleInfo => 'Thông tin';

  @override
  String get devXpTitlePhoto => 'Ảnh';

  @override
  String get devXpTitleSetup => 'Cài đặt';

  @override
  String get devXpTitleTrend => 'Xu hướng';

  @override
  String get devXpTitleWeather => 'Thời tiết';

  @override
  String get devXpCardNeedApproval => 'Cần bạn duyệt';

  @override
  String get devXpCardDoneTitle => 'Xong rồi!';

  @override
  String devXpCardRunningPct(int pct) {
    return 'Đang chạy $pct%';
  }

  @override
  String devXpCardFinished(String name) {
    return '$name đã xong';
  }

  @override
  String devXpCardWaitingAnswer(String name) {
    return '$name đang chờ câu trả lời';
  }

  @override
  String devXpCardWaitStatus(String age) {
    return 'chờ bạn · $age';
  }

  @override
  String devXpSeconds(int n) {
    return '$n giây';
  }

  @override
  String devXpShortDur(int n, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'minutes': 'P',
      'hours': 'G',
      'other': 'NG',
    });
    return '$n$_temp0';
  }

  @override
  String get devXpRowNeedYou => 'Cần bạn';

  @override
  String get devXpRowWaitingYou => 'Đang chờ bạn';

  @override
  String devXpKindWord(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'approval': 'Phê duyệt',
      'error': 'Lỗi',
      'input': 'Chờ bạn',
      'progress': 'Tiến độ',
      'warning': 'Cảnh báo',
      'success': 'Xong',
      'other': 'Thông tin',
    });
    return '$_temp0';
  }

  @override
  String devXpMoreItems(int n) {
    return '+ $n mục khác';
  }

  @override
  String devXpItems(int n) {
    return '$n mục';
  }

  @override
  String devXpNApprovals(int n) {
    return '$n cần duyệt';
  }

  @override
  String devXpNInputs(int n) {
    return '$n lượt bạn';
  }

  @override
  String get devXpNoneWaiting => 'không mục nào chờ';

  @override
  String get devXpDeskTrash => 'Thùng rác';

  @override
  String devXpDeskNow(int temp, String desc) {
    return '$temp° · $desc';
  }

  @override
  String devXpDeskFeels(int temp) {
    return 'cảm giác $temp°';
  }

  @override
  String get devXpDeskNoWeather => 'chưa có thời tiết';

  @override
  String get devXpSetupHead => 'Hoàn tất cài đặt';

  @override
  String devXpSetupLeft(int n) {
    return 'Còn $n bước nữa là xong.';
  }

  @override
  String get devXpSetupClaude => 'Khóa Claude';

  @override
  String get devXpSetupCodex => 'Token Codex';

  @override
  String get devXpSetupWeather => 'Thời tiết, vị trí, giờ';

  @override
  String get devXpSetupOpen => 'Mở trong trình duyệt';

  @override
  String get devXpPhotoEmpty => 'Chưa có ảnh';

  @override
  String get devXpPhotoSend => 'Gửi ảnh từ app glimmer';

  @override
  String get devXpPhotoOr => 'hoặc';

  @override
  String get devXpWeatherLoading => 'Đang tải thời tiết...';

  @override
  String get devXpWeatherErrorHead => 'Chưa có thời tiết';

  @override
  String devXpWeatherErrHttp(int code) {
    return 'Máy chủ trả lỗi $code.';
  }

  @override
  String get devXpWeatherErrConnect => 'Không kết nối được.';

  @override
  String get devXpWeatherErrBegin => 'Không mở được kết nối.';

  @override
  String get devXpWeatherErrJson => 'Dữ liệu lỗi.';

  @override
  String get devXpWeatherErrNoCurrent => 'Thiếu số liệu hiện tại.';

  @override
  String get devXpWeatherErrUnknown => 'Không rõ lỗi.';

  @override
  String get devXpWeatherRetrying => 'Đang tự thử lại...';

  @override
  String devXpWeatherFeels(int t) {
    return 'cảm giác $t°';
  }

  @override
  String devXpWeatherHumidity(int n) {
    return 'ẩm $n%';
  }

  @override
  String devXpWeatherWind(int n) {
    return 'gió ${n}km';
  }

  @override
  String get devXpDayToday => 'Nay';

  @override
  String get devXpDayTomorrow => 'Mai';

  @override
  String get devXpDayAfter => 'Kia';

  @override
  String devXpWeatherSun(String event, String time) {
    String _temp0 = intl.Intl.selectLogic(event, {
      'set': 'Mặt trời lặn',
      'other': 'Mặt trời mọc',
    });
    return '$_temp0 $time';
  }

  @override
  String devXpWeatherUpdated(String age) {
    return 'Cập nhật $age trước';
  }

  @override
  String devXpStaleMeta(String age) {
    return 'cũ $age';
  }

  @override
  String devXpSpanShort(String unit, int n) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'minutes': '${n}P',
      'hours': '${n}G',
      'other': '${n}NG',
    });
    return '$_temp0';
  }

  @override
  String devXpSpanLong(String unit, int n) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'minutes': '$n phút',
      'hours': '$n giờ',
      'other': '$n ngày',
    });
    return '$_temp0';
  }

  @override
  String get devXpForecastEmpty => 'Chưa có dự báo';

  @override
  String get devXpForecastNext3 => '3 ngày tới';

  @override
  String devXpClockGreeting(String slot, String name) {
    String _temp0 = intl.Intl.selectLogic(slot, {
      'night': 'ngủ ngon nhé',
      'morning': 'chào buổi sáng',
      'afternoon': 'chào buổi chiều',
      'evening': 'chào buổi tối',
      'other': 'nghỉ ngơi thôi',
    });
    return '$_temp0, $name';
  }

  @override
  String get devXpClockYou => 'bạn';

  @override
  String devXpClockWeek(int n) {
    return 'Tuần $n';
  }

  @override
  String devXpInfoLabels(String row) {
    String _temp0 = intl.Intl.selectLogic(row, {
      'ip': 'IP',
      'ssid': 'SSID',
      'rssi': 'Sóng',
      'up': 'Đã chạy',
      'heap': 'Bộ nhớ',
      'block': 'Khối lớn',
      'fw': 'Firmware',
      'channels': 'Kênh',
      'updated': 'Cập nhật',
      'other': 'Lần tới',
    });
    return '$_temp0';
  }

  @override
  String devXpInfoMinutes(int n) {
    return '${n}P';
  }

  @override
  String devXpInfoHeap(int n) {
    return '${n}K trống';
  }

  @override
  String devXpInfoAgo(int n) {
    return '${n}P trước';
  }

  @override
  String devXpInfoNext(int n) {
    return 'sau ${n}P';
  }

  @override
  String get devXpSetupLine1 => 'Để bắt đầu,';

  @override
  String get devXpSetupLine2 => 'kết nối Wi-Fi';

  @override
  String get devXpSetupPower => 'Cài đặt Wi-Fi';

  @override
  String get devXpOtaWarn => 'Đừng tắt hay rút điện máy.';

  @override
  String get devXpNoChannelsHead => 'Chưa có kênh';

  @override
  String get devXpNoChannelsLine => 'Bật kênh trên trang web:';

  @override
  String get devXpCardApproval => 'Cần duyệt';

  @override
  String get devXpCardInput => 'Lượt bạn';

  @override
  String get devXpCardDone => 'Xong';

  @override
  String get devXpCardError => 'Lỗi';

  @override
  String get devXpCardProgress => 'Đang chạy';

  @override
  String get devXpCardWarning => 'Cảnh báo';

  @override
  String get devXpCardInfo => 'Thông tin';

  @override
  String devXpSpanHourMin(int h, int m) {
    return '${h}G ${m}P';
  }

  @override
  String devXpMeta(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'keyBad': 'khóa lỗi',
      'blocked': 'bị chặn',
      'maintenance': 'bảo trì',
      'minor': 'chập chờn',
      'other': 'sự cố',
    });
    return '$_temp0';
  }

  @override
  String devXpMetaExpiring(String left) {
    return 'hạn $left';
  }

  @override
  String get devXpLoading => 'Đang tải...';

  @override
  String devXpWindow(String kind, int n) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'week': 'Hạn mức tuần',
      'day': 'Hạn mức ngày',
      'hours': 'Phiên $n giờ',
      'minutes': 'Phiên $n phút',
      'other': 'Hạn mức',
    });
    return '$_temp0';
  }

  @override
  String devXpProjState(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'approval': 'Cần duyệt',
      'input': 'Chờ bạn',
      'error': 'Lỗi',
      'working': 'Đang chạy',
      'other': 'Xong',
    });
    return '$_temp0';
  }

  @override
  String get devXpNoProject => 'Chưa có hoạt động project';

  @override
  String devXpCredNoun(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'claude': 'khóa',
      'other': 'token',
    });
    return '$_temp0';
  }

  @override
  String devXpCredNounCap(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'claude': 'Khóa',
      'other': 'Token',
    });
    return '$_temp0';
  }

  @override
  String devXpCredWho(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'claude': 'Khóa Claude',
      'other': 'Token Codex',
    });
    return '$_temp0';
  }

  @override
  String devXpCredWhoLower(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'claude': 'khóa Claude',
      'other': 'token Codex',
    });
    return '$_temp0';
  }

  @override
  String devXpBanner(String noun, String state, String host) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'expired': 'hết hạn',
      'other': 'bị từ chối',
    });
    return '$noun $_temp0 · $host';
  }

  @override
  String devXpBannerShort(String state, String host) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'expired': 'Hết hạn',
      'other': 'Bị từ chối',
    });
    return '$_temp0 · $host';
  }

  @override
  String devXpBannerBlocked(String noun) {
    return 'Bị chặn · $noun vẫn tốt · thử lại';
  }

  @override
  String devXpBannerBlockedShort(String noun) {
    return 'Bị chặn · $noun vẫn tốt';
  }

  @override
  String devXpCredHeadRejected(String noun) {
    return '$noun bị từ chối';
  }

  @override
  String devXpCredRejectedLine(String host, String noun) {
    return '$host từ chối $noun.';
  }

  @override
  String devXpCredEnterNew(String noun) {
    return 'Nhập $noun mới tại:';
  }

  @override
  String devXpCredHeadExpired(String noun) {
    return '$noun hết hạn';
  }

  @override
  String devXpCredExpiredOn(String date) {
    return 'Hết hạn ngày $date.';
  }

  @override
  String get devXpCredExpired => 'Đã hết hạn.';

  @override
  String get devXpCredHeadBlocked => 'Bị chặn';

  @override
  String devXpCredBlockedLine(String host) {
    return '$host chặn máy này.';
  }

  @override
  String devXpCredStillGood(String noun) {
    return '$noun vẫn tốt.';
  }

  @override
  String get devXpCredRetry15 => 'Thử lại mỗi 15 phút.';

  @override
  String devXpCredHeadNotSet(String noun) {
    return 'Chưa có $noun';
  }

  @override
  String devXpCredEnter(String noun) {
    return 'Nhập $noun tại:';
  }

  @override
  String get devXpCredHeadOffline => 'Mất mạng';

  @override
  String devXpCredUnreachable(String host) {
    return 'Không tới được $host.';
  }

  @override
  String devXpCredUnreachableShort(String host) {
    return 'Không tới $host.';
  }

  @override
  String get devXpCredCheckWifi => 'Kiểm tra Wi-Fi.';

  @override
  String get devXpCredHeadUpstream => 'Không đọc được';

  @override
  String devXpCredUpstreamLine(String host) {
    return '$host trả lỗi:';
  }

  @override
  String get devXpCredAutoRetry => 'Đang tự động thử lại...';

  @override
  String devXpCredStatusNotSet(String who) {
    return 'Chưa có $who';
  }

  @override
  String devXpCredStatusExpired(String who) {
    return '$who hết hạn';
  }

  @override
  String devXpCredStatusRejected(String who) {
    return '$who bị từ chối';
  }

  @override
  String devXpCredStatusBlocked(String host) {
    return '$host chặn máy này';
  }

  @override
  String get devXpResetIn => 'đặt lại sau';

  @override
  String get devXpCredits => 'tín dụng';

  @override
  String get devXpUsed => 'Đã dùng';

  @override
  String get devXpNone => 'Không có';

  @override
  String get devXpWeekResets => 'Đặt lại tuần';

  @override
  String get devXpNoResets => 'Chưa có lượt';

  @override
  String devXpResetsLeft(int n) {
    return 'còn $n';
  }

  @override
  String devXpResetsLeftIn(int n, String span) {
    return 'còn $n · $span';
  }

  @override
  String devXpResetsLeftUntil(int n, String date) {
    return 'còn $n · đến $date';
  }

  @override
  String devXpPaceEmpty(String span) {
    return 'hết sau $span';
  }

  @override
  String devXpPaceAtReset(int pct) {
    return '~$pct% khi đặt lại';
  }

  @override
  String get devXpAiHero => 'Tín dụng Codex còn';

  @override
  String devXpAiBad(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'blocked': 'Chặn',
      'other': 'Khóa',
    });
    return '$_temp0';
  }

  @override
  String devXpAiResets(String cl, String cx) {
    return 'CL $cl · CX $cx';
  }

  @override
  String devXpAdviceUse(String name) {
    return 'Dùng $name';
  }

  @override
  String devXpAdviceResets(String name, int n) {
    return '$name có $n lượt đặt lại';
  }

  @override
  String get devXpAdviceBothLow => 'Cả hai sắp hết';

  @override
  String get devXpTrendLabel => '7 ngày · % hạn mức tuần';

  @override
  String get devXpTrendToday => 'Hôm nay';

  @override
  String devXpTrendPeak(String day) {
    return 'Đỉnh $day';
  }

  @override
  String devXpTrendHave(int n) {
    return 'Có $n / 7 ngày';
  }

  @override
  String get devXpTrendCollecting => 'Đang thu thập...';

  @override
  String devXpTrendLast(int d, int m) {
    return 'cuối $d/$m';
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
}
