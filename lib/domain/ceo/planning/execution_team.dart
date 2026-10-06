import 'team_member.dart';

class ExecutionTeam {
  ExecutionTeam({required List<TeamMember> members})
      : members = List<TeamMember>.unmodifiable(members);

  final List<TeamMember> members;

  bool covers(String stepId) => members.any((m) => m.stepId == stepId);

  List<TeamMember> forStep(String stepId) =>
      members.where((m) => m.stepId == stepId).toList(growable: false);
}
