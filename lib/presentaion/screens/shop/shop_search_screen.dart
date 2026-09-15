
import 'package:booking/presentaion/screens/shop/cubit/search_cubit.dart';
import 'package:booking/presentaion/screens/shop/widget/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:booking/data/models/product_model.dart';

const double _gridGap = 12;
const double _horizontalPadding = 16;

class ShopSearchScreen extends StatelessWidget {
  const ShopSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit()..loadCatalog(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // RN auto-focuses the input after 250ms.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _searchFocus.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) {
              // Keep controller in sync when state changes externally
              // (e.g. "apply recent search").
              if (_searchCtrl.text != state.searchText) {
                _searchCtrl.value = TextEditingValue(
                  text: state.searchText,
                  selection: TextSelection.collapsed(
                    offset: state.searchText.length,
                  ),
                );
              }
      
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    searchText: state.searchText,
                  ),
                  _CategoryGrid(selected: state.selectedCategory),
                  Expanded(child: _Body(state: state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Header (back + search bar) ────────────────────────────────────────
class _Header extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchText;

  const _Header({
    required this.controller,
    required this.focusNode,
    required this.searchText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<SearchCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: colors.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search products, tags...',
                        hintStyle: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search,
                      size: 20, color: colors.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: cubit.setSearchText,
                      onSubmitted: (v) {
                        cubit.commitSearch(v);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  if (searchText.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        cubit.clearSearchText();
                        controller.clear();
                      },
                      child: Icon(
                        Icons.cancel,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category chips ────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final ProductCategory? selected;
  const _CategoryGrid({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<SearchCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kCategories.map((c) {
          final isSelected = selected == c.id;
          return InkWell(
            onTap: () => cubit.toggleCategory(c.id),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(c.icon),
                    size: 18,
                    color: isSelected ? Colors.white : colors.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'hair-dryer':
        return Icons.air;
      case 'hand-back-right':
        return Icons.back_hand_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'content-cut':
        return Icons.content_cut;
      case 'toolbox':
        return Icons.handyman_outlined;
      case 'flower':
        return Icons.local_florist_outlined;
      case 'gift':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

// ─── Body ──────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final SearchState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.catalogStatus) {
      case SearchCatalogStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchCatalogStatus.failure:
        return _ErrorState(
          onRetry: () => context.read<SearchCubit>().loadCatalog(),
        );
      case SearchCatalogStatus.success:
        return state.isBrowsing
            ? _BrowseView(state: state)
            : _ResultsView(state: state);
    }
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load products.",
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
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
}

// ─── Browse (recent + trending) ────────────────────────────────────────
class _BrowseView extends StatelessWidget {
  final SearchState state;
  const _BrowseView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final colors = Theme.of(context).colorScheme;
    final trending = state.trending;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('Recent searches'),
                GestureDetector(
                  onTap: cubit.clearRecentSearches,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.recentSearches.map((term) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => cubit.applyRecentSearch(term),
                        child: Text(
                          term,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => cubit.removeRecentSearch(term),
                        child: Icon(
                          Icons.close,
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (trending.isNotEmpty) ...[
            const _SectionLabel('Trending now'),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 140,
                  child: ProductCard(product: trending[i]),
                ),
              ),
            ),
          ],
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
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// ─── Results (sort + grid) ─────────────────────────────────────────────
class _ResultsView extends StatelessWidget {
  final SearchState state;
  const _ResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final colors = Theme.of(context).colorScheme;
    final results = state.results;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${results.length} '
                '${results.length == 1 ? 'result' : 'results'}',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: SearchSort.values.map((opt) {
                    final selected = state.sortBy == opt;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => cubit.setSort(opt),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.onSurface
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Theme.of(context)
                                      .scaffoldBackgroundColor
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: colors.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No products match your search.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth -
                            _horizontalPadding * 2 -
                            _gridGap) /
                        2;
                    return GridView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                          _horizontalPadding, 0, _horizontalPadding, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: _gridGap,
                        mainAxisSpacing: _gridGap,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: results.length,
                      itemBuilder: (_, i) => ProductCard(product: results[i], cardWidth: cardWidth,),
                    );
                  },
                ),
        ),
      ],
    );
  }
}