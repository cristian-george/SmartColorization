import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/extensions/share_image_extension.dart';

class ShareImageWidget extends StatelessWidget {
  const ShareImageWidget({
    Key? key,
    required this.imageData,
  }) : super(key: key);

  final Uint8List imageData;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        imageData.share();
      },
      tooltip: 'Share image',
      icon: const Icon(Icons.ios_share),
    );
  }
}
