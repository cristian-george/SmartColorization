import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_app/database/photo_model.dart';
import 'package:photo_app/utils/extensions/save_photo_extension.dart';
import 'package:photo_app/utils/filter_utils.dart';
import 'package:photo_app/widgets/image_widget.dart';
import 'package:photofilters/filters/filters.dart';
import 'package:image/image.dart' as img;

import '../database/photo_db_helper.dart';
import '../widgets/image_filters/filtered_image_list_widget.dart';
import '../widgets/image_filters/filtered_image_widget.dart';
import '../widgets/save_image_widget.dart';

class ImageFiltersPage extends StatefulWidget {
  const ImageFiltersPage({
    Key? key,
    required this.title,
    required this.imageData,
    required this.filters,
    required this.category,
  }) : super(key: key);

  final String title;
  final Uint8List imageData;
  final List<Filter> filters;
  final PhotoCategory category;

  @override
  State<ImageFiltersPage> createState() => _ImageFiltersPageState();
}

class _ImageFiltersPageState extends State<ImageFiltersPage> {
  late img.Image _image;
  late Filter _filter;

  late Widget _filteredImageListWidget;

  @override
  void initState() {
    super.initState();

    FilterUtils.clearCache();
    _image = img.decodeImage(widget.imageData)!;
    _filter = widget.filters.first;

    _filteredImageListWidget = FilteredImageListWidget(
      filters: widget.filters,
      image: _image,
      onChangedFilter: (filter) {
        if (_filter != filter) {
          _filter = filter;

          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () {
            if (_filter != widget.filters.first) {
              PhotoDbHelper.instance.savePhoto(
                  widget.imageData,
                  Uint8List.fromList(FilterUtils.getCachedFilter(_filter)!),
                  widget.category);

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
          if (_filter != widget.filters.first)
            SaveImageWidget(
              imageData:
                  Uint8List.fromList(FilterUtils.getCachedFilter(_filter)!),
            ),
        ],
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
              child: Center(
                child: FilteredImageWidget(
                  filter: _filter,
                  image: _image,
                  successBuilder: (imageBytes) {
                    final image = Uint8List.fromList(imageBytes);

                    return ImageWidget(
                      originalImageData: widget.imageData,
                      processedImageData:
                          _filter != widget.filters.first ? image : null,
                      isEyeShown: _filter != widget.filters.first,
                    );
                  },
                  errorBuilder: () {
                    return Container();
                  },
                  loadingBuilder: () {
                    return const SizedBox(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(
              height: 5,
              color: Colors.grey,
            ),
            _filteredImageListWidget,
          ],
        ),
      ),
    );
  }
}
