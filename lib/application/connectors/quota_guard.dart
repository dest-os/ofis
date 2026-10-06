import '../../domain/connectors/quota_policy.dart';
import '../../domain/connectors/quota_state.dart';

class QuotaGuard {
  bool canRun({
    required QuotaPolicy policy,
    required QuotaState state,
    required double estimatedCost,
    required DateTime now,
  }) {
    final expired = now.difference(state.windowStartedAt) >= policy.window;
    if (expired) return true;
    if (state.calls >= policy.maxCalls) return false;
    if (policy.maxEstimatedCost > 0 &&
        state.estimatedCost + estimatedCost > policy.maxEstimatedCost) {
      return false;
    }
    return true;
  }
}
