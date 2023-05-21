import 'dart:typed_data';
import 'dart:ui';

extension ImageSize on Uint8List {
  Future<Size> getSize() async {
    final imageCodec = await instantiateImageCodec(this);
    final FrameInfo frameInfo = await imageCodec.getNextFrame();
    return Size(
      frameInfo.image.width.toDouble(),
      frameInfo.image.height.toDouble(),
    );
  }
}
