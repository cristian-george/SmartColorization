import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/automatic_colorization_local.dart';
import 'image_widget.dart';

class ColorizationImageWidget extends StatelessWidget {
  ColorizationImageWidget(
      {super.key,
      this.originalImageData,
      this.processedImageData,
      required this.isColoring,
      required this.isEyeShown,
      required this.onProcessedImage});

  final Uint8List? originalImageData;
  late Uint8List? processedImageData;

  bool isColoring;
  bool isEyeShown;

  Function(Uint8List) onProcessedImage;

  @override
  Widget build(BuildContext context) {
    return isColoring
        ? FutureBuilder(
            future: compute(
              AutomaticColorizationLocal.preprocessingImage,
              originalImageData!,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 5),
                        Text('Loading...'),
                      ],
                    ),
                  ),
                );
              } else {
                Map<String, dynamic> status = snapshot.data;
                status = AutomaticColorizationLocal.runModel(status);

                return FutureBuilder(
                  future: compute(
                    AutomaticColorizationLocal.postprocessingImage,
                    status,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 5),
                              Text('Almost done...'),
                            ],
                          ),
                        ),
                      );
                    } else {
                      isColoring = false;
                      isEyeShown = true;

                      processedImageData = snapshot.data!;
                      onProcessedImage(processedImageData!);

                      return ImageWidget(
                        originalImageData: originalImageData,
                        processedImageData: processedImageData,
                        isEyeShown: isEyeShown,
                      );
                    }
                  },
                );
              }
            },
          )
        : ImageWidget(
            originalImageData: originalImageData,
            processedImageData: processedImageData,
            isEyeShown: isEyeShown,
          );
  }
}
