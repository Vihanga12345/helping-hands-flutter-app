import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../services/supabase_service.dart';
import '../../services/firebase_messaging_service.dart';
import '../../services/custom_auth_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/custom_app_bar.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Notification preferences
  bool _jobRequests = true;
  bool _jobUpdates = true;
  bool _jobCompletions = true;
  bool _paymentReminders = true;
  bool _ratingReminders = true;
  bool _systemUpdates = true;
  bool _marketingNotifications = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseMessagingService _firebaseService = FirebaseMessagingService();
  final CustomAuthService _authService = CustomAuthService();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = currentUser['user_id'];
      final preferences =
          await _supabaseService.getUserNotificationPreferences(userId);

      if (preferences != null) {
        setState(() {
          _jobRequests = preferences['job_requests'] ?? true;
          _jobUpdates = preferences['job_updates'] ?? true;
          _jobCompletions = preferences['job_completions'] ?? true;
          _paymentReminders = preferences['payment_reminders'] ?? true;
          _ratingReminders = preferences['rating_reminders'] ?? true;
          _systemUpdates = preferences['system_updates'] ?? true;
          _marketingNotifications =
              preferences['marketing_notifications'] ?? false;
          _pushNotifications = preferences['push_notifications'] ?? true;
          _emailNotifications = preferences['email_notifications'] ?? true;
          _smsNotifications = preferences['sms_notifications'] ?? false;
        });
      }
    } catch (e) {
      print('❌ Error loading notification preferences: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load notification settings'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    try {
      setState(() => _isSaving = true);

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = currentUser['user_id'];

      final preferences = {
        'job_requests': _jobRequests,
        'job_updates': _jobUpdates,
        'job_completions': _jobCompletions,
        'payment_reminders': _paymentReminders,
        'rating_reminders': _ratingReminders,
        'system_updates': _systemUpdates,
        'marketing_notifications': _marketingNotifications,
        'push_notifications': _pushNotifications,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
      };

      await _supabaseService.updateUserNotificationPreferences(
          userId, preferences);

      // Update Firebase messaging subscriptions based on preferences
      await _updateFirebaseSubscriptions();

      if (mounted) {
        _showSuccessSnackBar('Notification settings saved successfully'.tr());
      }
    } catch (e) {
      print('❌ Error saving notification preferences: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save notification settings'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateFirebaseSubscriptions() async {
    try {
      // Update topic subscriptions based on preferences
      // This would typically be done for category-specific notifications
      print('🔔 Updating Firebase subscriptions based on preferences');
    } catch (e) {
      print('❌ Error updating Firebase subscriptions: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.darkGrey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.mediumGrey,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: icon != null
            ? Icon(
                icon,
                color: value ? AppColors.primaryGreen : AppColors.mediumGrey,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Notification Settings'.tr(),
              showBackButton: true,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Job Notifications Section
                          _buildSectionTitle('Job Notifications'.tr()),
                          _buildSettingCard(
                            title: 'Job Requests'.tr(),
                            subtitle:
                                'Receive notifications for new job requests'
                                    .tr(),
                            value: _jobRequests,
                            onChanged: (value) =>
                                setState(() => _jobRequests = value),
                            icon: Icons.work_outline,
                          ),
                          _buildSettingCard(
                            title: 'Job Updates'.tr(),
                            subtitle:
                                'Get notified about job status changes'.tr(),
                            value: _jobUpdates,
                            onChanged: (value) =>
                                setState(() => _jobUpdates = value),
                            icon: Icons.update,
                          ),
                          _buildSettingCard(
                            title: 'Job Completions'.tr(),
                            subtitle:
                                'Notifications when jobs are completed'.tr(),
                            value: _jobCompletions,
                            onChanged: (value) =>
                                setState(() => _jobCompletions = value),
                            icon: Icons.check_circle_outline,
                          ),

                          // Payment & Rating Section
                          _buildSectionTitle('Payments & Ratings'.tr()),
                          _buildSettingCard(
                            title: 'Payment Reminders'.tr(),
                            subtitle: 'Reminders for pending payments'.tr(),
                            value: _paymentReminders,
                            onChanged: (value) =>
                                setState(() => _paymentReminders = value),
                            icon: Icons.payment,
                          ),
                          _buildSettingCard(
                            title: 'Rating Reminders'.tr(),
                            subtitle: 'Reminders to rate completed jobs'.tr(),
                            value: _ratingReminders,
                            onChanged: (value) =>
                                setState(() => _ratingReminders = value),
                            icon: Icons.star_border,
                          ),

                          // System Notifications Section
                          _buildSectionTitle('System Notifications'.tr()),
                          _buildSettingCard(
                            title: 'System Updates'.tr(),
                            subtitle:
                                'App updates and maintenance notifications'
                                    .tr(),
                            value: _systemUpdates,
                            onChanged: (value) =>
                                setState(() => _systemUpdates = value),
                            icon: Icons.system_update,
                          ),
                          _buildSettingCard(
                            title: 'Marketing'.tr(),
                            subtitle:
                                'Promotional offers and new features'.tr(),
                            value: _marketingNotifications,
                            onChanged: (value) =>
                                setState(() => _marketingNotifications = value),
                            icon: Icons.campaign,
                          ),

                          // Delivery Methods Section
                          _buildSectionTitle('Delivery Methods'.tr()),
                          _buildSettingCard(
                            title: 'Push Notifications'.tr(),
                            subtitle:
                                'Instant notifications on your device'.tr(),
                            value: _pushNotifications,
                            onChanged: (value) =>
                                setState(() => _pushNotifications = value),
                            icon: Icons.notifications,
                          ),
                          _buildSettingCard(
                            title: 'Email Notifications'.tr(),
                            subtitle: 'Receive notifications via email'.tr(),
                            value: _emailNotifications,
                            onChanged: (value) =>
                                setState(() => _emailNotifications = value),
                            icon: Icons.email,
                          ),
                          _buildSettingCard(
                            title: 'SMS Notifications'.tr(),
                            subtitle:
                                'Receive notifications via text message'.tr(),
                            value: _smsNotifications,
                            onChanged: (value) =>
                                setState(() => _smsNotifications = value),
                            icon: Icons.sms,
                          ),

                          const SizedBox(height: 24),

                          // FCM Token Info (for debugging)
                          if (_firebaseService.fcmToken != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Device Info'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.mediumGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'FCM Token: ${_firebaseService.fcmToken!.substring(0, 20)}...',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.mediumGrey,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveNotificationPreferences,
              backgroundColor: AppColors.primaryGreen,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: AppColors.white),
              label: Text(
                _isSaving ? 'Saving...'.tr() : 'Save Settings'.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}

// Extension for translation support
extension NotificationSettingsTranslations on String {
  String tr() {
    return LocalizationService().translate(this);
  }
}
