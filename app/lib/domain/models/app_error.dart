/// Why something failed. The UI turns [AppError.kind] into words (l10n) — no user-facing text here.
enum AppErrorKind {
  /// The device asked for an API token (HTTP 401).
  unauthorized,

  /// The device answered with an HTTP error ([AppError.status]).
  http,

  /// No answer (timeout / unreachable); [AppError.detail] = the low-level error.
  unreachable,

  /// OTA upload rejected; [AppError.detail] = the device's answer.
  flashFailed,

  /// GitHub rate limit (HTTP 403 on the releases API).
  rateLimited,

  /// GitHub releases API answered [AppError.status].
  releaseHttp,

  /// Downloading a release asset failed ([AppError.status], 0 = network).
  download,

  /// The release has no asset named [AppError.detail].
  noAsset,

  /// Discovery found no display on this network.
  notFound,

  /// Nothing answered at the typed address [AppError.detail].
  noDeviceAt,

  /// Location / nearby-Wi-Fi permission refused.
  wifiPermission,

  /// Could not join or reach the setup AP "glimmer-setup".
  setupAp,

  /// The device did not show up on Wi-Fi [AppError.detail] after the change.
  notOnNetwork,

  /// The device did not answer after flashing the firmware.
  noAnswerAfterFlash,

  /// The device's config could not be read for a backup.
  configUnreadable,

  /// The picked file is not a glimmer config; [AppError.detail] = parser message.
  invalidBackup,

  /// The device's firmware cannot toggle skills, or does not have skill [AppError.detail] (R-SK-4).
  skillUnsupported,

  /// Turning off [AppError.detail] would leave no skill on (R-SK-1).
  skillLastOne,

  /// The device already holds its maximum of photos (`full`, HTTP 413).
  photoFull,

  /// The photo stays over the device's byte limit even at the lowest JPEG quality (`too_big`).
  photoTooBig,

  /// The device filesystem has no room left (`no_space`, HTTP 507).
  photoNoSpace,

  /// The device refused the file (`not_jpeg` / `progressive` / `bad_size` / `truncated` / `empty` / `field`);
  /// [AppError.detail] = the device's code. Also: the picked image could not be read.
  photoRejected,

  /// DELETE /api/photos: no photo named [AppError.detail] on the device (HTTP 404).
  photoNotFound,

  /// The user cancelled the upload.
  cancelled,

  /// Anything else; [AppError.detail] = the error.
  other,
}

class AppError implements Exception {
  const AppError(this.kind, {this.status = 0, this.detail = ''});

  /// Wraps anything thrown into an [AppError] (an [AppError] passes through).
  factory AppError.from(Object e) => e is AppError ? e : AppError(AppErrorKind.other, detail: '$e');

  final AppErrorKind kind;
  final int status;
  final String detail;

  @override
  String toString() => 'AppError(${kind.name}, $status, $detail)';
}
