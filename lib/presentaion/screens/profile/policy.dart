import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Privacy Policy',
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
              'Privacy Policy for Timely Booking App',
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

            // Introduction
            _buildSectionTitle(context, 'Introduction'),
            _buildParagraph(
              context,
              'Welcome to Timely! This privacy policy describes how Timely ("we", "us", or "our") collects, uses, and discloses your personal information when you use our mobile booking application (the "App") and the services provided through the App.',
            ),
            _buildParagraph(
              context,
              'We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you use our App and tell you about your privacy rights and how the law protects you.',
            ),
            const SizedBox(height: 16),

            // 1. Important Information and Who We Are
            _buildSectionTitle(context, '1. Important Information and Who We Are'),
            _buildSubSectionTitle(context, '1.1 Purpose of This Privacy Policy'),
            _buildParagraph(
              context,
              'This privacy policy aims to give you information on how Timely collects and processes your personal data through your use of this App, including any data you may provide when you book services, register as a service provider, or contact us.',
            ),
            _buildSubSectionTitle(context, '1.2 Data Controller'),
            _buildParagraph(
              context,
              'Timely is the data controller and responsible for your personal data. If you have any questions about this privacy policy, please contact us at:',
            ),
            _buildParagraph(
              context,
              'Email: privacy@timelyapp.com\nAddress: Airport Roundabout, Kumasi - Ash.',
              isMonospaced: true,
            ),
            _buildSubSectionTitle(context, '1.3 Key Definitions'),
            _buildBulletList([
              'User: Any individual using the Timely app to book services',
              'Service Provider: Businesses or individuals offering services through the Timely platform',
              'Personal Data: Any information relating to an identified or identifiable natural person',
            ]),
            const SizedBox(height: 16),

            // 2. The Data We Collect About You
            _buildSectionTitle(context, '2. The Data We Collect About You'),
            _buildParagraph(
              context,
              'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:',
            ),
            _buildSubSectionTitle(context, '2.1 Information Collected From All Users'),
            _buildBulletList([
              'Identity Data: Includes first name, last name, username or similar identifier.',
              'Contact Data: Includes email address, telephone numbers, and billing addresses.',
              'Technical Data: Includes internet protocol (IP) address, your login data, browser type and version, time zone setting and location, operating system and platform, and other technology on the devices you use to access this App.',
              'Profile Data: Includes your username and password, bookings made by you, preferences, feedback, and survey responses.',
              'Usage Data: Includes information about how you use our App, products and services.',
              'Marketing and Communications Data: Includes your preferences in receiving marketing from us and our third parties and your communication preferences.',
            ]),
            _buildSubSectionTitle(context, '2.2 Location Data (Service Providers)'),
            _buildParagraph(
              context,
              'When you use the location features in our App as a service provider, we collect precise geolocation data (latitude and longitude coordinates) to:',
            ),
            _buildBulletList([
              'Set and save your shop location in our Firestore database',
              'Enable users to get directions to your location',
              'Provide location-based services',
            ]),
            _buildParagraph(
              context,
              'We collect this information only when you grant us permission to access your device\'s location. You can withdraw this permission at any time through your device settings.',
            ),
            _buildSubSectionTitle(context, '2.3 Information Collected From Service Providers'),
            _buildParagraph(
              context,
              'If you register as a service provider, we collect additional information including:',
            ),
            _buildBulletList([
              'Business name and address',
              'Working days and hours',
              'Service offerings and pricing',
              'Business images/photos',
              'Bank account or payment details (processed through third-party payment processors)',
            ]),
            _buildSubSectionTitle(context, '2.4 Information Collected From Users (Customers)'),
            _buildParagraph(
              context,
              'When you book services through our App, we collect:',
            ),
            _buildBulletList([
              'Your name and contact information',
              'Booking dates and times',
              'Service preferences',
              'Payment information (processed securely through third-party payment processors)',
            ]),
            _buildSubSectionTitle(context, '2.5 Information Collected Automatically'),
            _buildParagraph(
              context,
              'We automatically collect certain technical data when you visit our App, including:',
            ),
            _buildBulletList([
              'Device information (hardware model, operating system version)',
              'Unique device identifiers',
              'Mobile network information',
              'App usage statistics',
              'IP address',
            ]),
            _buildSubSectionTitle(context, '2.6 Third-Party Data Collection'),
            _buildParagraph(
              context,
              'We use third-party services that may collect information about you:',
            ),
            _buildBulletList([
              'Google Maps API: For location services and directions',
              'Firebase/Firestore: For data storage and authentication',
              'Analytics services: To understand how users interact with our App',
            ]),
            const SizedBox(height: 16),

            // Continue with other sections similarly...
            // For brevity, I'll add key remaining sections and then the table.

            // 3. How We Collect Your Personal Data
            _buildSectionTitle(context, '3. How We Collect Your Personal Data'),
            _buildSubSectionTitle(context, '3.1 Direct Interactions'),
            _buildParagraph(
              context,
              'You may give us your Identity, Contact, and Profile Data by filling in forms or by corresponding with us by phone, email, or otherwise. This includes personal data you provide when you:',
            ),
            _buildBulletList([
              'Create an account',
              'Book a service',
              'Register as a service provider',
              'Set your shop location',
              'Request marketing to be sent to you',
              'Give us feedback',
            ]),
            _buildSubSectionTitle(context, '3.2 Automated Technologies or Interactions'),
            _buildParagraph(
              context,
              'As you interact with our App, we automatically collect Technical Data about your equipment, browsing actions and patterns. We collect this personal data by using cookies and other similar technologies',
            ),
            
            _buildSubSectionTitle(context, '3.3 Third Parties or Publicly Available Sources'),
            _buildParagraph(
              context,
              'We may receive personal data about you from various third parties including:',
            ),
            _buildBulletList([
              'Technical Data from analytics providers',
              'Identity and Contact Data from social media platforms when you choose to connect your account',
            ]),

            // 4. How We Use Your Personal Data
            _buildSectionTitle(context, '4. How We Use Your Personal Data'),
            _buildSubSectionTitle(context, '4.1 For All Users'),
            _buildBulletList([
              'To register you as a new user',
              'To manage our relationship with you',
              'To enable you to use our booking services',
              'To administer and protect our business and this App',
              'To deliver relevant App content and measure effectiveness',
              'To use data analytics to improve our App, products, services, and user experience',
            ]),
            // ... etc.

            // 5. Cookies and Tracking Technologies
            _buildSectionTitle(context, '5. Cookies and Tracking Technologies'),
            _buildParagraph(
              context,
              'Our App uses cookies and similar tracking technologies to track activity on our App and hold certain information. Cookies are files with small amount of data which may include an anonymous unique identifier.',
            ),
            _buildSectionTitle(context, '6. How We Share Your Personal Data'),
            _buildSubSectionTitle(context, '6.1 Service Providers'),
            _buildParagraph(
              context,
              'We engage third-party service providers to facilitate our App, provide services on our behalf, or assist us in analyzing how our App is used. These third parties include:',
            ),
            _buildBulletList([
              'Cloud service providers (Firebase/Google Cloud Platform) to store your data',
              'Analytics providers to help us improve our App',
              'Map service providers (Google Maps) to provide location and direction services',
            ]),
            _buildSubSectionTitle(context, '6.2 Between Users and Service Providers'),
            _buildParagraph(
              context,
              'When you make a booking through our App, we share relevant booking information (name, contact details, booking time) with the service provider to facilitate the appointment.',
            ),
            _buildSubSectionTitle(context, '6.3 Legal Requirements'),
            _buildParagraph(
              context,
              'We may disclose your personal data if required to do so by law or in response to valid requests by public authorities (e.g., a court or government agency).',
            ),
            _buildSubSectionTitle(context, '6.4 With Your Consent'),
            _buildParagraph(
              context,
              'We may disclose your personal information for any other purpose with your explicit consent.',
            ),

            _buildSectionTitle(context, '7. International Data Transfers'),
            _buildParagraph(
              context,
              'Your information, including personal data, may be transferred to — and maintained on — computers located outside of your state, province, country or other governmental jurisdiction where the data protection laws may differ from those of your jurisdiction.',
            ),
            _buildParagraph(
              context,
              'If you are located outside Ghana and choose to provide information to us, please note that we transfer the data to Ghana and process it there.',
            ),
            _buildParagraph(
              context,
              'Your consent to this privacy policy followed by your submission of such information represents your agreement to that transfer.',
            ),

            _buildSectionTitle(context, '8. Data Security'),
            _buildSubSectionTitle(context, '16.1 Location Permission'),
            _buildParagraph(
              context,
              'We have implemented appropriate security measures to prevent your personal data from being accidentally lost, used, or accessed in an unauthorized way, altered, or disclosed. These measures include:',
            ),
            _buildBulletList([
              'Encryption of data in transit and at rest',
              'Regular security assessments',
              'Access controls and authentication procedures',
              'Secure data storage through Firebase/Firestore',
            ]),
            _buildParagraph(
              context,
              'We follow industry-standard practices to protect your personal information. However, no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal data, we cannot guarantee its absolute security.',
            ),

            _buildSectionTitle(context, '9. Data Retention'),
            _buildParagraph(
              context,
              'We will only retain your personal data for as long as necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements.',
            ),
            _buildSubSectionTitle(context, '9.1 Retention Periods'),
            
            _buildBulletList([
              'Account information: Retained for as long as you have an active account with us',
              'Booking records: Retained for 5 years to maintain booking history and for legal purposes',
              'Secure data storage through Firebase/Firestore',
            ]),


             _buildSectionTitle(context, '10. Your Legal Rights'),
      
      _buildSubSectionTitle(context, '10.1 Right to Access'),
      _buildParagraph(
        context,
        'You have the right to request access to your personal data (commonly known as a "data subject access request"). This enables you to receive a copy of the personal data we hold about you and to check that we are lawfully processing it.',
      ),

      _buildSubSectionTitle(context, '10.2 Right to Correction'),
      _buildParagraph(
        context,
        'You have the right to request correction of the personal data that we hold about you. This enables you to have any incomplete or inaccurate data we hold about you corrected.',
      ),

      _buildSubSectionTitle(context, '10.3 Right to Erasure (Right to be Forgotten)'),
      _buildParagraph(
        context,
        'You have the right to request erasure of your personal data where there is no good reason for us continuing to process it. This includes the right to ask us to delete or remove your personal data where you have exercised your right to object to processing.',
      ),

      _buildSubSectionTitle(context, '10.4 Right to Restrict Processing'),
      _buildParagraph(
        context,
        'You have the right to request restriction of processing of your personal data in certain circumstances.',
      ),

      _buildSubSectionTitle(context, '10.5 Right to Data Portability'),
      _buildParagraph(
        context,
        'You have the right to request that we transfer your personal data to you or to a third party in a structured, commonly used, machine-readable format.',
      ),

      _buildSubSectionTitle(context, '10.6 Right to Object'),
      _buildParagraph(
        context,
        'You have the right to object to processing of your personal data where we are relying on a legitimate interest and there is something about your particular situation which makes you want to object to processing on this ground.',
      ),

      _buildSubSectionTitle(context, '10.7 Right to Withdraw Consent'),
      _buildParagraph(
        context,
        'You have the right to withdraw your consent at any time where we are relying on consent to process your personal data. This includes withdrawing consent for location data collection.',
      ),

      _buildSubSectionTitle(context, '10.8 Account Deletion'),
      _buildParagraph(
        context,
        'You have the right to request deletion of your account at any time. You can do this by:',
      ),
      _buildBulletList([
        'Accessing your account settings within the App',
        'Contacting us directly at privacy@timelyapp.com',
      ]),
      _buildParagraph(
        context,
        'Upon account deletion, we will delete or anonymize your personal data, unless we need to retain certain information for legitimate business purposes or legal obligations.',
      ),

      // Section 11
      _buildSectionTitle(context, '11. Children\'s Privacy'),
      _buildParagraph(
        context,
        'Our App is not intended for children under the age of 13 (or 16 in certain jurisdictions). We do not knowingly collect personally identifiable information from children under 13. If you are a parent or guardian and you are aware that your child has provided us with personal data, please contact us. If we become aware that we have collected personal data from a child without verification of parental consent, we take steps to remove that information from our servers.',
      ),

      // Section 12
      _buildSectionTitle(context, '12. Third-Party Links and Services'),
      _buildParagraph(
        context,
        'Our App may contain links to other websites or services that are not operated by us. This privacy policy does not cover how those third parties process your information. We strongly advise you to review the privacy policy of every site or service you visit.',
      ),
      _buildParagraph(
        context,
        'We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.',
      ),

      // Section 13
      _buildSectionTitle(context, '13. Changes to This Privacy Policy'),
      _buildParagraph(
        context,
        'We may update our privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last updated" date at the top of this privacy policy.',
      ),
      _buildParagraph(
        context,
        'We will let you know via email and/or a prominent notice on our App prior to the change becoming effective. You are advised to review this privacy policy periodically for any changes. Changes to this privacy policy are effective when they are posted on this page.',
      ),

      // Section 14
      _buildSectionTitle(context, '14. Your California Privacy Rights (For California Residents)'),
      _buildParagraph(
        context,
        'If you are a California resident, you have specific rights under the California Consumer Privacy Act (CCPA) as amended by the California Privacy Rights Act (CPRA):',
      ),
      _buildBulletList([
        'Right to know what personal information we collect, use, disclose, and sell',
        'Right to request deletion of your personal information',
        'Right to opt-out of the sale or sharing of your personal information',
        'Right to correct inaccurate personal information',
        'Right to limit use and disclosure of sensitive personal information',
        'Right to non-discrimination for exercising your CCPA rights',
      ]),
      _buildParagraph(
        context,
        'We do not sell your personal information. To exercise your California privacy rights, please contact us using the information provided below.',
      ),

      // Section 15
      _buildSectionTitle(context, '15. Your GDPR Rights (For European Economic Area Residents)'),
      _buildParagraph(
        context,
        'If you are located in the European Economic Area (EEA), you have additional rights under the General Data Protection Regulation (GDPR):',
      ),
      _buildBulletList([
        'The right to lodge a complaint with a supervisory authority',
        'The right to be informed about any automated decision-making and profiling',
        'Additional information about international data transfers and safeguards',
      ]),
      _buildParagraph(
        context,
        'We process your data based on the legal bases outlined in Section 4.4 of this policy.',
      ),


            // 16. Specific App Permissions
            _buildSectionTitle(context, '16. Specific App Permissions'),
            _buildParagraph(
              context,
              'Our App requests access to your device\'s location:',
            ),
            _buildBulletList([
              'For service providers: To capture and save your shop location coordinates in Firestore',
              'For users: To provide accurate directions to service provider locations via Google Maps',
            ]),
            _buildParagraph(
              context,
              'We only access your location when you grant permission and for the specific purposes described. You can revoke this permission at any time through your device settings.',
            ),
            _buildSubSectionTitle(context, '16.2 Camera Permission'),
            _buildParagraph(
              context,
              'We may request camera access to allow you to:',
            ),
            _buildBulletList([
              'Upload profile photos',
              'Capture images of services or locations',
            ]),
            _buildSubSectionTitle(context, '16.3 Storage Permission'),
            _buildParagraph(
              context,
              'We may request storage access to:',
            ),
            _buildBulletList([
              'Save and upload images',
              'Cache app data for improved performance',
            ]),

            _buildSectionTitle(context, '17. Contact Us'),
            _buildParagraph(
              context,
              'If you have any questions about this privacy policy or our data practices, please contact us:',
            ),
            _buildBulletList([
              'By email: privacy@timelyapp.com',
              'By phone: +233244032237',
            ]),
            _buildSectionTitle(context, '18. Complaints'),
            _buildParagraph(
              context,
              'You have the right to make a complaint at any time to your local data protection authority. We would, however, appreciate the chance to deal with your concerns before you approach them, so please contact us in the first instance.',
            ),


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
                    'This privacy policy was last updated on February 26, 2026.',
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