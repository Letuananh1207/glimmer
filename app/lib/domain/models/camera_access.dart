/// Camera permission for reading the QR on the display (WifiScanScreen, design 2026-11-28.12).
enum CameraAccess {
  granted,

  /// Refused this time: asking again shows the system dialog.
  denied,

  /// Refused for good ("don't ask again" / blocked): only the phone's settings can allow it.
  blocked,
}
