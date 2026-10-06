import '../../core/database/database_schema_version.dart';
import 'database_migration.dart';
import 'in_memory_database.dart';

class DatabaseManager {
  DatabaseManager({
    InMemoryDatabase? database,
    List<DatabaseMigration> migrations = const <DatabaseMigration>[],
  })  : database = database ?? InMemoryDatabase(),
        _migrations = migrations;

  final InMemoryDatabase database;
  final List<DatabaseMigration> _migrations;

  int get currentVersion => DatabaseSchemaVersion.current;

  Future<void> initialize() async {
    final ordered = List<DatabaseMigration>.from(_migrations)
      ..sort((a, b) => a.fromVersion.compareTo(b.fromVersion));

    for (final migration in ordered) {
      if (migration.toVersion > DatabaseSchemaVersion.current) {
        throw StateError(
          'Veritabanı sürümü uygulamanın sürümünü aşamaz.',
        );
      }

      await migration.migrate(database);
    }
  }
}
