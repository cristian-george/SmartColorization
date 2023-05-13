import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_app/utils/filter_utils.dart';
import 'package:photo_app/widgets/filtered_image_widget.dart';
import 'package:photofilters/filters/filters.dart';
import 'package:photofilters/filters/preset_filters.dart';
import 'package:image/image.dart' as img;

import '../widgets/filtered_image_list_widget.dart';

class ImageFiltersPage extends StatefulWidget {
  const ImageFiltersPage({
    Key? key,
    required this.imageData,
  }) : super(key: key);

  final Uint8List imageData;

  @override
  State<ImageFiltersPage> createState() => _ImageFiltersPageState();
}

class _ImageFiltersPageState extends State<ImageFiltersPage> {
  late img.Image _image;
  Filter _filter = presetFiltersList.first;

  @override
  void initState() {
    super.initState();

    FilterUtils.clearCache();
    _image = img.decodeImage(widget.imageData)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Image Filters',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 20,
          left: 10,
          right: 10,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: FilteredImageWidget(
                      filter: _filter,
                      image: _image,
                      successBuilder: (imageBytes) {
                        Uint8List image = Uint8List.fromList(imageBytes);
                        return Image.memory(image);
                      },
                      errorBuilder: () {
                        return Container();
                      },
                      loadingBuilder: () {
                        return const SizedBox(
                          height: 400,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 5,
              color: Colors.grey,
            ),
            FilteredImageListWidget(
              filters: presetFiltersList,
              image: _image,
              onChangedFilter: (filter) {
                _filter = filter;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
