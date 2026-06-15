import 'package:booking/data/models/portfolio_model.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_bloc.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    // Hide system UI for immersive experience
   // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /*void _toggleLike(int index) {

    
   /* setState(() {
      widget.portfolioItems[index].isLiked = !widget.portfolioItems[index].isLiked;
      if (widget.portfolioItems[index].isLiked) {
        widget.portfolioItems[index].likes++;
      } else {
        widget.portfolioItems[index].likes--;
      }
    });*/
  }*/

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
                    onPressed: () =>
                        context.read<PortfolioCubit>().loadPortfolio(widget.serviceId),
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
              _pageController.jumpToPage(_currentIndex);
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
                    return _buildPortfolioPage(portfolioItems[index]);
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
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
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

  Widget _buildPortfolioPage(PortfolioImage item) {
    final userId = _auth.currentUser!.uid;
    final isLiked = item.likes!.contains(userId);
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
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF8B5CF6),
                      ),
                    );
                  },
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
                  // Like Button
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
                  SizedBox(height: 24),

                  // Share Button
                 /*   _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    color: Colors.white,
                    onTap: () {
                      // Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Share functionality coming soon!'),
                          backgroundColor: Color(0xFF8B5CF6),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),

                  // Download Button
                _buildActionButton(
                    icon: Icons.download,
                    label: 'Save',
                    color: Colors.white,
                    onTap: () {
                      // Implement download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Image saved to gallery!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),*/
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
                  padding: EdgeInsets.all(16),
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
                          constraints: BoxConstraints(maxHeight: 100),
                          child: SingleChildScrollView(
                            child: Text(
                              item.caption,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 8),

                      // Tags
                     /* if (item.tags != null && item.tags!.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: item.tags!.map((tag) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF8B5CF6).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF8B5CF6).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 8),*/

                      // Date
                      Text(
                        formatDateDifference(item.createdAt),
                        //item.createdAt.toString(),
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
          Container(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
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
  // Convert UTC timestamp to local timezone
  final DateTime createdLocal = createdDate.toLocal();
  final DateTime nowLocal = DateTime.now();

  // Extract only the date parts (ignore time)
  final DateTime createdOnly = DateTime(createdLocal.year, createdLocal.month, createdLocal.day);
  final DateTime nowOnly = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

  // Calendar day difference
  final int dayDiff = nowOnly.difference(createdOnly).inDays;

  // For relative time strings (minutes, hours) we still use the full difference
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
