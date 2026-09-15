import 'package:booking/presentaion/screens/shop/cubit/shop_cubit.dart';
import 'package:booking/presentaion/screens/shop/shop_search_screen.dart';
import 'package:booking/presentaion/screens/shop/widget/category_chips.dart';
import 'package:booking/presentaion/screens/shop/widget/product_card.dart';
import 'package:booking/presentaion/screens/shop/widget/sell_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShopCubit()..load(),
      child: const _ShopView(),
    );
  }
}

class _ShopView extends StatefulWidget {
  const _ShopView();

  @override
  State<_ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<_ShopView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.6) {
      context.read<ShopCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: const SellFAB(),
      body: Column(
        children: [
          _Header(primaryColor: colors.primary),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: BlocBuilder<ShopCubit, ShopState>(
              buildWhen: (p, c) => p.category != c.category,
              builder: (context, state) => CategoryChips(
                selected: state.category,
                onSelect: (category) =>
                    context.read<ShopCubit>().setCategory(category),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ShopCubit, ShopState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  );
                }

                if (state.isEmpty) {
                  return _EmptyState(color: colors.onSurfaceVariant);
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<ShopCubit>().refresh(),
                  color: colors.primary,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount:
                        state.products.length + (state.loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.products.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(
                                color: colors.primary),
                          ),
                        );
                      }
                      return ProductCard(product: state.products[index]);
                    },
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

class _Header extends StatelessWidget {
  final Color primaryColor;
  const _Header({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Shop',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.2),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShopSearchScreen(),)),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                    child: Text('🔍', style: TextStyle(fontSize: 18))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color color;
  const _EmptyState({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              'No products yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to list something in this category.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ],
        ),
      ),
    );
  }
}