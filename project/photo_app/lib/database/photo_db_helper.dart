import 'package:photo_app/database/database_connection.dart';
import 'package:sqflite/sqflite.dart';

import 'photo_model.dart';

const tablePhoto = 'photo';
const columnId = 'id';
const columnTimestamp = 'timestamp';
const columnPath = 'path';
const columnCategory = 'category';

class PhotoDbHelper {
  PhotoDbHelper._();

  static final instance = PhotoDbHelper._();

  Database? _database;

  Database get database {
    if (_database == null) {
      _database = DatabaseConnection.database;
      _createTable();
    }

    return _database!;
  }

  Future<void> _createTable() async => await database.execute('''
    create table if not exists $tablePhoto (
      $columnId integer primary key autoincrement not null,
      $columnTimestamp integer not null,
      $columnPath text not null,
      $columnCategory integer not null)
    ''');

  Future<int> createPhoto(PhotoModel photoModel) async =>
      await database.insert(tablePhoto, photoModel.toMap());

  Future<List<PhotoModel>> readPhotos(
      {PhotoCategory? category, String? orderBy}) async {
    List<PhotoModel> photos = [];
    final result = await database.query(
      tablePhoto,
      orderBy: '$columnTimestamp $orderBy',
      where: category != null ? '$columnCategory = ?' : null,
      whereArgs: category != null ? [category.index] : null,
    );

    for (final element in result) {
      final photoModel = PhotoModel.fromMap(element);
      photos.add(photoModel);
    }

    return photos;
  }

  Future<int> deletePhoto(int id) async =>
      await database.delete(tablePhoto, where: 'id = ?', whereArgs: [id]);

  Future<int> deleteTable() async => await database.delete(tablePhoto);
}
