import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../utils/extensions/save_image_extension.dart';

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
        imageData.save();

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
}
