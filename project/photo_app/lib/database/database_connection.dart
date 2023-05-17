import 'package:sqflite/sqflite.dart';

class DatabaseConnection {
  static late Database database;

  static initialize() async {
    final dir = await getDatabasesPath();
    final path = "$dir/database.db";

    database = await openDatabase(path, version: 2);
  }

  static deleteDatabase() async {
    final dir = await getDatabasesPath();
    final path = "$dir/database.db";

    databaseFactory.deleteDatabase(path);
  }
}
