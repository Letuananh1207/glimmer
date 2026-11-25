import '../../utils/json.dart';

/// An attention card in the device's queue (GET /push).
class AttentionCard {
  const AttentionCard(this.id, this.kind, this.agent, this.title, this.value, this.body, this.project,
      this.progress, this.ageS, {this.showsInS = 0});

  factory AttentionCard.fromJson(Map<String, dynamic> j) => AttentionCard(
        jsonStr(j['id']),
        jsonStr(j['kind']),
        jsonStr(j['agent']),
        jsonStr(j['title']),
        jsonStr(j['value']),
        jsonStr(j['body']),
        jsonStr(j['project']),
        jsonInt(j['progress'], -1),
        jsonInt(j['age_s']),
        showsInS: jsonInt(j['shows_in_s']),
      );

  final String id;

  /// approval / input / success / error / progress / warning / info.
  final String kind;
  final String agent, title, value, body, project;
  final int progress, ageS;

  /// Seconds until the card shows on the device (Codex "your turn" waits 60 s); 0 = showing now.
  final int showsInS;
}
