import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_app/database/photo_db_helper.dart';
import 'package:photo_app/database/photo_model.dart';
import 'package:photo_app/widgets/image_widget.dart';

import '../widgets/button_option_widget.dart';
import '../widgets/save_image_widget.dart';

class EditedImagesHistoryPage extends StatefulWidget {
  const EditedImagesHistoryPage({Key? key}) : super(key: key);

  @override
  State<EditedImagesHistoryPage> createState() =>
      _EditedImagesHistoryPageState();
}

class _EditedImagesHistoryPageState extends State<EditedImagesHistoryPage> {
  PhotoCategory? _currentCategory;
  bool _expandImage = false;

  Uint8List? _originalImageData;
  Uint8List? _processedImageData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Edited Images History',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () {
            if (!_expandImage) {
              Navigator.pop(context);
            } else {
              _expandImage = false;
              setState(() {});
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_expandImage)
            Row(
              children: [
                /*IconButton(
                  onPressed: () {},
                  tooltip: 'Delete image',
                  icon: const Icon(Icons.delete_outline),
                ),*/
                SaveImageWidget(
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
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _expandImage == false
                      ? FutureBuilder<List<PhotoModel>>(
                          future: PhotoDbHelper.instance.readPhotos(
                            category: _currentCategory,
                            orderBy: 'DESC',
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Text('Loading...'),
                              );
                            }

                            if (snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text('There are no images edited!'),
                              );
                            } else {
                              List<PhotoModel> originalPhotos = snapshot.data!
                                  .where((element) =>
                                      element.path.contains('original'))
                                  .toList();

                              List<PhotoModel> processedPhotos = snapshot.data!
                                  .where((element) =>
                                      element.path.contains('processed'))
                                  .toList();

                              return GridView.builder(
                                itemCount: processedPhotos.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                ),
                                itemBuilder: (context, index) {
                                  final originalPhoto = originalPhotos[index];
                                  final processedPhoto = processedPhotos[index];

                                  return Container(
                                    margin: const EdgeInsets.all(10.0),
                                    child: GestureDetector(
                                        onTap: () {
                                          _expandImage = true;
                                          _originalImageData =
                                              File(originalPhoto.path)
                                                  .readAsBytesSync();
                                          _processedImageData =
                                              File(processedPhoto.path)
                                                  .readAsBytesSync();
                                          setState(() {});
                                        },
                                        child: Image.file(
                                          File(processedPhoto.path),
                                          fit: BoxFit.cover,
                                        )),
                                  );
                                },
                              );
                            }
                          },
                        )
                      : Center(
                          child: ImageWidget(
                              originalImageData: _originalImageData,
                              processedImageData: _processedImageData,
                              isEyeShown: true),
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
                          text: 'All',
                          onSelected: () {
                            _currentCategory = null;
                            setState(() {});
                          },
                        ),
                        ButtonOptionWidget(
                          text: 'Automatic Image Colorization',
                          onSelected: () {
                            _currentCategory = PhotoCategory.automaticColorized;
                            setState(() {});
                          },
                        ),
                        ButtonOptionWidget(
                          text: 'User Guided Image Colorization',
                          onSelected: () {
                            _currentCategory = PhotoCategory.guidedColorized;
                            setState(() {});
                          },
                        ),
                        ButtonOptionWidget(
                          text: 'Image Color Filters',
                          onSelected: () {
                            _currentCategory = PhotoCategory.colorFiltered;
                            setState(() {});
                          },
                        ),
                        ButtonOptionWidget(
                          text: 'Image Convolution Filters',
                          onSelected: () {
                            _currentCategory = PhotoCategory.convFiltered;
                            setState(() {});
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
}
