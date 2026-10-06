import '../../domain/runtime/resource_snapshot.dart';

abstract interface class ResourceRuntime {
  Future<ResourceSnapshot> snapshot();
  bool mayStartWork(ResourceSnapshot snapshot);
}

class DefaultResourceRuntime implements ResourceRuntime {
  DefaultResourceRuntime({
    this.minimumBatteryPercent = 10,
    this.requireNetwork = false,
  });

  final int minimumBatteryPercent;
  final bool requireNetwork;

  @override
  Future<ResourceSnapshot> snapshot() async {
    return ResourceSnapshot(capturedAt: DateTime.now());
  }

  @override
  bool mayStartWork(ResourceSnapshot snapshot) {
    if (snapshot.batteryPercent != null &&
        snapshot.batteryPercent! < minimumBatteryPercent &&
        snapshot.isCharging != true) {
      return false;
    }
    if (requireNetwork && snapshot.isNetworkAvailable == false) return false;
    return true;
  }
}
