import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class HelperPrivacyPolicyPage extends StatelessWidget {
  const HelperPrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, 0.00),
            end: Alignment(0.50, 1.00),
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const AppHeader(
                title: 'Privacy Policy',
                showBackButton: true,
                showMenuButton: false,
                showNotificationButton: false,
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Last updated: December 2024',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'This Privacy Policy explains how we collect, use, and protect your personal information when you use the Helping Hands platform.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Privacy Sections
                      _buildPrivacySection(
                        '1. Information We Collect',
                        'We collect the following types of information:\n\n'
                            'Personal Information:\n'
                            '• Name, contact details, and identification\n'
                            '• Profile photos and verification documents\n'
                            '• Skills, experience, and service preferences\n'
                            '• Payment information and bank details\n\n'
                            'Usage Information:\n'
                            '• App usage patterns and preferences\n'
                            '• Location data for service matching\n'
                            '• Communication records with clients\n'
                            '• Service history and ratings',
                      ),

                      _buildPrivacySection(
                        '2. How We Use Your Information',
                        'Your information is used to:\n'
                            '• Create and maintain your helper profile\n'
                            '• Match you with relevant job opportunities\n'
                            '• Process payments and maintain financial records\n'
                            '• Verify your identity and qualifications\n'
                            '• Improve our services and platform functionality\n'
                            '• Communicate important updates and notifications\n'
                            '• Ensure platform safety and security',
                      ),

                      _buildPrivacySection(
                        '3. Information Sharing',
                        'We share your information only when necessary:\n\n'
                            'With Clients:\n'
                            '• Basic profile information for job matching\n'
                            '• Contact details after job acceptance\n'
                            '• Service history and ratings\n\n'
                            'With Third Parties:\n'
                            '• Payment processors for financial transactions\n'
                            '• Verification services for identity confirmation\n'
                            '• Analytics services for platform improvement\n\n'
                            'We never sell your personal information to third parties.',
                      ),

                      _buildPrivacySection(
                        '4. Data Security',
                        'We protect your information through:\n'
                            '• Encryption of sensitive data in transit and at rest\n'
                            '• Secure payment processing systems\n'
                            '• Regular security audits and updates\n'
                            '• Access controls limiting who can view your data\n'
                            '• Incident response procedures for security breaches\n'
                            '• Compliance with industry security standards',
                      ),

                      _buildPrivacySection(
                        '5. Your Privacy Rights',
                        'You have the right to:\n'
                            '• Access your personal information\n'
                            '• Update or correct inaccurate data\n'
                            '• Request deletion of your account and data\n'
                            '• Control marketing communications\n'
                            '• Export your data in a portable format\n'
                            '• File complaints with data protection authorities',
                      ),

                      _buildPrivacySection(
                        '6. Data Retention',
                        'We retain your information:\n'
                            '• While your account is active\n'
                            '• For legal and regulatory compliance requirements\n'
                            '• To resolve disputes or provide customer support\n'
                            '• As required for safety and security purposes\n\n'
                            'You can request account deletion at any time through the app settings or by contacting support.',
                      ),

                      _buildPrivacySection(
                        '7. Location Information',
                        'Location data usage:\n'
                            '• Used to match you with nearby job opportunities\n'
                            '• Helps estimate travel time and costs\n'
                            '• Enables location-based safety features\n'
                            '• Can be disabled in your device settings\n'
                            '• Precise location is not shared with clients until job acceptance',
                      ),

                      _buildPrivacySection(
                        '8. Communications',
                        'We may contact you for:\n'
                            '• Job notifications and updates\n'
                            '• Platform announcements and feature updates\n'
                            '• Safety alerts and important notices\n'
                            '• Marketing communications (with your consent)\n'
                            '• Customer support and assistance\n\n'
                            'You can manage communication preferences in your account settings.',
                      ),

                      _buildPrivacySection(
                        '9. Children\'s Privacy',
                        'Our platform is intended for users 18 years and older. We do not knowingly collect information from children under 18. If you become aware that a child has provided personal information, please contact us immediately.',
                      ),

                      _buildPrivacySection(
                        '10. Policy Updates',
                        'This Privacy Policy may be updated periodically to reflect changes in our practices or legal requirements. We will notify you of significant changes through the app or email. Continued use of the platform constitutes acceptance of updated policies.',
                      ),

                      const SizedBox(height: 20),

                      // Contact Information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColorLight,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy Questions or Concerns?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'If you have questions about this Privacy Policy or want to exercise your privacy rights, please contact our Data Protection Officer at:',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Email: privacy@helpinghands.lk\nPhone: +94 11 123 4567\nAddress: Privacy Office, Helping Hands, Colombo, Sri Lanka',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.home,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
