import '../../core/security/cost_policy.dart';
import '../../domain/costs/cost_record.dart';
import '../../domain/costs/cost_status.dart';
import '../ai/ai_registry_repository.dart';
import 'cost_repository.dart';

class CostService {
  final CostRepository repository;

  CostService(this.repository);

  Future<void> record(CostRecord record) async {
    if (record.estimatedAmount < 0 || record.actualAmount < 0) {
      throw ArgumentError('Maliyet negatif olamaz.');
    }
    if (record.provider.trim().isEmpty || record.model.trim().isEmpty) {
      throw ArgumentError('Sağlayıcı ve model bilgisi zorunludur.');
    }
    await repository.save(record);
  }

  Future<double> totalActualCost({String? projectId, String? currency}) async {
    final records = projectId == null
        ? await repository.getAll()
        : await repository.getByProject(projectId);
    return records
        .where((record) => currency == null || record.currency == currency)
        .fold<double>(0, (sum, record) => sum + record.actualAmount);
  }

  bool requiresPaidApproval(AiCostClass costClass) {
    return !CostPolicy.mayRunWithoutUserApproval(costClass);
  }
}

/// AI Registry'ye bağlı maliyet kontrolü için kullanılan basit karar yardımcısı.
/// Gerçek sağlayıcı çağrısı yapmaz ve hiçbir ücretli AI'ı etkinleştirmez.
class AiCostGuard {
  const AiCostGuard();

  bool canAutoRun(AiCostClass costClass) => CostPolicy.mayRunWithoutUserApproval(costClass);

  CostStatus statusFor(AiCostClass costClass) {
    return canAutoRun(costClass) ? CostStatus.approved : CostStatus.pendingApproval;
  }
}
