import '../../domain/decision/decision.dart';
import 'decision_engine.dart';

class DecisionService {
  DecisionService({DecisionEngine? engine})
      : _engine = engine ?? DecisionEngine();

  final DecisionEngine _engine;

  Decision evaluate({
    required String id,
    required bool archiveAvailable,
    required bool localAiAvailable,
    required bool freeAiAvailable,
    required bool paidAiAvailable,
  }) {
    return _engine.decide(
      id: id,
      archiveAvailable: archiveAvailable,
      localAiAvailable: localAiAvailable,
      freeAiAvailable: freeAiAvailable,
      paidAiAvailable: paidAiAvailable,
    );
  }
}
