import 'memory_reliability.dart';
import 'memory_source_type.dart';

class MemoryFact {
  final String id;
  final String statement;
  final MemorySourceType sourceType;
  final MemoryReliability reliability;
  final DateTime createdAt;
  final DateTime? validUntil;
  final bool superseded;

  const MemoryFact({
    required this.id,
    required this.statement,
    required this.sourceType,
    required this.reliability,
    required this.createdAt,
    this.validUntil,
    this.superseded = false,
  });

  bool isValidAt(DateTime time) {
    return !superseded &&
        !time.isBefore(createdAt) &&
        (validUntil == null || time.isBefore(validUntil!));
  }
}
