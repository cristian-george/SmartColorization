import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../database/photo_db_helper.dart';
import '../database/photo_model.dart';

extension SavePhoto on PhotoDbHelper {
  savePhoto(
      Uint8List original, Uint8List processed, PhotoCategory category) async {
    final date = DateTime.now();
    final dir = await getApplicationDocumentsDirectory();

    String originalImagePath = '${dir.path}/${date}_original.jpg';
    File originalImageFile = await File(originalImagePath).create();
    originalImageFile.writeAsBytesSync(original);

    String processedImagePath = '${dir.path}/${date}_processed.jpg';
    File processedImageFile = await File(processedImagePath).create();
    processedImageFile.writeAsBytesSync(processed);

    PhotoModel photo = PhotoModel(
      id: 1,
      timestamp: date.millisecondsSinceEpoch,
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath,
      category: category,
    );

    PhotoDbHelper.instance.createPhoto(photo);
  }
}
