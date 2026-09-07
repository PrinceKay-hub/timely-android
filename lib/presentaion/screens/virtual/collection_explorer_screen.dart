import 'package:booking/core/services/hairstyle_service.dart';
import 'package:booking/data/models/timely_hairstyle.dart';
import 'package:booking/presentaion/screens/virtual/widgets/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum _ExplorerMode { collections, grid, viewer }

class CollectionsExplorerScreen extends StatefulWidget {
  const CollectionsExplorerScreen({super.key});

  @override
  State<CollectionsExplorerScreen> createState() =>
      _CollectionsExplorerScreenState();
}

class _CollectionsExplorerScreenState extends State<CollectionsExplorerScreen> {
  final _service = HairstyleService();
  final _pageController = PageController();

  List<Hairstyle> _hairstyles = [];
  bool _loading = true;
  String? _error;

  _ExplorerMode _mode = _ExplorerMode.collections;
  String? _activeCategory;
  int _viewerIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchAllHairstyles();
      if (!mounted) return;
      setState(() => _hairstyles = data);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = 'Could not load hairstyles. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _formatCategory(String category) {
    return category
        .split(RegExp(r'[_-]'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  List<HairstyleCollection> get _collections {
    final map = <String, List<Hairstyle>>{};
    for (final style in _hairstyles) {
      final key = style.category.isNotEmpty ? style.category : 'uncategorized';
      map.putIfAbsent(key, () => []).add(style);
    }
    final list = map.entries
        .map(
          (e) => HairstyleCollection(
            category: e.key,
            displayName: _formatCategory(e.key),
            coverImage: e.value.first.images.card,
            count: e.value.length,
            styles: e.value,
          ),
        )
        .toList();
    list.sort((a, b) => b.count.compareTo(a.count)); // biggest first
    return list;
  }

  HairstyleCollection? get _activeCollection {
    if (_activeCategory == null) return null;
    for (final c in _collections) {
      if (c.category == _activeCategory) return c;
    }
    return null;
  }

  void _openCollection(String category) {
    setState(() {
      _activeCategory = category;
      _mode = _ExplorerMode.grid;
    });
  }

  void _openViewer(int index) {
    setState(() {
      _viewerIndex = index;
      _mode = _ExplorerMode.viewer;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    });
  }

  void _goBack() {
    if (_mode == _ExplorerMode.viewer) {
      setState(() => _mode = _ExplorerMode.grid);
    } else if (_mode == _ExplorerMode.grid) {
      setState(() {
        _mode = _ExplorerMode.collections;
        _activeCategory = null;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 2,
              ),
              SizedBox(height: 10,),
              Text('Loading Hairstyles...')
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final headerTitle = switch (_mode) {
      _ExplorerMode.collections => 'Hairstyles',
      _ExplorerMode.grid => _activeCollection?.displayName ?? '',
      _ExplorerMode.viewer => '',
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          if (_mode != _ExplorerMode.viewer)
            _Header(title: headerTitle, colors: colors, onBack: _goBack),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppColors colors) {
    switch (_mode) {
      case _ExplorerMode.collections:
        return _CollectionsGrid(
          key: const ValueKey('collections'),
          collections: _collections,
          colors: colors,
          onTap: _openCollection,
        );
      case _ExplorerMode.grid:
        final collection = _activeCollection;
        if (collection == null) return const SizedBox.shrink();
        return _StyleGrid(
          key: ValueKey('grid-${collection.category}'),
          collection: collection,
          colors: colors,
          onTap: _openViewer,
        );
      case _ExplorerMode.viewer:
        final collection = _activeCollection;
        if (collection == null) return const SizedBox.shrink();
        return _ImageViewer(
          key: const ValueKey('viewer'),
          collection: collection,
          controller: _pageController,
          initialIndex: _viewerIndex,
          onIndexChanged: (i) => setState(() => _viewerIndex = i),
          onClose: _goBack,
        );
    }
  }
}

class _Header extends StatelessWidget {
  final String title;
  final AppColors colors;
  final VoidCallback onBack;
  const _Header({
    required this.title,
    required this.colors,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.of(context).padding.top + 12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, size: 20, color:Theme.of(context).primaryColor),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            width: 36,
          ), // balances the back button so the title stays centered
        ],
      ),
    );
  }
}

class _CollectionsGrid extends StatelessWidget {
  final List<HairstyleCollection> collections;
  final AppColors colors;
  final ValueChanged<String> onTap;
  const _CollectionsGrid({
    super.key,
    required this.collections,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 55),
      physics: BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1 / 1.2,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final item = collections[index];
        return GestureDetector(
          onTap: () => onTap(item.category),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.coverImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: colors.surface),
                  errorWidget: (_, __, ___) => Container(color: colors.surface),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.black.withOpacity(0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.count} styles',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StyleGrid extends StatelessWidget {
  final HairstyleCollection collection;
  final AppColors colors;
  final ValueChanged<int> onTap;
  const _StyleGrid({
    super.key,
    required this.collection,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 55),
      physics: BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: collection.styles.length,
      itemBuilder: (context, index) {
        final style = collection.styles[index];
        return GestureDetector(
          onTap: () => onTap(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: style.images.thumb,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: colors.surface),
              errorWidget: (_, __, ___) => Container(color: colors.surface),
            ),
          ),
        );
      },
    );
  }
}

