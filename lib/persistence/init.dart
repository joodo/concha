import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

late final String riverpodDbPath;
const riverpodTableName = 'riverpod';

Future<void> persistenceInit() async {
  final supportDir = await getApplicationSupportDirectory();
  riverpodDbPath = join(supportDir.path, 'riverpod.db');

  final db = await openDatabase(riverpodDbPath);
  await _makeSureIncrementalColumn(db);
  await _trimCacheToLimit(db);
  await db.close();
}

Future<void> _makeSureIncrementalColumn(Database db) async {
  final tableInfo = await db.rawQuery("PRAGMA table_info($riverpodTableName)");

  final hasId = tableInfo.any((column) => column['name'] == 'id');
  if (hasId) return;

  final columnNames = tableInfo
      .map((column) => column['name'] as String)
      .map((name) => '"$name"')
      .join(', ');

  final columnDefinitions = tableInfo
      .map((column) {
        String name = column['name'] as String;
        String type = column['type'] as String;
        String notNull = column['notnull'] == 1 ? "NOT NULL" : "";
        return '"$name" $type $notNull';
      })
      .join(', ');

  // Create a new table and copy data from the old table to the new one
  await db.transaction((txn) async {
    await txn.execute('''
      CREATE TABLE ${riverpodTableName}_backup (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnDefinitions
      )
    ''');

    await txn.execute('''
      INSERT INTO ${riverpodTableName}_backup ($columnNames)
      SELECT $columnNames FROM $riverpodTableName
    ''');

    await txn.execute("DROP TABLE $riverpodTableName");
    await txn.execute(
      "ALTER TABLE ${riverpodTableName}_backup RENAME TO $riverpodTableName",
    );
  });

  debugPrint("Column 'id' added and existing rows populated successfully.");
}

Future<void> _trimCacheToLimit(Database db) async {
  const maxCount = 100;
  const trimNames = ['TextVoice', 'WordForWord'];

  for (final name in trimNames) {
    final nameLike = '$name(%';

    final totalCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $riverpodTableName WHERE key LIKE ?',
            [nameLike],
          ),
        ) ??
        0;
    if (totalCount <= maxCount) continue;

    int deleteCount = totalCount - maxCount;
    await db.rawQuery(
      '''
      DELETE FROM $riverpodTableName
      WHERE id IN (
        SELECT id FROM $riverpodTableName
        WHERE key LIKE ?
        ORDER BY id ASC
        LIMIT ?
      )
    ''',
      [nameLike, deleteCount],
    );
  }
}
