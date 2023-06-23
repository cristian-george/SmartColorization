import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../enums.dart';
import '../shared_preferences.dart';

extension ShareImage on Uint8List {
  Future<void> share() async {
    int index = sharedPreferences.getInt('format')!;
    String format = ImageFormats.values[index].toString().split('.')[1];

    final tempDir = await getTemporaryDirectory();
    File file =
        await File('${tempDir.path}/${DateTime.now()}.$format').create();
    file.writeAsBytesSync(this);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'This photo was edited using Photo Editor application!',
    );
  }
}
