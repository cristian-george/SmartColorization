import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_app/utils/filter_utils.dart';
import 'package:photofilters/filters/filters.dart';

import 'filtered_image_widget.dart';

class FilteredImageListWidget extends StatelessWidget {
  final List<Filter> filters;
  final img.Image image;
  final ValueChanged<Filter> onChangedFilter;

  const FilteredImageListWidget({
    Key? key,
    required this.filters,
    required this.image,
    required this.onChangedFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];

          return InkWell(
            onTap: () {
              if (FilterUtils.getCachedFilter(filter) != null) {
                onChangedFilter(filter);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilteredImageWidget(
                    filter: filter,
                    image: image,
                    successBuilder: (imageBytes) => CircleAvatar(
                      radius: 50,
                      backgroundImage: MemoryImage(
                        Uint8List.fromList(imageBytes),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    errorBuilder: () => const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.report, size: 32),
                    ),
                    loadingBuilder: () => const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filter.name,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
