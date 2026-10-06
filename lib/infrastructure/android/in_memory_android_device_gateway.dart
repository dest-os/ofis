import '../../application/android/android_device_gateway.dart';
import '../../domain/android/android_device.dart';
import '../../domain/android/android_permission.dart';

class InMemoryAndroidDeviceGateway implements AndroidDeviceGateway {
  final Set<AndroidPermission> _permissions = {};

  @override
  Future<AndroidDevice> getDevice() async => const AndroidDevice(
        id: 'android-device',
        model: 'Android Tablet',
        osVersion: 'unknown',
        sdkInt: 0,
        batteryPercent: 100,
        charging: false,
        networkAvailable: true,
      );

  @override
  Future<bool> hasPermission(AndroidPermission permission) async => _permissions.contains(permission);

  @override
  Future<bool> requestPermission(AndroidPermission permission) async {
    _permissions.add(permission);
    return true;
  }
}
