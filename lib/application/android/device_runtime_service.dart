import '../../domain/android/device_runtime_state.dart';

class DeviceRuntimeService {
  DeviceRuntimeState _state = DeviceRuntimeState.stopped;

  DeviceRuntimeState get state => _state;

  void start() {
    if (_state == DeviceRuntimeState.running) return;
    _state = DeviceRuntimeState.starting;
    _state = DeviceRuntimeState.running;
  }

  void pause() => _state = DeviceRuntimeState.paused;
  void resume() => _state = DeviceRuntimeState.running;
  void recover() => _state = DeviceRuntimeState.recovering;
  void stop() => _state = DeviceRuntimeState.stopped;
}
