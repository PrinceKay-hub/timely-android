import 'package:flutter/material.dart';

class TimelyLandingPage extends StatelessWidget {
  const TimelyLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: Theme.of(
                  context,
                ).colorScheme.primary,
              ),
            ),
          ),
        ),
        title: Text(
          'Timely',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero / Introduction
            Text(
              'Timely',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Timely makes booking appointments effortless – whether you\'re looking for a haircut, spa treatment, or professional service, Timely connects you with trusted providers in your area.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // For Customers
            _buildSectionTitle(context, 'For Customers'),
            const SizedBox(height: 8),
            Text(
              'Finding and booking services has never been easier. Browse providers, check real‑time availability, and secure your appointment in seconds – anytime, anywhere.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // For Service Providers
            _buildSectionTitle(context, 'For Service Providers'),
            const SizedBox(height: 8),
            Text(
              'Take control of your business with powerful tools designed to help you grow. Manage your calendar, track appointments, and build lasting relationships with your clients.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Why You'll Love Timely
            _buildSectionTitle(context, '✨ Why You\'ll Love Timely'),
            const SizedBox(height: 12),
            _buildFeatureItem(
              context,
              icon: Icons.search,
              title: 'Discover Great Providers',
              description:
                  'Browse through vetted service professionals in your area. View photos, read reviews, and compare services to find the perfect match for your needs.',
            ),
            _buildFeatureItem(
              context,
              icon: Icons.calendar_today,
              title: 'Book Instantly',
              description:
                  'No phone calls, no waiting. See real‑time availability and book your appointment immediately. Reschedule or cancel with just a few taps.',
            ),
            _buildFeatureItem(
              context,
              icon: Icons.map,
              title: 'Find Your Way',
              description:
                  'Never get lost. Get turn‑by‑turn directions to your appointment location using integrated Google Maps. Your provider\'s exact location is saved and ready to guide you.',
            ),
            _buildFeatureItem(
              context,
              icon: Icons.notifications,
              title: 'Smart Reminders',
              description:
                  'Receive timely notifications about upcoming appointments so you never miss a booking. Both customers and providers stay in sync.',
            ),
            const SizedBox(height: 16),

            // For Service Providers – Expanded
            _buildSectionTitle(context, '👥 For Service Providers'),
            const SizedBox(height: 8),
            _buildSubSectionTitle(context, 'Grow Your Business'),
            _buildBulletList([
              'Set your working hours and manage availability',
              'Accept bookings 24/7 – even while you sleep',
              'Reduce no‑shows with automated reminders',
            ]),
            const SizedBox(height: 12),
            _buildSubSectionTitle(context, 'Simplify Operations'),
            _buildBulletList([
              'Easy calendar management',
              'Client history and notes at your fingertips',
              'Track earnings and business performance',
            ]),
            const SizedBox(height: 12),
            _buildSubSectionTitle(context, 'Professional Presence'),
            _buildBulletList([
              'Create your custom service listings',
              'Upload photos of your work',
              'Build your reputation with customer reviews',
            ]),
            const SizedBox(height: 24),

            // Trusted by Users
            _buildSectionTitle(context, '⭐ Trusted by Users'),
            const SizedBox(height: 8),
            _buildQuote(
              context,
              '"Timely has completely transformed how I run my business. Clients can book at any time, whether it\'s in the middle of the night or during my busiest workday. It\'s so much more than a booking system – it\'s become an essential part of my business."',
              '– Selina, Beauty Specialist',
            ),
            const SizedBox(height: 12),
            _buildQuote(
              context,
              '"I love being able to make appointments on the go, anytime, anywhere. The automated messages hugely reduce our no‑shows."',
              '– Tracy Antwi, Salon Owner',
            ),
            const SizedBox(height: 24),

            // Privacy Matters
            _buildSectionTitle(context, '🔒 Your Privacy Matters'),
            const SizedBox(height: 8),
            Text(
              'We take your data seriously:',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildBulletList([
              'Location data is only used to help you find and navigate to services',
              'All data is encrypted in transit',
              'You can request deletion of your data anytime',
              'No data shared with third parties without your consent',
            ]),
            const SizedBox(height: 8),
            Text(
              'View our Privacy Policy | Terms of Service',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 24),

            // Download / Call to action
            _buildSectionTitle(context, '📲 Download Timely Today'),
            const SizedBox(height: 8),
            Text(
              'Join thousands of users who\'ve simplified their booking experience. Whether you\'re booking a service or running a business, Timely helps you stay organized and stress‑free.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                'Get started with a 30‑day free trial for providers',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Info
            _buildSectionTitle(context, 'App Info'),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Updated:', 'February 26, 2026'),
            _buildInfoRow(context, 'Version:', '1.0.0'),
            _buildInfoRow(context, 'Requires Android:', '8.0 or higher'),
            _buildInfoRow(context, 'Price:', 'Free (in‑app purchases available)'),
            _buildInfoRow(context, 'Developer:', 'Enorince Technologies Ltd.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSubSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(child: Text(item)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuote(BuildContext context, String quote, String attribution) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            attribution,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}