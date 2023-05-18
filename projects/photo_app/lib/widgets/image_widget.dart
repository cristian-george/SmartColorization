import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImageWidget extends StatefulWidget {
  const ImageWidget({
    Key? key,
    required this.originalImageData,
    required this.processedImageData,
    required this.isEyeShown,
  }) : super(key: key);

  final Uint8List? originalImageData;
  final Uint8List? processedImageData;
  final bool isEyeShown;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget>
    with SingleTickerProviderStateMixin {
  late TransformationController _controller;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  OverlayEntry? _entry;

  final double _minScale = 1;
  final double _maxScale = 4;

  late bool _isEyeShown;

  @override
  void initState() {
    super.initState();

    _isEyeShown = widget.isEyeShown;

    _controller = TransformationController();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() => _controller.value = _animation!.value)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _removeOverlay();
        }
      });
  }

  @override
  void didUpdateWidget(covariant ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    _isEyeShown = widget.isEyeShown;
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildImage(),
        if (widget.processedImageData != null)
          GestureDetector(
            onTapDown: (details) {
              setState(() {
                _isEyeShown = false;
              });
            },
            onTapUp: (details) {
              setState(() {
                _isEyeShown = true;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(2.5),
              color: Colors.black.withOpacity(0.5),
              child: Icon(
                _isEyeShown
                    ? Icons.remove_red_eye_outlined
                    : Icons.remove_red_eye_sharp,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    return Builder(
      builder: (context) => InteractiveViewer(
        clipBehavior: Clip.none,
        transformationController: _controller,
        panEnabled: false,
        minScale: _minScale,
        maxScale: _maxScale,
        onInteractionStart: (details) {
          if (details.pointerCount < 2) return;

          if (_entry == null) {
            _showOverlay(context);
          }
        },
        onInteractionEnd: (details) {
          if (details.pointerCount != 1) return;

          _resetAnimation();
        },
        child: Image.memory(
          !_isEyeShown ? widget.originalImageData! : widget.processedImageData!,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _resetAnimation() {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.forward(from: 0);
  }

  void _showOverlay(BuildContext context) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = MediaQuery.of(context).size;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.white),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              child: _buildImage(),
            ),
          ],
        );
      },
    );

    final overlay = Overlay.of(context);
    overlay.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }
}
