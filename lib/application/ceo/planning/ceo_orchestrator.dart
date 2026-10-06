import '../../../domain/agents/agent_library_entry.dart';
import '../../../domain/ceo/ceo_intent.dart';
import '../../../domain/ceo/planning/ceo_execution_plan.dart';
import '../../../domain/ceo/planning/execution_team.dart';
import 'ceo_planning_engine.dart';
import 'dynamic_team_builder.dart';
import 'plan_validator.dart';

class CeoPlanningResult {
  const CeoPlanningResult({
    required this.plan,
    required this.team,
    required this.validation,
  });

  final CeoExecutionPlan plan;
  final ExecutionTeam team;
  final PlanValidationResult validation;
}

class CeoOrchestrator {
  CeoOrchestrator({
    CeoPlanningEngine? planning,
    DynamicTeamBuilder? teamBuilder,
    PlanValidator? validator,
  })  : _planning = planning ?? CeoPlanningEngine(),
        _teamBuilder = teamBuilder ?? DynamicTeamBuilder(),
        _validator = validator ?? const PlanValidator();

  final CeoPlanningEngine _planning;
  final DynamicTeamBuilder _teamBuilder;
  final PlanValidator _validator;

  CeoPlanningResult createExecutionPlan({
    required String planId,
    required CeoIntent intent,
    required List<AgentLibraryEntry> candidates,
  }) {
    final plan = _planning.createPlan(planId: planId, intent: intent);
    final validation = _validator.validate(plan);
    final team = validation.valid
        ? _teamBuilder.build(plan: plan, candidates: candidates)
        : ExecutionTeam(members: const []);
    return CeoPlanningResult(plan: plan, team: team, validation: validation);
  }
}
