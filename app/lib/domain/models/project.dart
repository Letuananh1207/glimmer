import '../../utils/json.dart';

/// One row of the project board (latest state per project).
class Project {
  const Project(this.project, this.agent, this.state, this.detail, this.ageS, this.idleS, this.shown);

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        jsonStr(j['project']),
        jsonStr(j['agent']),
        jsonStr(j['state']),
        jsonStr(j['detail']),
        jsonInt(j['age_s']),
        jsonInt(j['idle_s']),
        jsonBool(j['shown']),
      );

  final String project, agent;

  /// approval / input / error / working / done.
  final String state;
  final String detail;
  final int ageS, idleS;
  final bool shown;
}
