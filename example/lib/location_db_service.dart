import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocationDbService {
  static Database? _db;

  static const String _table = 'location_logs';

  static Future<void> initDb() async {
    if (_db != null) return;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'location_logs.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL,
            long REAL,
            created_at TEXT,
            employee_id TEXT,
            is_synced INTEGER
          )
        ''');
      },
    );
  }

  static Future<int> insertLocation({
    required double lat,
    required double long,
    required String employeeId,
    bool isSynced = false,
  }) async {
    await initDb();
    return await _db!.insert(_table, {
      'lat': lat,
      'long': long,
      'created_at': DateTime.now().toIso8601String(),
      'employee_id': employeeId,
      'is_synced': isSynced ? 1 : 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getLocations({
    required String employeeId,
    required bool isSynced,
  }) async {
    await initDb();
    return await _db!.query(
      _table,
      where: 'employee_id = ? AND is_synced = ?',
      whereArgs: [employeeId, isSynced ? 1 : 0],
      orderBy: 'created_at DESC',
    );
  }

  static Future<int> markLocationsAsSynced(List<int> ids) async {
    await initDb();
    return await _db!.update(
      _table,
      {'is_synced': 1},
      where: 'id IN (${ids.join(',')})',
    );
  }

  static Future<void> clearAllLogs() async {
    await initDb();
    await _db!.delete(_table);
  }
}
