import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
          'Terms and Conditions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and last updated
            Text(
              'Terms and Conditions for Timely Booking App',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: February 26, 2026',
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 32, thickness: 1),

            // 1. Introduction
            _buildSectionTitle(context, '1. Introduction'),
            _buildParagraph(
              context,
              'Welcome to Timely! These Terms and Conditions ("Terms", "Agreement") govern your use of the Timely mobile application (the "App") and the services provided through the App. The App is operated by [Your Company Name] ("we", "us", or "our").',
            ),
            _buildParagraph(
              context,
              'By accessing or using the App, you agree to be bound by these Terms. If you disagree with any part of the Terms, you may not access the App.',
            ),
            _buildParagraph(
              context,
              'The App connects users ("Customers") with service providers ("Providers") for booking various services. Both Customers and Providers are users of the App and must agree to these Terms.',
            ),
            const SizedBox(height: 16),

            // 2. Definitions
            _buildSectionTitle(context, '2. Definitions'),
            _buildBulletList([
              '"Customer" – an individual using the App to book services from Providers.',
              '"Provider" – a business or individual offering services through the App.',
              '"Service" – any service listed by a Provider and booked by a Customer via the App.',
              '"Booking" – a confirmed appointment for a Service between a Customer and a Provider.',
            ]),
            const SizedBox(height: 16),

            // 3. Account Registration
            _buildSectionTitle(context, '3. Account Registration'),
            _buildSubSectionTitle(context, '3.1 Eligibility'),
            _buildParagraph(
              context,
              'You must be at least 18 years old to use the App. By creating an account, you represent that you are at least 18 years of age.',
            ),
            _buildSubSectionTitle(context, '3.2 Account Responsibilities'),
            _buildParagraph(
              context,
              'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.',
            ),
            _buildSubSectionTitle(context, '3.3 Accuracy of Information'),
            _buildParagraph(
              context,
              'You agree to provide accurate, current, and complete information during registration and keep it updated. Providers, in particular, must ensure their business details, location, working hours, and service listings are correct.',
            ),
            const SizedBox(height: 16),

            // 4. Services and Bookings
            _buildSectionTitle(context, '4. Services and Bookings'),
            _buildSubSectionTitle(context, '4.1 Provider Listings'),
            _buildParagraph(
              context,
              'Providers may list their services, including descriptions, prices, duration, availability, and location. Providers are solely responsible for the accuracy and legality of their listings.',
            ),
            _buildSubSectionTitle(context, '4.2 Booking Process'),
            _buildParagraph(
              context,
              'Customers can browse Providers, select a service, choose an available date and time, and confirm a booking. A booking is confirmed when the Customer receives a confirmation notification through the App.',
            ),
            _buildSubSectionTitle(context, '4.3 Modifications and Cancellations by Customer'),
            _buildParagraph(
              context,
              'Customers may modify or cancel a booking through the App subject to the Provider\'s cancellation policy (see Section 6).',
            ),
            _buildSubSectionTitle(context, '4.4 Modifications by Provider'),
            _buildParagraph(
              context,
              'Providers may need to reschedule or cancel a booking due to unforeseen circumstances. In such cases, Providers must notify the Customer immediately through the App, and the Customer will be entitled to a full refund or the option to rebook.',
            ),
            const SizedBox(height: 16),

            // 5. Payments
            _buildSectionTitle(context, '5. Payments'),
            _buildSubSectionTitle(context, '5.1 Pricing'),
            _buildParagraph(
              context,
              'All prices are displayed in the local currency and include applicable taxes unless stated otherwise. Providers set their own prices.',
            ),
            _buildSubSectionTitle(context, '5.2 Payment Processing'),
            _buildParagraph(
              context,
              'Payments for bookings are processed through third-party payment processors integrated into the App. By making a payment, you agree to the terms of those processors. We do not store your payment details on our servers.',
            ),
            _buildSubSectionTitle(context, '5.3 Payment Authorization'),
            _buildParagraph(
              context,
              'When you confirm a booking, you authorize us to charge your selected payment method for the total amount of the booking.',
            ),
            _buildSubSectionTitle(context, '5.4 Payouts to Providers'),
            _buildParagraph(
              context,
              'Providers will receive payments for completed bookings, minus any applicable service fees, according to the payout schedule specified in their provider agreement. Payouts are processed through the same third-party payment processors.',
            ),
            const SizedBox(height: 16),

            // 6. Cancellations and Refunds
            _buildSectionTitle(context, '6. Cancellations and Refunds'),
            _buildSubSectionTitle(context, '6.1 Customer Cancellations'),
            _buildParagraph(
              context,
              'Each Provider may set their own cancellation policy (e.g., full refund if canceled 24 hours in advance, no refund for last-minute cancellations). The applicable policy will be displayed at the time of booking. If no policy is specified, the following default applies:',
            ),
            _buildBulletList([
              'Cancellation more than 24 hours before the appointment: full refund.',
              'Cancellation within 24 hours: 50% refund.',
              'No-show: no refund.',
            ]),
            _buildSubSectionTitle(context, '6.2 Provider Cancellations'),
            _buildParagraph(
              context,
              'If a Provider cancels a booking, the Customer will receive a full refund. We may also offer the Customer a credit or discount for future bookings.',
            ),
            _buildSubSectionTitle(context, '6.3 Disputes'),
            _buildParagraph(
              context,
              'If a Customer believes a refund is warranted due to poor service, they must contact us within 7 days after the appointment. We will mediate and may issue a partial or full refund at our discretion.',
            ),
            const SizedBox(height: 16),

            // 7. Provider Obligations
            _buildSectionTitle(context, '7. Provider Obligations'),
            _buildSubSectionTitle(context, '7.1 Quality of Service'),
            _buildParagraph(
              context,
              'Providers agree to deliver services with reasonable skill and care, in accordance with their listings and any industry standards.',
            ),
            _buildSubSectionTitle(context, '7.2 Compliance with Laws'),
            _buildParagraph(
              context,
              'Providers must comply with all applicable laws, regulations, and licensing requirements related to their services.',
            ),
            _buildSubSectionTitle(context, '7.3 Location Accuracy'),
            _buildParagraph(
              context,
              'Providers are responsible for ensuring their shop location (latitude/longitude) is accurate in the App to enable Customers to get correct directions.',
            ),
            _buildSubSectionTitle(context, '7.4 Professional Conduct'),
            _buildParagraph(
              context,
              'Providers must treat Customers with respect and maintain a safe environment. Harassment, discrimination, or any inappropriate behavior is strictly prohibited and will result in immediate termination of the Provider\'s account.',
            ),
            const SizedBox(height: 16),

            // 8. User Conduct
            _buildSectionTitle(context, '8. User Conduct'),
            _buildParagraph(context, 'All users agree not to:'),
            _buildBulletList([
              'Use the App for any illegal purpose.',
              'Harass, abuse, or harm another user.',
              'Impersonate any person or entity.',
              'Post false, misleading, or defamatory content.',
              'Attempt to gain unauthorized access to the App\'s systems.',
              'Use any automated means (bots, scrapers) to access the App.',
            ]),
            _buildParagraph(
              context,
              'Violation of these rules may result in suspension or termination of your account.',
            ),
            const SizedBox(height: 16),

            // 9. Intellectual Property
            _buildSectionTitle(context, '9. Intellectual Property'),
            _buildParagraph(
              context,
              'The App and its original content, features, and functionality are owned by [Your Company Name] and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws. You may not copy, modify, distribute, sell, or lease any part of the App without our prior written consent.',
            ),
            const SizedBox(height: 16),

            // 10. Third-Party Links and Services
            _buildSectionTitle(context, '10. Third-Party Links and Services'),
            _buildParagraph(
              context,
              'The App may contain links to third-party websites or services (e.g., Google Maps, payment processors). We are not responsible for the content or practices of these third parties. Your use of such services is at your own risk and subject to their terms.',
            ),
            const SizedBox(height: 16),

            // 11. Limitation of Liability
            _buildSectionTitle(context, '11. Limitation of Liability'),
            _buildParagraph(
              context,
              'To the maximum extent permitted by law, in no event shall [Your Company Name] be liable for any indirect, punitive, incidental, special, consequential damages, or loss of data, profits, or business opportunity arising out of or in connection with your use of the App or services booked through the App.',
            ),
            _buildParagraph(
              context,
              'We are a platform connecting Customers and Providers. We are not responsible for the quality, safety, or legality of services provided by Providers. Any dispute between a Customer and a Provider is solely between those parties.',
            ),
            _buildParagraph(
              context,
              'Our total liability to you for any claim arising from these Terms or your use of the App shall not exceed the amount you paid to us (if any) during the twelve months preceding the event giving rise to the liability.',
            ),
            const SizedBox(height: 16),

            // 12. Indemnification
            _buildSectionTitle(context, '12. Indemnification'),
            _buildParagraph(
              context,
              'You agree to indemnify and hold harmless [Your Company Name] and its officers, directors, employees, and agents from any claims, damages, liabilities, costs, or expenses (including legal fees) arising from your violation of these Terms, your misuse of the App, or your dispute with another user.',
            ),
            const SizedBox(height: 16),

            // 13. Termination
            _buildSectionTitle(context, '13. Termination'),
            _buildParagraph(
              context,
              'We may terminate or suspend your account immediately, without prior notice or liability, for any reason, including if you breach these Terms. Upon termination, your right to use the App will cease. You may delete your account at any time through the App settings.',
            ),
            const SizedBox(height: 16),

            // 14. Governing Law
            _buildSectionTitle(context, '14. Governing Law'),
            _buildParagraph(
              context,
              'These Terms shall be governed and construed in accordance with the laws of [Your Country/State], without regard to its conflict of law provisions. Any legal action or proceeding arising under these Terms will be brought exclusively in the courts located in [Your City/Region].',
            ),
            const SizedBox(height: 16),

            // 15. Dispute Resolution
            _buildSectionTitle(context, '15. Dispute Resolution'),
            _buildSubSectionTitle(context, '15.1 Informal Resolution'),
            _buildParagraph(
              context,
              'Before filing a claim, you agree to attempt to resolve any dispute informally by contacting us at disputes@timelyapp.com. We will attempt to resolve the dispute internally.',
            ),
            _buildSubSectionTitle(context, '15.2 Arbitration'),
            _buildParagraph(
              context,
              'If the dispute cannot be resolved informally, you agree that any dispute arising out of or relating to these Terms shall be finally settled by binding arbitration administered by [Arbitration Institution] in accordance with its rules. The arbitration shall take place in [Your City], and judgment on the award may be entered in any court having jurisdiction.',
            ),
            _buildSubSectionTitle(context, '15.3 Class Action Waiver'),
            _buildParagraph(
              context,
              'You agree to resolve disputes with us on an individual basis, and not as a plaintiff or class member in any purported class or representative proceeding.',
            ),
            const SizedBox(height: 16),

            // 16. Changes to Terms
            _buildSectionTitle(context, '16. Changes to Terms'),
            _buildParagraph(
              context,
              'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days\' notice prior to any new terms taking effect. By continuing to access or use the App after those revisions become effective, you agree to be bound by the revised Terms.',
            ),
            const SizedBox(height: 16),

            // 17. Contact Us
            _buildSectionTitle(context, '17. Contact Us'),
            _buildParagraph(
              context,
              'If you have any questions about these Terms, please contact us:',
            ),
            _buildParagraph(
              context,
              'By email: support@timelyapp.com\nBy phone: +233244038837\nBy mail: Airport Roundabout, Kumasi',
              isMonospaced: true,
            ),
            const SizedBox(height: 16),

            // 18. Miscellaneous
            _buildSectionTitle(context, '18. Miscellaneous'),
            _buildSubSectionTitle(context, '18.1 Entire Agreement'),
            _buildParagraph(
              context,
              'These Terms constitute the entire agreement between you and us regarding the use of the App.',
            ),
            _buildSubSectionTitle(context, '18.2 Severability'),
            _buildParagraph(
              context,
              'If any provision of these Terms is held to be unenforceable or invalid, that provision will be enforced to the maximum extent possible, and the remaining provisions will remain in full force and effect.',
            ),
            _buildSubSectionTitle(context, '18.3 Waiver'),
            _buildParagraph(
              context,
              'Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights.',
            ),
            const SizedBox(height: 24),

            // Last updated and footer note
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    'These Terms and Conditions were last updated on February 26, 2026.',
                    style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build section headings (h2)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface
            ),
      ),
    );
  }

  // Helper for sub-section headings (h3)
  Widget _buildSubSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface
            ),
      ),
    );
  }

  // Helper for paragraphs
  Widget _buildParagraph(BuildContext context, String text, {bool isMonospaced = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: isMonospaced
            ? const TextStyle(fontFamily: 'monospace', fontSize: 14)
            : Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  // Helper for bullet lists
  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
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
}