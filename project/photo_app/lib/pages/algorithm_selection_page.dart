import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_app/pages/user_guided_colorization_page.dart';
import 'package:photo_app/utils/convolution_filters.dart';

import '../utils/color_filters.dart';
import '../widgets/button_option_widget.dart';
import '../widgets/image_widget.dart';
import 'automatic_colorization_page.dart';
import 'image_filters_page.dart';

class AlgorithmSelectionPage extends StatefulWidget {
  const AlgorithmSelectionPage({Key? key, required this.imageData})
      : super(key: key);

  final Uint8List imageData;

  @override
  State<AlgorithmSelectionPage> createState() => _AlgorithmSelectionPageState();
}

class _AlgorithmSelectionPageState extends State<AlgorithmSelectionPage>
    with SingleTickerProviderStateMixin {
  Uint8List? _originalImageData;
  Uint8List? _croppedImageData;

  bool _isCropped = false;

  @override
  void initState() {
    super.initState();

    _originalImageData = widget.imageData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Algorithm Selection',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _cropImage,
            tooltip: 'Crop',
            icon: const Icon(Icons.crop),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: ImageWidget(
                      originalImageData:
                          !_isCropped ? _originalImageData : _croppedImageData,
                      processedImageData: null,
                      isEyeShown: false,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Divider(
                    height: 5,
                    color: Colors.grey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ButtonOptionWidget(
                          text: 'Automatic Image Colorization',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AutomaticColorizationPage(
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                ),
                              ),
                            );
                          },
                        ),
                        ButtonOptionWidget(
                          text: 'User Guided Image Colorization',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserGuidedColorizationPage(
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                ),
                              ),
                            );
                          },
                        ),
                        ButtonOptionWidget(
                          text: 'Image Color Filters',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageFiltersPage(
                                  title: 'Image Color Filters',
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                  filters: colorFilters,
                                ),
                              ),
                            );
                          },
                        ),
                        ButtonOptionWidget(
                          text: 'Image Convolution Filters',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageFiltersPage(
                                  title: 'Image Convolution Filters',
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                  filters: convolutionFilters,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    _isCropped = false;
    _croppedImageData = _originalImageData;

    final tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/image.jpg').create();
    file.writeAsBytesSync(_originalImageData!);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          activeControlsWidgetColor: Colors.green,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
      ],
    );

    if (croppedFile != null) {
      _isCropped = true;
      _croppedImageData = await croppedFile.readAsBytes();
    }

    setState(() {});
  }
}
