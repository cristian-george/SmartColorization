import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/photo_db_helper.dart';
import '../database/photo_model.dart';
import '../database/save_photo_extension.dart';
import '../utils/extensions/convert_image_to_grayscale_extension.dart';
import '../widgets/save_image_widget.dart';
import '../widgets/share_image_widget.dart';

import '../services/colorization_service.dart';
import '../utils/shared_preferences.dart';
import '../widgets/button_option_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/settings/dataset_list_widget.dart';

class AutomaticColorizationPage extends StatefulWidget {
  const AutomaticColorizationPage({
    Key? key,
    required this.imageData,
    required this.category,
  }) : super(key: key);

  final Uint8List imageData;
  final PhotoCategory category;

  @override
  State<AutomaticColorizationPage> createState() =>
      _AutomaticColorizationPageState();
}

class _AutomaticColorizationPageState extends State<AutomaticColorizationPage> {
  Uint8List? _originalImageData;
  Uint8List? _processedImageData;

  bool _isGrayscale = true;
  bool _isEyeShown = false;
  ColorizationStatus _colorizationStatus = ColorizationStatus.none;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();

    _originalImageData = widget.imageData.toGrayscale();
    ColorizationService.setInterpreter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Automatic Colorization',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () {
            if (_originalImageData != null && _processedImageData != null) {
              PhotoDbHelper.instance.savePhoto(
                  _originalImageData!, _processedImageData!, widget.category);
              Navigator.pop(context);
            }

            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _processedImageData == null
              ? IconButton(
                  onPressed: _chooseDataset,
                  tooltip: 'Choose dataset',
                  icon: const Icon(Icons.dataset),
                )
              : Row(
                  children: [
                    SaveImageWidget(
                      imageData: _processedImageData!,
                    ),
                    ShareImageWidget(
                      imageData: _processedImageData!,
                    ),
                  ],
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ImageWidget(
                  originalImageData: _originalImageData,
                  processedImageData: _processedImageData,
                  isEyeShown: _isEyeShown,
                ),
              ),
            ),
            if (_isGrayscale)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Divider(
                  height: 5,
                  color: Colors.grey,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isGrayscale &&
                      _colorizationStatus == ColorizationStatus.none)
                    ButtonOptionWidget(
                      text: 'Colorize image',
                      onSelected: () {
                        setState(() {
                          _colorizationStatus =
                              ColorizationStatus.preprocessing;
                        });
                      },
                    ),
                  if (_isGrayscale &&
                      _colorizationStatus != ColorizationStatus.none)
                    _colorizeImageLocal(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _chooseDataset() {
    showGeneralDialog(
        context: context,
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            const DatasetPopup(title: "Colorize...")).then((value) {
      ColorizationService.setInterpreter();
    });
  }

  _colorizeImageLocal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (_colorizationStatus == ColorizationStatus.preprocessing)
          FutureBuilder(
            future: compute(
              ColorizationService.preprocessingImage,
              _originalImageData!,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              } else {
                {
                  _status = snapshot.data;
                  _status = ColorizationService.runModel(_status);

                  _colorizationStatus = ColorizationStatus.postprocessing;

                  return Container();
                }
              }
            },
          ),
        if (_colorizationStatus == ColorizationStatus.postprocessing)
          FutureBuilder(
            future: compute(
              ColorizationService.postprocessingImage,
              _status,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              } else {
                {
                  _isGrayscale = false;
                  _isEyeShown = true;
                  _colorizationStatus = ColorizationStatus.none;
                  _processedImageData = snapshot.data;

                  return Container();
                }
              }
            },
          )
      ],
    );
  }

  void _colorizeImageOnline() async {
    final map = {
      'image': base64Encode(_originalImageData!),
      'dataset': sharedPreferences.getInt('dataset')!,
    };

    var response = await http.post(
      Uri.parse('http://10.146.1.114:5000/automatic_colorization'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(map),
    );

    setState(() {
      _processedImageData = response.bodyBytes;
      _isGrayscale = false;
      _isEyeShown = true;
    });
  }
}
