enum DecisionType {
  allow,
  deny,
  defer,
  requireApproval,
  useArchive,
  useLocalAi,
  useFreeAi,
  usePaidAi,
}

extension DecisionTypeX on DecisionType {
  String get value => name.toUpperCase();
}
