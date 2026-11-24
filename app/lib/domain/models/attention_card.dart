import '../../utils/json.dart';

/// An attention card in the device's queue (GET /push).
class AttentionCard {
  const AttentionCard(this.id, this.kind, this.agent, this.title, this.value, this.body, this.project,
      this.progress, this.ageS);

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
      );

  final String id;

  /// approval / input / success / error / progress / warning / info.
  final String kind;
  final String agent, title, value, body, project;
  final int progress, ageS;
}
