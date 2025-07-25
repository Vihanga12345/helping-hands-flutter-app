import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';

class Helpee10ProfilePage extends StatefulWidget {
  const Helpee10ProfilePage({super.key});

  @override
  State<Helpee10ProfilePage> createState() => _Helpee10ProfilePageState();
}

class _Helpee10ProfilePageState extends State<Helpee10ProfilePage> {
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Profile'.tr(),
            showBackButton: false,
            showMenuButton: true,
            showNotificationButton: false,
            rightWidget: GestureDetector(
              onTap: () => context.go('/helpee/profile/edit'),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF8FD89F),
                  size: 18,
                ),
              ),
            ),
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
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _userDataService.getCurrentUserProfile(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      final userProfile = userSnapshot.data;
                      if (userProfile == null) {
                        return _buildErrorState();
                      }

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _userDataService
                            .getUserStatistics(userProfile['user_id']),
                        builder: (context, statsSnapshot) {
                          final stats = statsSnapshot.data ??
                              {
                                'total_jobs': 0,
                                'rating': 0.0,
                                'total_reviews': 0,
                              };

                          return Column(
                            children: [
                              // Profile Image Section
                              _buildProfileImageSection(userProfile),

                              const SizedBox(height: 20),

                              // Stats Section (Rating | Reviews | Jobs)
                              _buildStatsSection(stats),

                              const SizedBox(height: 20),

                              // Personal Information Section
                              _buildPersonalInfoSection(userProfile),

                              const SizedBox(height: 20),

                              // Emergency Contact Section
                              _buildEmergencyContactSection(userProfile),

                              const SizedBox(height: 20),

                              // Action Buttons
                              _buildActionButtons(),

                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.profile,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(Map<String, dynamic> userProfile) {
    final firstName = userProfile['first_name'] ?? '';
    final lastName = userProfile['last_name'] ?? '';
    final displayName = '$firstName $lastName'.trim();

    return Container(
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
          // Profile Picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGreen,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 57,
              backgroundColor: AppColors.primaryGreen,
              backgroundImage: userProfile['profile_image_url'] != null
                  ? NetworkImage(userProfile['profile_image_url'])
                  : null,
              child: userProfile['profile_image_url'] == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            displayName.isNotEmpty ? displayName : 'User',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Rating',
            '${(stats['rating'] ?? 0.0).toStringAsFixed(1)}',
            Icons.star,
            AppColors.warning,
          ),
          _buildStatDivider(),
          _buildClickableStatItem(
            'Reviews',
            '${stats['total_reviews'] ?? 0}',
            Icons.rate_review,
            AppColors.primaryGreen,
            onTap: () {
              // Navigate to reviews page
              context.push('/helpee/reviews');
            },
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Jobs',
            '${stats['total_jobs'] ?? 0}',
            Icons.work,
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(Map<String, dynamic> userProfile) {
    return Container(
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
            'Personal Information',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),

          // About Me
          _buildInfoSection(
            'About me',
            userProfile['about_me'] ?? 'No bio available',
            isMultiLine: true,
          ),
          const SizedBox(height: 16),

          // Email
          _buildInfoRow(
            'Email',
            userProfile['email'] ?? 'Not provided',
            Icons.email,
          ),
          const SizedBox(height: 12),

          // Phone Number
          _buildInfoRow(
            'Phone Number',
            userProfile['phone'] ?? 'Not provided',
            Icons.phone,
          ),
          const SizedBox(height: 12),

          // Location
          _buildInfoRow(
            'Location',
            userProfile['location_city'] ??
                userProfile['location_address'] ??
                'Not provided',
            Icons.location_on,
          ),
          const SizedBox(height: 12),

          // Age
          _buildInfoRow(
            'Age',
            _calculateAge(userProfile['date_of_birth']),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactSection(Map<String, dynamic> userProfile) {
    final emergencyName = userProfile['emergency_contact_name'];
    final emergencyPhone = userProfile['emergency_contact_phone'];

    return Container(
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
            'Emergency Contact',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          if (emergencyName != null || emergencyPhone != null) ...[
            // Name
            _buildInfoRow(
              'Name',
              emergencyName ?? 'Not provided',
              Icons.person,
            ),
            const SizedBox(height: 12),

            // Phone
            _buildInfoRow(
              'Phone',
              emergencyPhone ?? 'Not provided',
              Icons.phone,
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.contact_emergency_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No emergency contact added',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClickableStatItem(
      String label, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildInfoSection(String label, String value,
      {bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: isMultiLine ? 1.5 : 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryGreen,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/helpee/profile/edit'),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showLogoutDialog(context);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 'Not provided';

    try {
      DateTime birthDate;
      if (dateOfBirth is String) {
        birthDate = DateTime.parse(dateOfBirth);
      } else if (dateOfBirth is DateTime) {
        birthDate = dateOfBirth;
      } else {
        return 'Not provided';
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return '$age years old';
    } catch (e) {
      return 'Not provided';
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.logout();
                if (context.mounted) {
                  context.go('/user-selection');
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
