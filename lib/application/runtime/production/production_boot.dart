import 'production_composition_root.dart';
import 'production_runtime.dart';

class ProductionBoot {
  ProductionBoot({ProductionCompositionRoot? root})
      : root = root ?? ProductionCompositionRoot();

  final ProductionCompositionRoot root;
  ProductionRuntime? _runtime;

  ProductionRuntime get runtime {
    final value = _runtime;
    if (value == null) {
      throw StateError('ARES üretim çalışma çekirdeği henüz başlatılmadı.');
    }
    return value;
  }

  Future<ProductionRuntime> start() async {
    final created = root.build();
    await created.start();
    _runtime = created;
    return created;
  }

  Future<void> shutdown() async {
    await _runtime?.stop();
    _runtime = null;
  }
}
