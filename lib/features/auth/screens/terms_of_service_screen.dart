/// Terms of Service screen for ElderConnect.
///
/// Full-page scrollable view presented when the user taps "Terms of Service"
/// on the caretaker registration form.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
            _heading('Terms of Service'),
            _subtitle('Last updated: April 2026'),
            const SizedBox(height: ElderSpacing.lg),

            _sectionTitle('1. Acceptance of Terms'),
            _body(
              'By creating an account or using ElderConnect, you agree to be '
              'bound by these Terms of Service. If you do not agree, please do '
              'not use the app. These terms apply to all users, including elders '
              'and caretakers.',
            ),

            _sectionTitle('2. Description of Service'),
            _body(
              'ElderConnect is a social engagement and wellness platform designed '
              'to connect elderly individuals with their caretakers. The app '
              'provides features including mood tracking, daily journals, wellness '
              'games, medication reminders, community feeds, and communication '
              'tools between elders and their designated caretakers.',
            ),

            _sectionTitle('3. Account Registration'),
            _body(
              'You must provide accurate and complete information during '
              'registration. You are responsible for maintaining the '
              'confidentiality of your account credentials, including passwords '
              'and PINs. You agree to notify us immediately of any unauthorized '
              'use of your account.',
            ),

            _sectionTitle('4. Caretaker Responsibilities'),
            _body(
              'Caretakers who register on ElderConnect agree to:\n'
              '• Provide truthful profile information\n'
              '• Respect the privacy and dignity of the elders they are linked to\n'
              '• Use the app only for its intended caregiving purposes\n'
              '• Not share access credentials with unauthorized individuals\n'
              '• Report any concerns about elder safety through appropriate channels',
            ),

            _sectionTitle('5. Elder User Considerations'),
            _body(
              'ElderConnect is designed with accessibility in mind for elderly '
              'users. Features such as larger text, simplified navigation, and '
              'voice-based interactions are provided to ensure ease of use. '
              'Caretakers may assist elders in setting up and managing their '
              'accounts with the elder\'s consent.',
            ),

            _sectionTitle('6. Acceptable Use'),
            _body(
              'You agree not to:\n'
              '• Use the app for any unlawful purpose\n'
              '• Upload harmful, offensive, or misleading content\n'
              '• Attempt to interfere with the app\'s functionality or security\n'
              '• Impersonate another person or misrepresent your affiliation\n'
              '• Use automated systems to access the app without permission',
            ),

            _sectionTitle('7. Content and Data'),
            _body(
              'You retain ownership of the content you create (mood logs, journal '
              'entries, photos, etc.). By using ElderConnect, you grant us a '
              'limited license to store and process this content solely for the '
              'purpose of providing the service to you and your linked caretakers.',
            ),

            _sectionTitle('8. Intellectual Property'),
            _body(
              'The ElderConnect name, logo, design, and all associated '
              'intellectual property are owned by ElderConnect. You may not '
              'reproduce, distribute, or create derivative works from any part '
              'of the app without prior written consent.',
            ),

            _sectionTitle('9. Limitation of Liability'),
            _body(
              'ElderConnect is provided "as is" without warranties of any kind. '
              'We are not liable for any direct, indirect, incidental, or '
              'consequential damages arising from your use of the app. '
              'ElderConnect is not a substitute for professional care or '
              'emergency services. In case of an emergency, please contact '
              'your local emergency services immediately.',
            ),

            _sectionTitle('10. Termination'),
            _body(
              'We reserve the right to suspend or terminate your account at any '
              'time if you violate these terms. You may delete your account at '
              'any time by contacting support. Upon termination, your data will '
              'be handled in accordance with our Privacy Policy.',
            ),

            _sectionTitle('11. Changes to Terms'),
            _body(
              'We may update these Terms of Service from time to time. We will '
              'notify you of significant changes through the app. Continued use '
              'of ElderConnect after changes constitutes acceptance of the '
              'updated terms.',
            ),

            _sectionTitle('12. Contact'),
            _body(
              'If you have questions about these Terms of Service, please '
              'contact us at support@elderconnect.care.',
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
