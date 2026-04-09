import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';

part 'riverpod.g.dart';

@Riverpod(keepAlive: true)
class PersistStorage extends _$PersistStorage {
  static late final String dbPath;
  static const tableName = 'riverpod';

  @override
  Future<Storage<String, String>> build() async {
    final supportDir = await getApplicationSupportDirectory();
    dbPath = join(supportDir.path, 'riverpod.db');

    final db = await openDatabase(dbPath);
    await _makeSureIncrementalColumn(db);
    await _trimCacheToLimit(db);
    await db.close();

    return JsonSqFliteStorage.open(dbPath);
  }

  Future<void> _makeSureIncrementalColumn(Database db) async {
    final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");

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
      CREATE TABLE ${tableName}_backup (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnDefinitions
      )
    ''');

      await txn.execute('''
      INSERT INTO ${tableName}_backup ($columnNames)
      SELECT $columnNames FROM $tableName
    ''');

      await txn.execute("DROP TABLE $tableName");
      await txn.execute("ALTER TABLE ${tableName}_backup RENAME TO $tableName");
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
              'SELECT COUNT(*) FROM $tableName WHERE key LIKE ?',
              [nameLike],
            ),
          ) ??
          0;
      if (totalCount <= maxCount) continue;

      int deleteCount = totalCount - maxCount;
      await db.rawQuery(
        '''
      DELETE FROM $tableName
      WHERE id IN (
        SELECT id FROM $tableName
        WHERE key LIKE ?
        ORDER BY id ASC
        LIMIT ?
      )
    ''',
        [nameLike, deleteCount],
      );
    }
  }
}
