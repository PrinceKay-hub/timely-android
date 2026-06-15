import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

// Onboarding Screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Discover Top Salons',
      description:
          'Find the best hair salons, barbershops, and beauty studios near you with verified reviews and ratings.',
      icon: Icons.search,
      color: Color(0xFF8B5CF6),
      illustration: 'search',
    ),
    OnboardingData(
      title: 'Book Appointments',
      description:
          'Schedule your appointments instantly with real-time availability. No more waiting on calls or uncertain bookings.',
      icon: Icons.calendar_today,
      color: Color(0xFF06B6D4),
      illustration: 'calendar',
    ),
    OnboardingData(
      title: 'Expert Stylists',
      description:
          'Choose from experienced professionals, view their portfolios, and read authentic customer reviews.',
      icon: Icons.people,
      color: Color(0xFFEC4899),
      illustration: 'stylist',
    ),
    OnboardingData(
      title: 'Get Started',
      description:
          'Your perfect look is just a tap away. Join thousands of satisfied customers today!',
      icon: Icons.star,
      color: Color(0xFFF59E0B),
      illustration: 'success',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    // Navigate to authentication
    context.go('/app');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerRight,
                child: _currentPage < _pages.length - 1
                    ? TextButton(
                        onPressed: _skipOnboarding,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // Indicators and Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _pages.length - 1
                                ? 'Next'
                                : 'Get Started',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          _buildIllustration(data),
          
          const SizedBox(height: 40),

          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: data.color,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(OnboardingData data) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - _pages.indexOf(data);
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }

        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: _buildIllustrationContent(data),
          ),
        );
      },
    );
  }

  Widget _buildIllustrationContent(OnboardingData data) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: 30,
            right: 30,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 40,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 30,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Icon
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.color.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),

          // Floating elements based on illustration type
          if (data.illustration == 'search') ...[
            _buildFloatingElement(
              top: 40,
              left: 50,
              icon: Icons.location_on,
              color: data.color,
              delay: 0,
            ),
            _buildFloatingElement(
              bottom: 60,
              right: 50,
              icon: Icons.star,
              color: data.color,
              delay: 200,
            ),
          ],
          if (data.illustration == 'calendar') ...[
            _buildFloatingElement(
              top: 50,
              right: 40,
              icon: Icons.check_circle,
              color: data.color,
              delay: 0,
            ),
            _buildFloatingElement(
              bottom: 70,
              left: 50,
              icon: Icons.access_time,
              color: data.color,
              delay: 200,
            ),
          ],
          if (data.illustration == 'stylist') ...[
            _buildFloatingElement(
              top: 60,
              left: 40,
              icon: Icons.content_cut,
              color: data.color,
              delay: 0,
            ),
            _buildFloatingElement(
              bottom: 60,
              right: 40,
              icon: Icons.brush,
              color: data.color,
              delay: 200,
            ),
          ],
          if (data.illustration == 'success') ...[
            _buildFloatingElement(
              top: 50,
              right: 50,
              icon: Icons.favorite,
              color: data.color,
              delay: 0,
            ),
            _buildFloatingElement(
              bottom: 70,
              left: 40,
              icon: Icons.thumb_up,
              color: data.color,
              delay: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingElement({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 800 + delay),
        curve: Curves.elasticOut,
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: Transform.rotate(
              angle: math.sin(value * math.pi) * 0.1,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _pages[_currentPage].color
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String illustration;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.illustration,
  });
}
