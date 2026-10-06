import '../../domain/update/update_plan.dart';
import 'update_guard.dart';

class UpdateService {
  UpdateService({UpdateGuard? guard}) : guard = guard ?? UpdateGuard();

  final UpdateGuard guard;

  bool prepare(UpdatePlan plan) => guard.canInstall(plan);
}
