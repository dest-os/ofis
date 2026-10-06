import 'in_memory_database.dart';

abstract interface class DatabaseMigration {
  int get fromVersion;
  int get toVersion;

  Future<void> migrate(InMemoryDatabase database);
}
