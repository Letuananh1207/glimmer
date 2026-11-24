/// A config.json the user picked to restore.
class ConfigBackup {
  const ConfigBackup(this.fileName, this.config);
  final String fileName;
  final Map<String, dynamic> config;
}
