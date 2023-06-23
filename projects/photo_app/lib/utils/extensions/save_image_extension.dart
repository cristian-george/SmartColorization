import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

import '../../enums.dart';
import '../shared_preferences.dart';

extension ShareImage on Uint8List {
  Future<void> save() async {
    int index = sharedPreferences.getInt('format')!;
    String format = ImageFormats.values[index].toString().split('.')[1];

    final tempDir = await getTemporaryDirectory();
    File file =
        await File('${tempDir.path}/${DateTime.now()}.$format').create();
    file.writeAsBytesSync(this);

    GallerySaver.saveImage(file.path, albumName: 'Pictures');
  }
}
