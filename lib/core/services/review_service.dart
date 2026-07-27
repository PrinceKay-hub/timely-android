
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static const String _firstLaunchKey = 'first_launch_date';
  static const String _launchCountKey = 'launch_count';
  static const String _lastReviewDateKey = 'last_review_date';

  final InAppReview _inAppReview = InAppReview.instance;

  // Singleton
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  /// Call this when the app starts (e.g., in main or home screen initState)
  Future<void> onAppStart() async {
    final prefs = await SharedPreferences.getInstance();

    // Increment launch count
    int count = prefs.getInt(_launchCountKey) ?? 0;
    count++;
    await prefs.setInt(_launchCountKey, count);

    // Record first launch date if not exists
    if (!prefs.containsKey(_firstLaunchKey)) {
      await prefs.setString(_firstLaunchKey, DateTime.now().toIso8601String());
    }
  }

  /// Check if user is eligible and show review dialog
  Future<void> requestReviewIfEligible() async {
    if (!await _inAppReview.isAvailable()) {
      // Fallback: open store listing
      await _inAppReview.openStoreListing();
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // 1. Minimum launch count condition (e.g., 3 launches)
    final launchCount = prefs.getInt(_launchCountKey) ?? 0;
    if (launchCount < 3) return;

    // 2. Minimum time since first launch (e.g., 5 days)
    final firstLaunchStr = prefs.getString(_firstLaunchKey);
    if (firstLaunchStr != null) {
      final firstLaunch = DateTime.parse(firstLaunchStr);
      final daysSince = DateTime.now().difference(firstLaunch).inDays;
      if (daysSince < 5) return;
    }

    // 3. Cooldown: don't show again within 30 days after last review
    final lastReviewStr = prefs.getString(_lastReviewDateKey);
    if (lastReviewStr != null) {
      final lastReview = DateTime.parse(lastReviewStr);
      final daysSinceReview = DateTime.now().difference(lastReview).inDays;
      if (daysSinceReview < 30) return;
    }

    // All conditions met – show review popup
    try {
      await _inAppReview.requestReview();
      // Record that we showed the review
      await prefs.setString(_lastReviewDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      // If in-app review fails, fallback to store listing
      await _inAppReview.openStoreListing();
    }
  }
}