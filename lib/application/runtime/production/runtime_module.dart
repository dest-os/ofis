abstract interface class RuntimeModule {
  String get name;
  Future<void> start();
  Future<void> stop();
}
