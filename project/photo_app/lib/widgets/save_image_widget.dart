import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../enums.dart';
import '../utils/shared_preferences.dart';

class SaveImageWidget extends StatelessWidget {
  const SaveImageWidget({
    Key? key,
    required this.imageData,
  }) : super(key: key);

  final Uint8List imageData;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        _saveImageToGallery();

        Fluttertoast.showToast(
            msg: "Image saved!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            textColor: Colors.white,
            backgroundColor: Colors.black.withOpacity(0.75),
            fontSize: 16);
      },
      tooltip: 'Save image',
      icon: const Icon(Icons.save_alt_outlined),
    );
  }

  Future<void> _saveImageToGallery() async {
    int index = sharedPreferences.getInt('format')!;
    String format = ImageFormats.values[index].toString().split('.')[1];

    final tempDir = await getTemporaryDirectory();
    File file =
        await File('${tempDir.path}/${DateTime.now()}.$format').create();
    file.writeAsBytesSync(imageData);

    GallerySaver.saveImage(file.path, albumName: 'Pictures');
  }
}
