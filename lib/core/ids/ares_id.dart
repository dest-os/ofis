class AresId {
  const AresId(this.value);

  final String value;

  factory AresId.generate() =>
      AresId(DateTime.now().toUtc().microsecondsSinceEpoch.toString());

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) {
    return other is AresId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
