class FeatureFlags {
  const FeatureFlags({
    this.productionRuntime = true,
    this.localAi = true,
    this.remoteAi = true,
    this.voice = true,
    this.backgroundRuntime = true,
    this.learning = true,
  });

  final bool productionRuntime;
  final bool localAi;
  final bool remoteAi;
  final bool voice;
  final bool backgroundRuntime;
  final bool learning;
}
