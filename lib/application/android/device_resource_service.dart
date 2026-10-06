import '../../domain/android/device_resource_snapshot.dart';

class DeviceResourceService {
  DeviceResourceSnapshot snapshot({
    required int batteryPercent,
    required bool charging,
    required bool networkAvailable,
    required bool powerSaver,
  }) {
    return DeviceResourceSnapshot(
      batteryPercent: batteryPercent,
      charging: charging,
      networkAvailable: networkAvailable,
      powerSaver: powerSaver,
      capturedAt: DateTime.now(),
    );
  }
}
