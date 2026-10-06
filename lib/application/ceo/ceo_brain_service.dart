import '../../domain/ceo/ceo_intent.dart';
import '../../domain/ceo/ceo_plan.dart';
import 'ceo_intent_parser.dart';
import 'ceo_planner.dart';

class CeoBrainService {
  CeoBrainService({
    CeoIntentParser? parser,
    CeoPlanner? planner,
  })  : _parser = parser ?? CeoIntentParser(),
        _planner = planner ?? CeoPlanner();

  final CeoIntentParser _parser;
  final CeoPlanner _planner;

  CeoIntent understand(String input) {
    return _parser.parse(input);
  }

  CeoPlan plan({
    required CeoIntent intent,
    required String planId,
    required String taskId,
  }) {
    return _planner.createPlan(
      intent: intent,
      planId: planId,
      taskId: taskId,
    );
  }
}
