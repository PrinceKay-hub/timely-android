import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageViewerScreen extends StatefulWidget {
  final String heroTag;
  final String? imageUrl;
  final String? localImagePath;

  const ImageViewerScreen({
    Key? key,
    required this.heroTag,
    this.imageUrl,
    this.localImagePath,
  }) : super(key: key);

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  double _dragOffset = 0;
  double _backgroundOpacity = 1;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      final progress = (_dragOffset.abs() / 300).clamp(0.0, 1.0);
      _backgroundOpacity = 1 - progress;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 120) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _backgroundOpacity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.localImagePath != null
        ? Image.file(File(widget.localImagePath!), fit: BoxFit.contain)
        : CachedNetworkImage(
            imageUrl: widget.imageUrl!,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
          );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(_backgroundOpacity),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Center(
            child: Hero(
              tag: widget.heroTag,
              child: InteractiveViewer(minScale: 1, maxScale: 4, child: image),
            ),
          ),
        ),
      ),
    );
  }
}