class _ImageViewer extends StatefulWidget {
  final HairstyleCollection collection;
  final PageController controller;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onClose;

  const _ImageViewer({
    super.key,
    required this.collection,
    required this.controller,
    required this.initialIndex,
    required this.onIndexChanged,
    required this.onClose,
  });

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late int _index = widget.initialIndex;
  bool _isZoomed = false; // drives PageView physics

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: widget.controller,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : null,
            itemCount: widget.collection.styles.length,
            onPageChanged: (i) {
              setState(() {
                _index = i;
                _isZoomed = false; // reset lock when landing on a fresh page
              });
              widget.onIndexChanged(i);
            },
            itemBuilder: (context, i) {
              final style = widget.collection.styles[i];
              return _ZoomableImage(
                key: ValueKey(style.id ?? i),
                imageUrl: style.images.full,
                placeholderUrl: style.images.card,
                onZoomChanged: (zoomed) {
                  // Only let the currently active page control PageView's
                  // physics — a neighboring pre-built page shouldn't matter.
                  if (i == _index && zoomed != _isZoomed) {
                    setState(() => _isZoomed = zoomed);
                  }
                },
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                color: Colors.black.withOpacity(0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.collection.styles[_index].name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_index + 1} of ${widget.collection.styles.length} · ${widget.collection.displayName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single full-screen image that supports pinch-to-zoom and
/// double-tap-to-zoom, and reports its zoom state so the parent PageView
/// can disable swipe-to-change-page while zoomed in.
class _ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final String placeholderUrl;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomableImage({
    super.key,
    required this.imageUrl,
    required this.placeholderUrl,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapZoomScale = 2.5;

  late final TransformationController _controller;
  late final AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_onAnimTick);
    _controller.addListener(_onTransformChanged);
  }

  void _onAnimTick() {
    if (_zoomAnimation != null) {
      _controller.value = _zoomAnimation!.value;
    }
  }

  void _onTransformChanged() {
    final zoomedNow = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomedNow != _isZoomed) {
      _isZoomed = zoomedNow;
      widget.onZoomChanged(zoomedNow);
    }
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final currentScale = _controller.value.getMaxScaleOnAxis();

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
      begin: _controller.value,
      end: endMatrix,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(_animController),
    );

    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
    _controller.dispose();
    _animController.removeListener(_onAnimTick);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        panEnabled: true,
        minScale: 1,
        maxScale: 4,
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.contain,
          // low-res card image shows instantly while the full image loads
          placeholder: (_, __) => CachedNetworkImage(
            imageUrl: widget.placeholderUrl,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 48),
            ),
          ),
          errorWidget: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}