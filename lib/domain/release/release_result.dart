import 'release_gate.dart';

class ReleaseResult {
  final bool ready;
  final List<ReleaseGate> gates;
  final List<String> blockers;

  const ReleaseResult({
    required this.ready,
    required this.gates,
    required this.blockers,
  });
}
