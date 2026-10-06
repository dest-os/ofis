abstract interface class AresClock {
  DateTime now();
}

class SystemAresClock implements AresClock {
  const SystemAresClock();

  @override
  DateTime now() => DateTime.now();
}
