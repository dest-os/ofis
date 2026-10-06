enum DataClassification { public, internal, private, sensitive, critical }

extension DataClassificationX on DataClassification {
  bool get isProtected => this == DataClassification.private || this == DataClassification.sensitive || this == DataClassification.critical;
  bool get requiresStrictHandling => this == DataClassification.sensitive || this == DataClassification.critical;
}
