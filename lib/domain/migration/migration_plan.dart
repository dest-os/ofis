class MigrationPlan {
  final String id; final int fromVersion; final int toVersion; final List<String> steps; final bool destructive;
  const MigrationPlan({required this.id, required this.fromVersion, required this.toVersion, required this.steps, this.destructive = false});
}
