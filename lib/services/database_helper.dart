import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/expense_item.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _databaseName = 'vku_expense_ocr.db';
  static const _tableName = 'expenses';
  static const _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, _databaseName),
      version: _databaseVersion,
      onCreate: (database, version) async {
        await _createExpensesTable(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.transaction((transaction) async {
            await transaction.execute(
              'ALTER TABLE $_tableName RENAME TO expenses_v1',
            );
            await _createExpensesTable(transaction);
            await transaction.execute('''
              INSERT INTO $_tableName (id, merchant, amount, date, category)
              SELECT id, merchant, amount, date, category
              FROM expenses_v1
            ''');
            await transaction.execute('DROP TABLE expenses_v1');
          });
        }
      },
    );
    return _database!;
  }

  Future<void> _createExpensesTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT
      )
    ''');
  }

  Future<int> insert(ExpenseItem expense) async {
    final db = await database;
    return db.insert(
      _tableName,
      expense.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseItem>> getAll() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'date DESC');
    return rows.map(ExpenseItem.fromMap).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
