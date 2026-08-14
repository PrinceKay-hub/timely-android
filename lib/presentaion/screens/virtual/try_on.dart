import 'package:booking/presentaion/screens/virtual/virtual_try_on_screen.dart';
import 'package:booking/presentaion/screens/virtual/widgets/app_colors.dart';
import 'package:booking/presentaion/screens/virtual/collection_explorer_screen.dart';
import 'package:flutter/material.dart';

const double _gridGap = 16;
const double _hPadding = 24;

class MenuItemData {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final WidgetBuilder builder; // 👈 was: final String route;

  const MenuItemData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.builder,
  });
}

class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Add a third or fourth entry here and the grid adapts on its own —
    // same intent as MENU_ITEMS in the RN version.
    final items = <MenuItemData>[
      MenuItemData(
        key: 'tryOn',
        title: 'Virtual Try-On',
        subtitle: 'See yourself in any style',
        icon: Icons.auto_fix_high,
        accent: Theme.of(context).primaryColor,
        accentSoft: Theme.of(context).primaryColor.withOpacity(0.2),
        builder: (context) => const VirtualTryOnScreen(), // adjust if this should point elsewhere
      ),
      MenuItemData(
        key: 'styles',
        title: 'Hairstyles',
        subtitle: 'Browse 1,000+ styles',
        icon: Icons.content_cut,
        accent: Colors.blue,
        accentSoft: Colors.lightBlueAccent.withOpacity(0.2),
        builder: (context) => const CollectionsExplorerScreen(), // swap in your actual feed screen widget/class name
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _hPadding,
            vertical: 32,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Try-On',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: colors.text,
                ),
              ),
              Text(
                'Find your perfect look today',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              _SignatureRule(colors: colors),
              const SizedBox(height: 24),
              Expanded(
                child: _MenuGrid(items: items),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignatureRule extends StatelessWidget {
  final AppColors colors;
  const _SignatureRule({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 32,
        height: 3,
        child: Row(
          children: [
            Expanded(child: Container(color: Theme.of(context).primaryColor)),
            Expanded(child: Container(color: Colors.lightBlueAccent)),
          ],
        ),
      ),
    );
  }
}

/// Adaptive grid: 2 items get a prominent, taller pair; 3+ wrap as a
/// squarer grid — same rule as MenuGrid.tsx (`items.length <= 2`).
class _MenuGrid extends StatelessWidget {
  final List<MenuItemData> items;
  const _MenuGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - _hPadding * 2 - _gridGap) / 2;
    final tall = items.length <= 2;

    return Wrap(
      spacing: _gridGap,
      runSpacing: _gridGap,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return SizedBox(
          width: cardWidth,
          height: tall ? cardWidth * 1.35 : cardWidth,
          child: _MenuCard(
            item: item,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: item.builder),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final MenuItemData item;
  final VoidCallback onTap;
  const _MenuCard({required this.item, required this.onTap});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = widget.item;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: item.accentSoft,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onHighlightChanged: (isHighlighted) {
            if (!isHighlighted) setState(() => _pressed = false);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.05),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.accentSoft,
                    border: Border.all(color: item.accent, width: 1.5),
                  ),
                  child: Icon(item.icon, size: 26, color: item.accent),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.accent,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: item.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}