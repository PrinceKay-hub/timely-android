
import 'package:booking/presentaion/screens/shop/cubit/my_listings_cubit.dart';
import 'package:booking/presentaion/screens/shop/sell_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:booking/data/models/product_model.dart';

// ─── Helpers ────────────────────────────────────────────────────────────
String _timeAgo(int ms) {
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
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyListingsCubit()..load(),
      child: const _MyListingsView(),
    );
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 48, color: colors.onSurfaceVariant),
                const SizedBox(height: 10),
                Text(
                  'Sign in to manage your listings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<MyListingsCubit, MyListingsState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) {
            // If we transition into failure, surface a snackbar.
            if (state.status == MyListingsStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Couldn't load your listings."),
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const _Header(),
                if (state.status == MyListingsStatus.success &&
                    state.listings.isNotEmpty)
                  _StatsRow(state: state),
                Expanded(child: _Body(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, size: 22, color: colors.onSurface),
          ),
          Expanded(
            child: Text(
              'My listings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          Material(
            color: colors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SellScreen(),)),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.add, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ──────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final MyListingsState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(child: _StatBox(label: 'Live', value: state.activeCount)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(label: 'Offline', value: state.offlineCount)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(label: 'Pending', value: state.pendingCount)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(label: 'Total views', value: state.totalViews)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Body (loading / error / empty / list) ─────────────────────────────
class _Body extends StatelessWidget {
  final MyListingsState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<MyListingsCubit>();

    switch (state.status) {
      case MyListingsStatus.idle:
      case MyListingsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case MyListingsStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Couldn't load your listings.",
                  style: TextStyle(
                      fontSize: 13, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => cubit.load(),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case MyListingsStatus.success:
        if (state.listings.isEmpty) {
          return _EmptyState(
            onCreate: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) => SellScreen()))
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          color: colors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: state.listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ListingCard(
              product: state.listings[i],
              isMutating:
                  state.mutatingId == state.listings[i].productId,
            ),
          ),
        );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              "You haven't listed anything yet.",
              style: TextStyle(
                  fontSize: 13, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sell your first product',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Listing card ───────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final Product product;
  final bool isMutating;

  const _ListingCard({required this.product, required this.isMutating});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categoryMeta = kCategories.firstWhere(
      (c) => c.id == product.category,
      orElse: () => kCategories.first,
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 78,
              height: 78,
              child: Image.network(
                product.thumbnailUrl.isNotEmpty
                    ? product.thumbnailUrl
                    : (product.images.isNotEmpty
                        ? product.images.first
                        : ''),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: colors.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: isMutating
                          ? null
                          : () => _showActionsSheet(context, product),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: isMutating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.more_vert,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.currency} ${_formatPrice(product.price)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatusBadge(status: product.status),
                    const SizedBox(width: 6),
                    Text(
                      '·',
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        categoryMeta.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 12, color: colors.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      '${product.viewCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _timeAgo(product.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge ───────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ProductStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case ProductStatus.offline:
        label = 'Offline';
        bg = colors.error.withOpacity(0.15);
        fg = colors.error;
        break;
      case ProductStatus.active:
        label = 'Live';
        bg = const Color(0xFF2E9E5B).withOpacity(0.12);
        fg = const Color(0xFF2E9E5B);
        break;
      case ProductStatus.pending:
        label = 'Pending';
        bg = const Color(0xFFD6C36F);
        fg = const Color(0xFFF9F2E3);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Action sheet ───────────────────────────────────────────────────────
void _showActionsSheet(BuildContext context, Product product) {
  final cubit = context.read<MyListingsCubit>();

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final colors = Theme.of(sheetCtx).colorScheme;
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Edit
              _SheetOption(
                icon: Icons.edit_outlined,
                label: 'Edit listing',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SellScreen(productId: product.productId,),));
                },
              ),

              // Toggle status
              _SheetOption(
                icon: product.status == ProductStatus.offline
                    ? Icons.refresh
                    : Icons.check_circle_outline,
                label: product.status == ProductStatus.offline
                    ? 'Relist as available'
                    : 'Mark as offline',
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final ok = await cubit.toggleStatus(product);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Couldn't update this listing. Try again."),
                      ),
                    );
                  }
                },
              ),

              // Delete
              _SheetOption(
                icon: Icons.delete_outline,
                label: 'Delete listing',
                color: colors.error,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _confirmDelete(context, cubit, product);
                },
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
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

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = color ?? colors.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(fontSize: 15, color: tint),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  MyListingsCubit cubit,
  Product product,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Delete this listing?'),
      content: Text('"${product.name}" will be removed permanently.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogCtx).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  final ok = await cubit.deleteListing(product);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't delete this listing. Try again."),
      ),
    );
  }
}