
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GalleryWidget extends StatefulWidget {
  const GalleryWidget(
      {super.key,
      required this.images,
      required this.index,
      });
  final List images;
  final int index;

  @override
  State<StatefulWidget> createState() =>
      _GalleryWidgetState(images, index,);
}

class _GalleryWidgetState extends State<GalleryWidget>
    with SingleTickerProviderStateMixin {
  _GalleryWidgetState(this.images, this.index, );
  final List images;
  final int index;
  late PageController pageController;
  late TransformationController controller;
  late AnimationController animationController;
  Animation<Matrix4>? animation;
  
  Offset _offset = Offset.zero; // Tracks image position
  double _opacity = 1.0; // Background opacity
  AnimationController? _returnController; // Handles return animation
  var count = 0;
  double _rotationAngle = 0.0;


  @override
  void initState() {
    super.initState();

    pageController = PageController(initialPage: index);
    setState(() {
      count = index + 1;
    });
    controller = TransformationController();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  void _rotateImage() {

    setState(() {
      // Rotate by 90 degrees (π/2 radians) on each press
      _rotationAngle += pi / 2;
    });
  }

  @override
  void dispose() {
    controller.dispose();
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
              const SizedBox(
                width: 5,
              ),
              const Text(
                '/',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                '${images.length}',
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
              icon: const Icon(Icons.rotate_right, color: Colors.white,)
            )
          ],
          backgroundColor: Colors.black,
        ),
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            count = index + 1;
          });
          //print(index+1);
        },
        itemBuilder: (context, index) {
          final images = widget.images[index];
          return Transform.translate(
            offset: _offset,
            child: GestureDetector(
            onVerticalDragStart: (_) => _cancelReturnAnimation(),
              onVerticalDragUpdate: (details) => _handleDragUpdate(details),
              onVerticalDragEnd: _handleDragEnd,
              onTap: () => Navigator.pop(context),
            child: Container(
              decoration: const BoxDecoration(color: Colors.black),
              child: InteractiveViewer(
                transformationController: controller,
                panEnabled: false,
                minScale: 1,
                maxScale: 4,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Builder(builder: (context) {
                    int? cacheWidth, cacheHeight;
                    Size targetSize = const Size(800, 800);
                    const double originalImgAspectRatio = 1.7;
                    if (originalImgAspectRatio > 0) {
                      cacheHeight = targetSize.height.round();
                    } else {
                      cacheWidth = targetSize.width.round();
                    }
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      child: Transform.rotate(
                      angle: _rotationAngle,
                      child: CachedNetworkImage(
                      imageUrl: images,
                      fit: BoxFit.contain,
                      memCacheHeight: cacheHeight,
                      memCacheWidth: cacheWidth,
                      progressIndicatorBuilder: (context, url, progress) {
                        return const Center(child: CircularProgressIndicator());
                      },
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
  final double newDy = _offset.dy + details.delta.dy;
  
  // Block upward drag when at top position
  if (details.delta.dy < 0 && _offset.dy <= 0) {
    return; // Ignore upward drag
  }
  
  // Allow downward drag in all cases
  setState(() {
    _offset = Offset(0, newDy);
    _opacity = (1 - newDy.clamp(0, 300) / 300).clamp(0.4, 1.0);
  });
}

  void _handleDragEnd(DragEndDetails _) {
  // Snap back to top if dragged up from bottom
  if (_offset.dy < 0) {
    _animateBackToPosition(Offset.zero, 1.0);
    return;
  }
  
  // Dismiss if dragged beyond threshold
  if (_offset.dy > 100) {
    Navigator.pop(context);
    return;
  }
  
  // Animate back to top
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
    _returnController?.dispose();
    _returnController = null;
  }
}
