// ─────────────────────────────────────────────────────────────────────────
// product_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:booking/presentaion/common/pages/gallery_widget.dart';
import 'package:booking/presentaion/screens/shop/cubit/detail_cubit.dart';
import 'package:booking/presentaion/screens/shop/cubit/detail_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:booking/data/models/product_model.dart';
// import your chat router / chat store equivalent here
// import your GalleryWidget equivalent here

const double _screenPadding = 16;

// ─── Helpers ────────────────────────────────────────────────────────────
String timeAgo(int ms) {
  if (ms == 0) return '';
  final seconds = (DateTime.now().millisecondsSinceEpoch - ms) ~/ 1000;
  if (seconds < 60) return 'Just now';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';
  final days = hours ~/ 24;
  if (days < 7) return '${days}d ago';
  final weeks = days ~/ 7;
  if (weeks < 5) return '${weeks}w ago';
  final months = days ~/ 30;
  if (months < 12) return '${months}mo ago';
  return '${days ~/ 365}y ago';
}

String formatViewCount(int count) {
  if (count < 1000) return '$count';
  if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '${count ~/ 1000}k';
}

String _formatPrice(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final intPart = abs.truncate();                    // int, not double
  final hasFraction = abs - intPart > 0;

  // Digit grouping on the integer part.
  final digits = intPart.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }

  final sign = isNegative ? '-' : '';
  if (!hasFraction) return '$sign$buf';

  final decimals = ((abs - intPart) * 100)
      .round()
      .toString()
      .padLeft(2, '0');
  return '$sign$buf.$decimals';
}

