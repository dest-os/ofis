import '../../../domain/runtime/runtime_mode.dart';

class OfflineOnlineManager {
  RuntimeMode _mode = RuntimeMode.online;

  RuntimeMode get mode => _mode;
  bool get isOnline => _mode == RuntimeMode.online;

  void setOnline() => _mode = RuntimeMode.online;
  void setOffline() => _mode = RuntimeMode.offline;
}
