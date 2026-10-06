class AndroidRecoveryService {
  bool _recoveryRequired = false;

  bool get recoveryRequired => _recoveryRequired;

  void markInterrupted() => _recoveryRequired = true;
  void markRecovered() => _recoveryRequired = false;
}
