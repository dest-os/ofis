class AndroidDevice {
  final String id;
  final String model;
  final String osVersion;
  final int sdkInt;
  final int batteryPercent;
  final bool charging;
  final bool networkAvailable;

  const AndroidDevice({
    required this.id,
    required this.model,
    required this.osVersion,
    required this.sdkInt,
    required this.batteryPercent,
    required this.charging,
    required this.networkAvailable,
  });
}
