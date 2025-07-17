import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class HelperTermsConditionsPage extends StatelessWidget {
  const HelperTermsConditionsPage({super.key});

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
                title: 'Terms & Conditions',
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
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
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
                              'Please read these terms carefully before using the Helping Hands platform as a helper.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Terms Sections
                      _buildTermsSection(
                        '1. Acceptance of Terms',
                        'By registering as a helper on the Helping Hands platform, you agree to comply with and be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.',
                      ),

                      _buildTermsSection(
                        '2. Helper Responsibilities',
                        'As a helper, you agree to:\n'
                            '• Provide accurate and up-to-date profile information\n'
                            '• Complete verification requirements as requested\n'
                            '• Deliver services professionally and safely\n'
                            '• Maintain appropriate communication with clients\n'
                            '• Honor accepted job commitments\n'
                            '• Follow all applicable laws and regulations',
                      ),

                      _buildTermsSection(
                        '3. Service Standards',
                        'All helpers must maintain high service standards including:\n'
                            '• Punctuality and reliability\n'
                            '• Professional conduct and appearance\n'
                            '• Respect for client property and privacy\n'
                            '• Quality workmanship appropriate to the service\n'
                            '• Clear communication throughout the service process',
                      ),

                      _buildTermsSection(
                        '4. Payment Terms',
                        'Payment arrangements:\n'
                            '• Payments are processed through the platform\n'
                            '• Helpers receive payment after service completion and client confirmation\n'
                            '• Platform fees may apply as outlined in your agreement\n'
                            '• Dispute resolution procedures apply for payment issues\n'
                            '• Tax obligations are the responsibility of the helper',
                      ),

                      _buildTermsSection(
                        '5. Cancellation Policy',
                        'Job cancellation guidelines:\n'
                            '• Helpers may cancel jobs with appropriate notice\n'
                            '• Frequent cancellations may affect account standing\n'
                            '• Emergency cancellations must include valid reasons\n'
                            '• Compensation may be required for late cancellations',
                      ),

                      _buildTermsSection(
                        '6. Safety and Insurance',
                        'Safety requirements:\n'
                            '• Helpers must follow all safety protocols\n'
                            '• Appropriate insurance coverage is recommended\n'
                            '• Report any incidents or accidents immediately\n'
                            '• Comply with health and safety regulations',
                      ),

                      _buildTermsSection(
                        '7. Account Termination',
                        'Accounts may be terminated for:\n'
                            '• Violation of terms and conditions\n'
                            '• Fraudulent activity or misrepresentation\n'
                            '• Consistently poor service ratings\n'
                            '• Failure to complete verification requirements\n'
                            '• Inappropriate conduct toward clients or staff',
                      ),

                      _buildTermsSection(
                        '8. Limitation of Liability',
                        'Helping Hands platform:\n'
                            '• Acts as a facilitator between helpers and clients\n'
                            '• Is not responsible for the quality of services provided\n'
                            '• Does not guarantee specific income or job availability\n'
                            '• Limits liability to the extent permitted by law',
                      ),

                      _buildTermsSection(
                        '9. Intellectual Property',
                        'Platform usage rights:\n'
                            '• Content and materials remain property of Helping Hands\n'
                            '• Helpers may not reproduce or distribute platform content\n'
                            '• User-generated content may be used for platform improvement\n'
                            '• Respect third-party intellectual property rights',
                      ),

                      _buildTermsSection(
                        '10. Modifications',
                        'These terms may be updated periodically. Continued use of the platform after changes constitutes acceptance of updated terms. Users will be notified of significant changes.',
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
                              'Questions about these terms?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'If you have any questions about these Terms and Conditions, please contact us at legal@helpinghands.lk or call +94 11 123 4567.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.textSecondary,
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

  Widget _buildTermsSection(String title, String content) {
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
                color: AppColors.primaryGreen,
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
