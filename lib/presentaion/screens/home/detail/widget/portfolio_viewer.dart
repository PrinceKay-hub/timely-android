import 'package:booking/data/models/portfolio_model.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_bloc.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PortfolioViewerScreen extends StatefulWidget {
  final String serviceId;
  final int initialIndex;

  const PortfolioViewerScreen({
    Key? key,
    required this.serviceId,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PortfolioViewerScreen> createState() => _PortfolioViewerScreenState();
}

class _PortfolioViewerScreenState extends State<PortfolioViewerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PortfolioError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<PortfolioCubit>()
                        .loadPortfolio(widget.serviceId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is PortfolioLoaded) {
            final portfolioItems = state.images;
            if (portfolioItems.isEmpty) {
              return const Center(
                child: Text(
                  'No portfolio images',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // Adjust current index if list shrunk (e.g., after deletion)
            if (_currentIndex >= portfolioItems.length) {
              _currentIndex = portfolioItems.length - 1;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _pageController.jumpToPage(_currentIndex);
              });
            }

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: portfolioItems.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPortfolioPage(context, portfolioItems[index]);
                  },
                ),
                // Close button
                SafeArea(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink(); // fallback
        },
      ),
    );
  }

  Widget _buildPortfolioPage(BuildContext context, PortfolioImage item) {
    final userId = _auth.currentUser!.uid;
    final isLiked = item.likes!.contains(userId);

    // Full-screen zoomable viewer (up to 4x) — cap the decode at ~2x
    // screen size so we're not decoding a full multi-thousand-pixel
    // camera photo, but still stay sharp when zoomed.
    final mq = MediaQuery.of(context);
    final cacheWidth = (mq.size.width * mq.devicePixelRatio * 2).round();

    return GestureDetector(
      onTap: () => setState(() => _showUI = !_showUI),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'portfolio_${item.id}',
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.contain,
                  memCacheWidth: cacheWidth,
                  fadeInDuration: const Duration(milliseconds: 150),
                  progressIndicatorBuilder: (context, url, progress) {
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.progress,
                        color: const Color(0xFF8B5CF6),
                      ),
                    );
                  },
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Gradient Overlay
          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

          // Right Action Buttons
          if (_showUI)
            Positioned(
              right: 12,
              bottom: 120,
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.favorite,
                    label: _formatCount(item.likes?.length ?? 0),
                    color: isLiked ? Colors.red : Colors.white,
                    onTap: () {
                      context
                          .read<PortfolioCubit>()
                          .toggleLike(widget.serviceId, item.id);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

          // Bottom Info Section
          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 80,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.serviceName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),

                      // Caption
                      if (item.caption.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: SingleChildScrollView(
                            child: Text(
                              item.caption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Date
                      Text(
                        formatDateDifference(item.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  String formatDateDifference(DateTime createdDate) {
    final DateTime createdLocal = createdDate.toLocal();
    final DateTime nowLocal = DateTime.now();

    final DateTime createdOnly =
        DateTime(createdLocal.year, createdLocal.month, createdLocal.day);
    final DateTime nowOnly =
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final int dayDiff = nowOnly.difference(createdOnly).inDays;
    final Duration diff = nowLocal.difference(createdLocal);

    if (diff.isNegative) {
      return "In the future";
    } else if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inHours < 1) {
      return "${diff.inMinutes} minutes ago";
    } else if (dayDiff == 0) {
      return "Today";
    } else if (dayDiff == 1) {
      return "Yesterday";
    } else if (dayDiff < 30) {
      return "$dayDiff days ago";
    } else if (dayDiff < 60) {
      return "1 month ago";
    } else if (dayDiff < 365) {
      final int months = (dayDiff / 30).floor();
      return "$months months ago";
    } else if (dayDiff < 730) {
      return "1 year ago";
    } else {
      final int years = (dayDiff / 365).floor();
      return "$years years ago";
    }
  }
}