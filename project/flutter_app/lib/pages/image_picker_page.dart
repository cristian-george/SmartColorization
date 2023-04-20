import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../colorization_service.dart';
import '../image_provider_data.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key});

  @override
  ImagePickerWidgetState createState() => ImagePickerWidgetState();
}

class ImagePickerWidgetState extends State<ImagePickerWidget> {
  final _picker = ImagePicker();

  late TransformationController _controller;
  TapDownDetails? _tapDownDetails;

  @override
  void initState() {
    super.initState();

    _controller = TransformationController();
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: context.watch<ImageProviderData>().imageData == null
                ? const Text('No image selected.')
                : GestureDetector(
                    onDoubleTapDown: (details) {
                      _tapDownDetails = details;
                    },
                    onDoubleTap: () {
                      final position = _tapDownDetails!.localPosition;

                      const double scale = 3;
                      final x = -position.dx * (scale - 1);
                      final y = -position.dy * (scale - 1);
                      final zoomed = Matrix4.identity()
                        ..translate(x, y)
                        ..scale(scale);

                      final value = _controller.value.isIdentity()
                          ? zoomed
                          : Matrix4.identity();
                      _controller.value = value;
                    },
                    child: InteractiveViewer(
                        clipBehavior: Clip.none,
                        panEnabled: false,
                        scaleEnabled: false,
                        transformationController: _controller,
                        child: Image.memory(
                            context.watch<ImageProviderData>().imageData!)),
                  ),
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
