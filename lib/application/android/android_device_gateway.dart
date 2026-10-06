import '../../domain/android/android_device.dart';
import '../../domain/android/android_permission.dart';

abstract interface class AndroidDeviceGateway {
  Future<AndroidDevice> getDevice();
  Future<bool> hasPermission(AndroidPermission permission);
  Future<bool> requestPermission(AndroidPermission permission);
}
