import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GalleryWidget extends StatefulWidget {
  const GalleryWidget({
    super.key,
    required this.images,
    required this.index,
  });
  final List images;
  final int index;

  @override
  State<StatefulWidget> createState() => _GalleryWidgetState();
}

class _GalleryWidgetState extends State<GalleryWidget>
    with TickerProviderStateMixin {
  late PageController pageController;
  late TransformationController controller;
  late AnimationController animationController;
  Animation<Matrix4>? _zoomAnimation;

  static const double _doubleTapZoomScale = 2.5;
  TapDownDetails? _doubleTapDetails;

  Offset _offset = Offset.zero;
  double _opacity = 1.0;
  AnimationController? _returnController;
  late int count;
  double _rotationAngle = 0.0;

  bool _isZoomed = false; // NEW: drives PageView physics

  @override
  void initState() {
    super.initState();

    pageController = PageController(initialPage: widget.index);
    count = widget.index + 1;
    controller = TransformationController();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    animationController.addListener(_onZoomAnimationTick);

    // NEW: react to any transformation change, including pinch gestures
    // driven internally by InteractiveViewer.
    controller.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final zoomedNow = controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomedNow != _isZoomed) {
      setState(() {
        _isZoomed = zoomedNow;
      });
    }
  }

  void _onZoomAnimationTick() {
    if (_zoomAnimation != null) {
      controller.value = _zoomAnimation!.value;
    }
  }

  void _rotateImage() {
    setState(() {
      // Rotate by 90 degrees (π/2 radians) on each press
      _rotationAngle += pi / 2;
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final currentScale = controller.value.getMaxScaleOnAxis();

    Matrix4 endMatrix;
    if (currentScale > 1.01) {
      // Already zoomed in -> zoom back out to fit
      endMatrix = Matrix4.identity();
    } else {
      // Zoom in, centered on the tap position
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      endMatrix = Matrix4.identity()
        ..translate(
          -position.dx * (_doubleTapZoomScale - 1),
          -position.dy * (_doubleTapZoomScale - 1),
        )
        ..scale(_doubleTapZoomScale);
    }

    _zoomAnimation = Matrix4Tween(
      begin: controller.value,
      end: endMatrix,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(animationController),
    );

    animationController.forward(from: 0);
  }

    @override
    void dispose() {
      pageController.dispose();
      controller.removeListener(_onTransformationChanged);
      controller.dispose();
      animationController.removeListener(_onZoomAnimationTick);
      animationController.dispose();
      _returnController?.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
            const SizedBox(width: 5),
            const Text(
              '/',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
            const SizedBox(width: 5),
            Text(
              '${widget.images.length}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _rotateImage,
            icon: const Icon(Icons.rotate_right, color: Colors.white),
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: pageController,
        // Disable page swiping while zoomed in so vertical/horizontal
        // pan gestures on the zoomed image don't fight the PageView.
        physics: _isZoomed ? const NeverScrollableScrollPhysics() : null,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            count = index + 1;
          });
        },
        itemBuilder: (context, index) {
          final imageUrl = widget.images[index];
          return Transform.translate(
            offset: _offset,
            child: GestureDetector(
              onVerticalDragStart: (_) => _cancelReturnAnimation(),
              onVerticalDragUpdate: (details) => _handleDragUpdate(details),
              onVerticalDragEnd: _handleDragEnd,
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black),
                child: InteractiveViewer(
                  transformationController: controller,
                  panEnabled: true,
                  minScale: 1,
                  maxScale: 4,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Builder(builder: (context) {
                      final mq = MediaQuery.of(context);
                      final cacheWidth =
                          (mq.size.width * mq.devicePixelRatio * 2).round();

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        child: Transform.rotate(
                          angle: _rotationAngle,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            memCacheWidth: cacheWidth,
                            progressIndicatorBuilder:
                                (context, url, progress) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorWidget: (context, url, error) =>
                                const Center(
                              child: Icon(Icons.error, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

    void _handleDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return; // don't dismiss-drag while zoomed in

    final double newDy = _offset.dy + details.delta.dy;

    if (details.delta.dy < 0 && _offset.dy <= 0) {
      return;
    }

    setState(() {
      _offset = Offset(0, newDy);
      _opacity = (1 - newDy.clamp(0, 300) / 300).clamp(0.4, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails _) {
    if (_offset.dy < 0) {
      _animateBackToPosition(Offset.zero, 1.0);
      return;
    }

    if (_offset.dy > 100) {
      Navigator.pop(context);
      return;
    }

    _animateBackToPosition(Offset.zero, 1.0);
  }

  void _animateBackToPosition(Offset targetOffset, double targetOpacity) {
    _returnController?.dispose();
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final offsetTween = Tween<Offset>(begin: _offset, end: targetOffset);
    final opacityTween = Tween<double>(begin: _opacity, end: targetOpacity);

    _returnController!.addListener(() {
      setState(() {
        _offset = offsetTween.evaluate(_returnController!);
        _opacity = opacityTween.evaluate(_returnController!);
      });
    });

    _returnController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _returnController?.dispose();
        _returnController = null;
      }
    });

    _returnController!.forward();
  }

  void _cancelReturnAnimation() {
    _returnController?.stop();
    _returnController = null;
  }
}