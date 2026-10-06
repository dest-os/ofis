enum RuntimeCommandType {
  start,
  stop,
  pause,
  resume,
  recover,
  enterSafeMode,
}

class RuntimeCommand {
  const RuntimeCommand({
    required this.type,
    this.reason,
  });

  final RuntimeCommandType type;
  final String? reason;
}
