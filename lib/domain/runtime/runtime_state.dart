enum RuntimeState {
  created,
  starting,
  ready,
  running,
  waitingApproval,
  paused,
  recovering,
  stopping,
  stopped,
  failed,
}

extension RuntimeStateX on RuntimeState {
  bool get isTerminal => this == RuntimeState.stopped || this == RuntimeState.failed;
  String get value => name.toUpperCase();
}
