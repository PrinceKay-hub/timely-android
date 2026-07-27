// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:booking/core/services/review_service.dart';
import 'package:booking/domain/entities/user_entity.dart';
import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/screens/favorite/favorite_screen.dart';
import 'package:booking/presentaion/screens/virtual/virtual_try_on_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:booking/presentaion/screens/appointments/appointments_screen.dart';
import 'package:booking/presentaion/screens/home/home_screen.dart';
import 'package:booking/presentaion/screens/profile/profile_screen.dart';
import 'package:booking/presentaion/user/cubit/user_cubit.dart';

// ---- Design tokens -------------------------------------------------------
class _NavColors {
  static const primaryStart = Color(0xFF7C3AED); // violet-600
  static const primaryEnd = Color(0xFF5B21B6); // violet-800
  static const accentGlow = Color(0xFFC084FC); // violet-300 glow
  static const inactive = Color(0xFF9CA3AF); // gray-400
  static const active = Color(0xFF5B21B6);
}

class HomeEntry extends StatefulWidget {
  final UserEntity? user;
  const HomeEntry({
    super.key,
    this.user,
  });

  @override
  State<HomeEntry> createState() => _HomeEntryState();
}

class _HomeEntryState extends State<HomeEntry> {
  late final userCubit = context.read<UserCubit>();

  var currentContentIndex = 0;
  Map<String, dynamic> user = {};

  static const _navItems = [
    _NavItemData(icon: FontAwesomeIcons.house, label: 'Home'),
    _NavItemData(icon: FontAwesomeIcons.heart, label: 'Favorites'),
    _NavItemData(icon: FontAwesomeIcons.wandMagicSparkles, label: 'Try on'),
    _NavItemData(icon: FontAwesomeIcons.calendar, label: 'Appointments'),
    _NavItemData(icon: FontAwesomeIcons.user, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    ReviewService().onAppStart();
    fetchHomeData();
  }

  fetchHomeData() async {
    userCubit.loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return LoadingScreen();
          }
      
          if (state is UserError) {
            return Scaffold(
              body: Center(child: Text('Error loading user: ${state.message}')),
            );
          }
      
          if (state is UserLoaded) {
            return Scaffold(
              extendBody: true,
              body: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: buildAppBodyContent(currentContentIndex, state.user),
              ),
              bottomNavigationBar: _ModernBottomNav(
                currentIndex: currentContentIndex,
                items: _navItems,
                onTap: (index) => setState(() => currentContentIndex = index),
              ),
            );
          }
      
          // Default fallback UI
          return Scaffold(
            body: Center(child: Text('No user data available')),
          );
        },
      ),
    );
  }

  Widget buildAppBodyContent(int index, Map<String, dynamic> user) {
    switch (index) {
      case 0:
        return HomeScreen(user: user);
      case 1:
        return FavoriteScreen(user: user);

      case 2:
        return VirtualTryOnScreen();

      case 3:
        return AppointmentsScreen(user: user);

      case 4:
        return ProfileScreen(user: user);

      default:
        return const HomeEntry();
    }
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

/// A modern bottom navigation bar with a floating, gradient "Try On" button
/// that pops above the bar to draw the eye.
class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  const _ModernBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  static const _tryOnIndex = 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bar background
          Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(items.length, (index) {
                if (index == _tryOnIndex) {
                  // Reserve space for the floating button.
                  return const SizedBox(width: 64);
                }
                return _NavIcon(
                  data: items[index],
                  selected: currentIndex == index,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),

          // Floating "Try on" button
          Positioned(
            bottom: 30,
            child: GestureDetector(
              onTap: () => onTap(_tryOnIndex),
              child: AnimatedScale(
                scale: currentIndex == _tryOnIndex ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _NavColors.primaryStart,
                            _NavColors.primaryEnd,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _NavColors.accentGlow.withOpacity(
                              currentIndex == _tryOnIndex ? 0.45 : 0.2,
                            ),
                            blurRadius: currentIndex == _tryOnIndex ? 18 : 14,
                            spreadRadius: currentIndex == _tryOnIndex ? 1.5 : 0,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.wandMagicSparkles,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try on',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: currentIndex == _tryOnIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _NavColors.active,
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

class _NavIcon extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _NavColors.active : _NavColors.inactive;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? _NavColors.active.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(data.icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}