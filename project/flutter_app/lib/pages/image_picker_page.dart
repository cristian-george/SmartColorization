import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../colorization_service.dart';
import '../image_provider_data.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: context.watch<ImageProviderData>().imageData == null
                ? const Text('No image selected.')
                : Image.memory(context.watch<ImageProviderData>().imageData!),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  Uint8List imageData = await pickedFile.readAsBytes();

                  if (mounted) {
                    context.read<ImageProviderData>().setImageData(imageData);
                  }
                }
              },
              child: const Text('Pick an Image'),
            ),
            if (context.watch<ImageProviderData>().isGrayscale)
              ElevatedButton(
                onPressed: () async {
                  Uint8List colorizedImageData =
                      await ColorizationService.colorizeImage(
                          context.read<ImageProviderData>().imageData!);
                  if (mounted) {
                    context
                        .read<ImageProviderData>()
                        .setImageData(colorizedImageData);
                  }
                },
                child: const Text('Colorize Image'),
              ),
            if (context.watch<ImageProviderData>().imageData != null &&
                !context.watch<ImageProviderData>().isGrayscale)
              ElevatedButton(
                onPressed: () async {
                  Uint8List grayscaleImageData =
                      await ColorizationService.grayscaleImage(
                          context.read<ImageProviderData>().imageData!);
                  if (mounted) {
                    context
                        .read<ImageProviderData>()
                        .setImageData(grayscaleImageData);
                  }
                },
                child: const Text('Convert to Grayscale Image'),
              ),
          ],
        ),
      ],
    );
  }
}