// ─── Entry ──────────────────────────────────────────────────────────────
class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(productId: productId)..load(),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        if (state.loading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final product = state.product;
        if (product == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "This listing isn't available anymore.",
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Go back',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        final isOwnListing = uid == product.sellerId;
        final isSoldOut = product.status == ProductStatus.offline;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Column(
            children: [
              Expanded(
                child: _Body(
                  product: product,
                  state: state,
                  isOwnListing: isOwnListing,
                  isSoldOut: isSoldOut,
                ),
              ),
              if (!isOwnListing)
                _ContactFooter(
                  product: product,
                  isSoldOut: isSoldOut,
                  isOpeningChat: state.isOpeningChat,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Body ───────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final Product product;
  final ProductDetailState state;
  final bool isOwnListing;
  final bool isSoldOut;

  const _Body({
    required this.product,
    required this.state,
    required this.isOwnListing,
    required this.isSoldOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    final categoryMeta = kCategories.firstWhere(
      (c) => c.id == product.category,
      orElse: () => kCategories.first,
    );
    final contactLabel = product.contact.isNotEmpty
        ? 'Call Now'
        : 'Message seller';

    final loc = product.location;
    final locationLine = loc != null
        ? [loc.district, loc.region].where((s) => s.isNotEmpty).join(', ')
        : null;

    return CustomScrollView(
      slivers: [
        // ─── Image carousel with floating header ────────────────
        SliverToBoxAdapter(
          child: _ImageSection(
            product: product,
            activeImage: state.activeImage,
            width: width,
          ),
        ),

        // ─── Content ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            //margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(_screenPadding),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOwnListing) ...[
                  _OwnListingBanner(),
                  const SizedBox(height: 12),
                ],

                // Name + price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.currency} ${_formatPrice(product.price)}',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stats
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 13,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${formatViewCount(product.viewCount)} views',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '·',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo(product.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Category + delivery pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        categoryMeta.label,
                        style: TextStyle(fontSize: 12, color: colors.onSurface),
                      ),
                    ),
                    if (product.isDelivery)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F8EF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 13,
                              color: Color(0xFF2E9E5B),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Delivery available',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2E9E5B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                if (locationLine != null && locationLine.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locationLine,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                              if (loc?.landmark != null &&
                                  loc!.landmark!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Near ${loc.landmark}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Description
                if (product.description.isNotEmpty) ...[
                  _SectionLabel('Description'),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.46,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],

                // Tags
                if (product.tags.isNotEmpty) ...[
                  _SectionLabel('Tags'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ─── Related products ────────────────────────────────────
        if (state.relatedLoading || state.relatedProducts.isNotEmpty)
          SliverToBoxAdapter(child: _RelatedSection(state: state)),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─── Image section (carousel + floating header) ────────────────────────
class _ImageSection extends StatefulWidget {
  final Product product;
  final int activeImage;
  final double width;

  const _ImageSection({
    required this.product,
    required this.activeImage,
    required this.width,
  });

  @override
  State<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<_ImageSection> {
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: widget.activeImage);
  }

  @override
  void didUpdateWidget(covariant _ImageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeImage != widget.activeImage &&
        _pageCtrl.hasClients &&
        _pageCtrl.page?.round() != widget.activeImage) {
      _pageCtrl.jumpToPage(widget.activeImage);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final p = widget.product;
    final url = 'https://timelygh.com/shop/${p.productId}';
    await Share.share(
      '${p.name} — ${p.currency} ${_formatPrice(p.price)}: $url',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<ProductDetailCubit>();
    final images = widget.product.images;

    return SizedBox(
      height: widget.width,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: cubit.setActiveImage,
            itemBuilder: (_, i) {
              final uri = images.isEmpty ? '' : images[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GalleryWidget(images: images, index: i),
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: uri,
                  width: widget.width,
                  height: widget.width,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      ColoredBox(color: colors.surfaceContainerHighest),
                ),
              );
            },
          ),

          // Floating header
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FloatingIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _FloatingIconButton(icon: Icons.share_outlined, onTap: _share),
              ],
            ),
          ),

          // Image counter
          if (images.length > 1)
            Positioned(
              bottom: 25,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.activeImage + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: colors.onSurface),
        ),
      ),
    );
  }
}

// ─── Small bits ────────────────────────────────────────────────────────
class _OwnListingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            'This is your listing',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─── Related products ───────────────────────────────────────────────────
class _RelatedSection extends StatelessWidget {
  final ProductDetailState state;
  const _RelatedSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _screenPadding),
            child: Text(
              'You might also like',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (state.relatedLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _screenPadding),
                itemCount: state.relatedProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final item = state.relatedProducts[i];
                  return SizedBox(
                    width: 130,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(productId: item.productId),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 130,
                              height: 100,
                              child: Image.network(
                                item.thumbnailUrl.isNotEmpty
                                    ? item.thumbnailUrl
                                    : (item.images.isNotEmpty
                                          ? item.images.first
                                          : ''),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: colors.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${item.currency} ${_formatPrice(item.price)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Contact footer ─────────────────────────────────────────────────────
class _ContactFooter extends StatelessWidget {
  final Product product;
  final bool isSoldOut;
  final bool isOpeningChat;

  const _ContactFooter({
    required this.product,
    required this.isSoldOut,
    required this.isOpeningChat,
  });

  Future<void> _handleContact(BuildContext context) async {
    if (product.contact.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: product.contact);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cannot make a call')));
      }
    } else {
      await _handleMessage(context);
    }
  }

  Future<void> _handleMessage(BuildContext context) async {
    // TODO: wire up your chat store equivalent.
    // Example:
    //   final chatId = await ChatRepository.getOrCreateChat(...);
    //   Navigator.pushNamed(context, '/chats/$chatId');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat is not configured yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = product.contact.isNotEmpty ? 'Call Now' : 'Message seller';

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colors.outlineVariant, width: 0.5),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSoldOut ? null : () => _handleContact(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSoldOut ? colors.outlineVariant : colors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOpeningChat)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  product.contact.isNotEmpty
                      ? Icons.phone
                      : Icons.chat_bubble_outline,
                  size: 18,
                  color: Colors.white,
                ),
              const SizedBox(width: 8),
              Text(
                isSoldOut ? 'No longer available' : label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
