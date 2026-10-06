class DeviceResourceSnapshot {
  final int batteryPercent;
  final bool charging;
  final bool networkAvailable;
  final bool powerSaver;
  final DateTime capturedAt;

  const DeviceResourceSnapshot({
    required this.batteryPercent,
    required this.charging,
    required this.networkAvailable,
    required this.powerSaver,
    required this.capturedAt,
  });
}
