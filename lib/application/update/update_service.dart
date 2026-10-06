import '../../domain/update/update_plan.dart';
import 'update_guard.dart';
class UpdateService {
  final UpdateGuard guard;
  const UpdateService({this.guard = const UpdateGuard()});
  bool prepare(UpdatePlan plan) => guard.canInstall(plan);
}
