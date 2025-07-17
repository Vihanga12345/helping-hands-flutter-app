import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class Helper6RegistrationPage4 extends StatelessWidget {
  const Helper6RegistrationPage4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Complete'),
        automaticallyImplyLeading: false,
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Success Animation/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    size: 60,
                    color: AppColors.warning,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Main Message
                Text(
                  'Registration Submitted!',
                  style: TextStyle().copyWith(
                    color: AppColors.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Your application is now under review. We\'ll verify your documents and get back to you soon.',
                  style: TextStyle().copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Status Card
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Under Review',
                              style: TextStyle().copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        'What happens next?',
                        style: TextStyle(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTimelineStep(
                        1,
                        'Document Verification',
                        'We\'ll verify your submitted documents',
                        '1-2 business days',
                        true,
                      ),
                      
                      _buildTimelineStep(
                        2,
                        'Background Check',
                        'Police clearance and reference verification',
                        '2-3 business days',
                        false,
                      ),
                      
                      _buildTimelineStep(
                        3,
                        'Profile Approval',
                        'Final review and account activation',
                        '1 business day',
                        false,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Information Cards
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: TextStyle().copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• You\'ll receive email updates about your application status',
                        style: TextStyle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Keep your phone accessible for verification calls',
                        style: TextStyle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Check your profile regularly for additional requirements',
                        style: TextStyle(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Contact Support
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
                    children: [
                      Text(
                        'Need Help?',
                        style: TextStyle(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'If you have any questions about your application, our support team is here to help.',
                        style: TextStyle().copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening support chat...')),
                                );
                              },
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('Live Chat'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Calling support...')),
                                );
                              },
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call Us'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/helper-home'),
                    icon: const Icon(Icons.home, size: 18),
                    label: const Text('Go to Dashboard'),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Start'),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(int step, String title, String description, String time, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryGreen : AppColors.lightGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.schedule, color: AppColors.white, size: 18)
                  : Text(
                      step.toString(),
                      style: TextStyle().copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle().copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primaryGreen : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    time,
                    style: TextStyle().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
