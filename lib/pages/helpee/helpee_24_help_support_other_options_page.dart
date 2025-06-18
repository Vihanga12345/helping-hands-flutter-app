import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helpee24HelpSupportOtherOptionsPage extends StatefulWidget {
  const Helpee24HelpSupportOtherOptionsPage({super.key});

  @override
  State<Helpee24HelpSupportOtherOptionsPage> createState() => _Helpee24HelpSupportOtherOptionsPageState();
}

class _Helpee24HelpSupportOtherOptionsPageState extends State<Helpee24HelpSupportOtherOptionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Help & Support',
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
          ),
          
          // Body Content
          Expanded(
            child: Container(
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
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: AppColors.primaryGreen,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'How can we help you?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choose from the options below to get the support you need',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Support Options
                      _buildSupportOption(
                        'Account & Profile',
                        'Manage your account settings, update profile information, and security options',
                        Icons.account_circle,
                        AppColors.primaryGreen,
                        () => _navigateToAccountSupport(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSupportOption(
                        'App Issues',
                        'Report bugs, app crashes, performance issues, and technical problems',
                        Icons.bug_report,
                        Colors.red,
                        () => _navigateToTechnicalSupport(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSupportOption(
                        'Safety & Trust',
                        'Report safety concerns, trust issues, and inappropriate behavior',
                        Icons.security,
                        Colors.orange,
                        () => _navigateToSafetySupport(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSupportOption(
                        'Feedback & Suggestions',
                        'Share your experience and suggest improvements for our service',
                        Icons.feedback,
                        Colors.blue,
                        () => _navigateToFeedback(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSupportOption(
                        'Partnership & Business',
                        'Business inquiries, partnership opportunities, and commercial support',
                        Icons.business,
                        Colors.purple,
                        () => _navigateToBusinessSupport(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Contact Information Card
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Phone
                            _buildContactInfo(
                              Icons.phone,
                              'Phone Support',
                              '+94 11 234 5678',
                              'Available 24/7',
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email
                            _buildContactInfo(
                              Icons.email,
                              'Email Support',
                              'support@helpinghands.lk',
                              'Response within 24 hours',
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Live Chat
                            _buildContactInfo(
                              Icons.chat,
                              'Live Chat',
                              'Available in app',
                              'Mon-Fri: 8 AM - 8 PM',
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Emergency Contact
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.emergency, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Emergency Contact',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'For urgent safety issues or emergencies, call our 24/7 emergency line: +94 11 999 8888',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // FAQ Link
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.help_outline,
                              color: AppColors.primaryGreen,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Looking for quick answers?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check our frequently asked questions for instant help',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.go('/helpee/help-support/my-jobs'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('View FAQ'),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.home,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAccountSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Account Support...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _navigateToTechnicalSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Technical Support...'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToSafetySupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Safety & Trust Support...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Feedback Form...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToBusinessSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Business Support...'),
        backgroundColor: Colors.purple,
      ),
    );
  }
} 
