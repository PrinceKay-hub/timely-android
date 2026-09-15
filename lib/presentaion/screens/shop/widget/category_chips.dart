import 'package:flutter/material.dart';

import 'package:booking/data/models/product_model.dart';

/// A horizontal, scrollable row of category filter chips.
///
/// [selected] == null means "All categories".
class CategoryChips extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelect;

  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            active: selected == null,
            onPress: () => onSelect(null),
          ),
          ...kCategories.map(
            (c) => _Chip(
              label: c.label,
              active: selected == c.id,
              // Tapping the active chip clears the filter,
              // matching the toggle behavior in SearchScreen.
              onPress: () => onSelect(selected == c.id ? null : c.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPress;

  const _Chip({
    required this.label,
    required this.active,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}