/// The rolling `latest` release CI publishes on every push to main.
class Release {
  const Release(this.published, this.commit, this.assets);

  final DateTime published;

  /// First 7 of the target commit, if known.
  final String commit;

  /// Asset name → download URL.
  final Map<String, String> assets;
}
