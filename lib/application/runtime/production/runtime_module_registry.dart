import 'runtime_module.dart';

class RuntimeModuleRegistry {
  final List<RuntimeModule> _modules = <RuntimeModule>[];

  void register(RuntimeModule module) {
    if (_modules.any((item) => item.name == module.name)) return;
    _modules.add(module);
  }

  List<RuntimeModule> get modules => List.unmodifiable(_modules);

  Future<void> startAll() async {
    for (final module in _modules) {
      await module.start();
    }
  }

  Future<void> stopAll() async {
    for (final module in _modules.reversed) {
      await module.stop();
    }
  }
}
