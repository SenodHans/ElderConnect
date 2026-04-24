/// Privacy Policy screen for ElderConnect.
///
/// Full-page scrollable view presented when the user taps "Privacy Policy"
/// on the caretaker registration form.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      appBar: AppBar(
        backgroundColor: ElderColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: ElderColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ElderSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('Privacy Policy'),
            _subtitle('Last updated: April 2026'),
            const SizedBox(height: ElderSpacing.lg),

            _sectionTitle('1. Introduction'),
            _body(
              'ElderConnect ("we", "our", or "us") is committed to protecting '
              'the privacy and security of our users. This Privacy Policy '
              'explains how we collect, use, store, and share your information '
              'when you use our mobile application.',
            ),

            _sectionTitle('2. Information We Collect'),
            _body(
              'We collect the following types of information:\n\n'
              'Account Information: Name, email address, phone number, and '
              'password (caretakers) or PIN (elders) provided during registration.\n\n'
              'Profile Data: Profile photos, interests, and preferences you '
              'choose to share.\n\n'
              'Wellness Data: Mood logs, daily journal entries, game scores, '
              'and activity records created through your use of the app.\n\n'
              'Medication Data: Medication names, schedules, and reminder '
              'preferences entered by caretakers on behalf of linked elders.\n\n'
              'Device Information: Device type, operating system, and push '
              'notification tokens for delivering alerts and reminders.',
            ),

            _sectionTitle('3. How We Use Your Information'),
            _body(
              'We use your information to:\n'
              '• Provide and maintain the ElderConnect service\n'
              '• Enable communication between elders and their caretakers\n'
              '• Send medication reminders and wellness notifications\n'
              '• Generate mood and activity reports for linked caretakers\n'
              '• Improve the app experience and develop new features\n'
              '• Ensure account security and prevent unauthorized access',
            ),

            _sectionTitle('4. Data Sharing'),
            _body(
              'Your data is shared only in the following circumstances:\n\n'
              'With Linked Caretakers: Elders\' mood logs, activity data, and '
              'wellness information are shared with their designated caretakers '
              'to support caregiving.\n\n'
              'Service Providers: We use Supabase for backend services and '
              'Firebase for push notifications. These providers process data '
              'on our behalf under strict confidentiality agreements.\n\n'
              'Legal Requirements: We may disclose information if required by '
              'law or to protect the safety of our users.',
            ),

            _sectionTitle('5. Data Security'),
            _body(
              'We take the security of your data seriously:\n'
              '• All data is transmitted over encrypted connections (TLS/SSL)\n'
              '• Passwords are hashed using industry-standard algorithms\n'
              '• Elder PINs are hashed with bcrypt before storage\n'
              '• Sensitive credentials are stored using platform-specific '
              'secure storage (iOS Keychain, Android Keystore)\n'
              '• Access to user data is restricted to authorized personnel only',
            ),

            _sectionTitle('6. Data Retention'),
            _body(
              'We retain your personal data for as long as your account is '
              'active or as needed to provide services. If you delete your '
              'account, we will remove your personal data within 30 days, '
              'except where retention is required by law.',
            ),

            _sectionTitle('7. Your Rights'),
            _body(
              'You have the right to:\n'
              '• Access the personal data we hold about you\n'
              '• Request correction of inaccurate data\n'
              '• Request deletion of your account and associated data\n'
              '• Withdraw consent for data processing at any time\n'
              '• Export your data in a portable format\n\n'
              'To exercise these rights, contact us at privacy@elderconnect.care.',
            ),

            _sectionTitle('8. Children\'s Privacy'),
            _body(
              'ElderConnect is not intended for use by children under the age '
              'of 13. We do not knowingly collect personal information from '
              'children. If we become aware that a child has provided us with '
              'personal data, we will take steps to delete it.',
            ),

            _sectionTitle('9. Push Notifications'),
            _body(
              'ElderConnect uses push notifications to deliver medication '
              'reminders, mood check-ins, and caretaker alerts. You can '
              'manage notification preferences in your device settings at '
              'any time.',
            ),

            _sectionTitle('10. Third-Party Services'),
            _body(
              'ElderConnect integrates with the following third-party services:\n'
              '• Supabase — Authentication and database services\n'
              '• Firebase Cloud Messaging — Push notification delivery\n'
              '• Google Fonts — Typography rendering\n\n'
              'Each service has its own privacy policy governing data handling.',
            ),

            _sectionTitle('11. Changes to This Policy'),
            _body(
              'We may update this Privacy Policy periodically. We will notify '
              'you of material changes through the app or via email. Your '
              'continued use of ElderConnect after changes constitutes '
              'acceptance of the updated policy.',
            ),

            _sectionTitle('12. Contact Us'),
            _body(
              'If you have questions or concerns about this Privacy Policy '
              'or our data practices, please contact us:\n\n'
              'Email: privacy@elderconnect.care\n'
              'Support: support@elderconnect.care',
            ),

            const SizedBox(height: ElderSpacing.xl),
          ],
        ),
      ),
    );
  }

  static Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: ElderSpacing.xs),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurface,
          ),
        ),
      );

  static Widget _subtitle(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: ElderColors.onSurfaceVariant,
        ),
      );

  static Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: ElderSpacing.lg, bottom: ElderSpacing.sm),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ElderColors.onSurface,
          ),
        ),
      );

  static Widget _body(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: ElderColors.onSurfaceVariant,
          height: 1.7,
        ),
      );
}
