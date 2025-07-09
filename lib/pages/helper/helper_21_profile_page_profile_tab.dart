import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/helper_data_service.dart';

class Helper21ProfilePageProfileTab extends StatefulWidget {
  final int initialTabIndex;

  const Helper21ProfilePageProfileTab({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<Helper21ProfilePageProfileTab> createState() =>
      _Helper21ProfilePageProfileTabState();
}

class _Helper21ProfilePageProfileTabState
    extends State<Helper21ProfilePageProfileTab> with TickerProviderStateMixin {
  late TabController _tabController;
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();
  final HelperDataService _helperDataService = HelperDataService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Profile',
            showBackButton: false,
            showMenuButton: true,
            showNotificationButton: false,
            rightWidget: GestureDetector(
              onTap: () => context.go('/helper/profile/edit'),
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
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicator: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: AppTextStyles.buttonMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle:
                              AppTextStyles.buttonMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Profile'),
                              ),
                            ),
                            Tab(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Jobs'),
                              ),
                            ),
                            Tab(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Resume'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Edit Button Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildEditButtonForCurrentTab(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProfileTab(),
                          _buildJobsTab(),
                          _buildResumeTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.profile,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataService.getCurrentUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final userProfile = userSnapshot.data;
        if (userProfile == null) {
          return _buildErrorState();
        }

        // DEBUG: Print user data to console
        print('🔍 DEBUG: Helper Profile Page Data:');
        print('   User ID: ${userProfile['user_id']}');
        print('   User Type: ${userProfile['user_type']}');
        print('   Username: ${userProfile['username']}');
        print(
            '   Name: ${userProfile['first_name']} ${userProfile['last_name']}');
        print('   Email: ${userProfile['email']}');
        print('   Current Auth Service User: ${_authService.currentUser}');
        print(
            '   Current Auth Service User Type: ${_authService.currentUserType}');

        // Check if this is actually a helper user
        if (userProfile['user_type'] != 'helper') {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Authentication Error',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are logged in as a ${userProfile['user_type']}, but this is a helper profile page.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.logout();
                    if (context.mounted) {
                      context.go('/user-selection');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout and Switch User'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.forceClearSession();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session cleared. Please login again.'),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                      context.go('/user-selection');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Session (Debug)'),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _userDataService.getHelperStatistics(userProfile['user_id']),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ??
                {
                  'total_jobs': 0,
                  'rating': 0.0,
                  'total_reviews': 0,
                  'member_since': 'Dec 2024',
                };

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(userProfile, stats),

                  const SizedBox(height: 20),

                  // Personal Information
                  _buildPersonalInformation(userProfile),

                  const SizedBox(height: 16),

                  // Contact Information
                  _buildContactInformation(userProfile),

                  const SizedBox(height: 16),

                  // Preferences
                  _buildPreferences(userProfile),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJobsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Job Statistics
          _buildJobStatistics(),

          const SizedBox(height: 20),

          // Skills and Categories
          _buildSkillsSection(),

          const SizedBox(height: 20),

          // Recent Jobs
          _buildRecentJobsSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Experience Section
          _buildExperienceSection(),

          const SizedBox(height: 20),

          // Education Section
          _buildEducationSection(),

          const SizedBox(height: 20),

          // Certifications and Documents
          _buildCertificationsSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      Map<String, dynamic> userProfile, Map<String, dynamic> stats) {
    final firstName = userProfile['first_name'] ?? '';
    final lastName = userProfile['last_name'] ?? '';
    final displayName = userProfile['display_name'] ?? '$firstName $lastName';
    final memberSince = stats['member_since'] ?? 'Dec 2024';

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
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryGreen,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName.isNotEmpty ? displayName : 'Helper',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Helper since $memberSince',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Jobs', '${stats['total_jobs']}'),
              _buildStatItem('Rating', '${stats['rating'].toStringAsFixed(1)}'),
              _buildStatItem('Reviews', '${stats['total_reviews']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation(Map<String, dynamic> userProfile) {
    return _buildInfoSection(
      title: 'Personal Information',
      items: [
        _buildInfoItem(
            'Full Name',
            '${userProfile['first_name'] ?? ''} ${userProfile['last_name'] ?? ''}'
                .trim()),
        _buildInfoItem(
            'Date of Birth', _formatDateOfBirth(userProfile['date_of_birth'])),
        _buildInfoItem(
            'Location', userProfile['location_city'] ?? 'Not provided'),
        _buildInfoItem('About Me', userProfile['about_me'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildContactInformation(Map<String, dynamic> userProfile) {
    return _buildInfoSection(
      title: 'Contact Information',
      items: [
        _buildInfoItem('Email', userProfile['email'] ?? 'Not provided'),
        _buildInfoItem('Phone', userProfile['phone'] ?? 'Not provided'),
        _buildInfoItem(
            'Address', userProfile['location_address'] ?? 'Not provided'),
        _buildInfoItem('Emergency Contact',
            userProfile['emergency_contact_name'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildPreferences(Map<String, dynamic> userProfile) {
    return _buildInfoSection(
      title: 'Preferences',
      items: [
        _buildInfoItem(
            'Language', userProfile['preferred_language'] ?? 'English'),
        _buildInfoItem('Currency', userProfile['preferred_currency'] ?? 'LKR'),
        _buildInfoItem(
            'Notifications',
            userProfile['notifications_enabled'] == true
                ? 'Enabled'
                : 'Disabled'),
        _buildInfoItem('Availability',
            'Available'), // This would come from a separate availability system
      ],
    );
  }

  Widget _buildJobStatistics() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return _buildEmptySection(
          'Job Statistics', 'Please log in to view statistics');
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataService.getHelperStatistics(currentUser['user_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSection();
        }

        final stats = snapshot.data ?? {};

        return _buildInfoSection(
          title: 'Job Statistics',
          items: [
            _buildInfoItem(
                'Total Jobs Completed', '${stats['completed_jobs'] ?? 0}'),
            _buildInfoItem('Jobs in Progress', '${stats['ongoing_jobs'] ?? 0}'),
            _buildInfoItem('Pending Requests', '${stats['pending_jobs'] ?? 0}'),
            _buildInfoItem('Success Rate', '95%'), // This would be calculated
          ],
        );
      },
    );
  }

  Widget _buildSkillsSection() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return _buildEmptySection(
          'Skills & Categories', 'Please log in to view skills');
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _helperDataService.getHelperJobTypes(currentUser['user_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSection();
        }

        final jobTypes = snapshot.data ?? [];

        if (jobTypes.isEmpty) {
          return _buildEmptySection(
              'Skills & Categories', 'No job types selected yet');
        }

        // Extract job names and rates
        final skillNames = jobTypes
            .map((jt) => jt['job_categories']['name'] as String)
            .toList();
        final hourlyRates =
            jobTypes.map((jt) => (jt['hourly_rate'] ?? 0).toDouble()).toList();

        final minRate = hourlyRates.isEmpty
            ? 0.0
            : hourlyRates.reduce((a, b) => a < b ? a : b);
        final maxRate = hourlyRates.isEmpty
            ? 0.0
            : hourlyRates.reduce((a, b) => a > b ? a : b);

        // Determine experience level based on number of job types and rates
        String experienceLevel = 'Beginner';
        if (jobTypes.length >= 5 && maxRate >= 2500) {
          experienceLevel = 'Expert';
        } else if (jobTypes.length >= 3 && maxRate >= 2000) {
          experienceLevel = 'Intermediate';
        }

        return _buildInfoSection(
          title: 'Skills & Categories',
          items: [
            _buildInfoItem('Job Categories', skillNames.take(3).join(', ')),
            if (skillNames.length > 3)
              _buildInfoItem('Additional Skills',
                  '${skillNames.length - 3} more categories'),
            _buildInfoItem(
                'Hourly Rate Range',
                minRate == maxRate
                    ? 'LKR ${minRate.toStringAsFixed(0)}'
                    : 'LKR ${minRate.toStringAsFixed(0)} - ${maxRate.toStringAsFixed(0)}'),
            _buildInfoItem('Experience Level', experienceLevel),
            _buildInfoItem('Total Categories', '${jobTypes.length} selected'),
          ],
        );
      },
    );
  }

  Widget _buildRecentJobsSection() {
    return _buildInfoSection(
      title: 'Recent Job Performance',
      items: [
        _buildInfoItem('Last Job', 'House Cleaning - Completed'),
        _buildInfoItem('Average Rating', '4.8/5'),
        _buildInfoItem('On-time Completion', '98%'),
        _buildInfoItem('Customer Satisfaction', '96%'),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return _buildInfoSection(
      title: 'Work Experience',
      items: [
        _buildInfoItem('Years of Experience', '3 years'),
        _buildInfoItem('Previous Employer', 'CleanCorp Services'),
        _buildInfoItem('Specialization', 'Residential Cleaning'),
        _buildInfoItem(
            'Additional Skills', 'Time Management, Customer Service'),
      ],
    );
  }

  Widget _buildEducationSection() {
    return _buildInfoSection(
      title: 'Education',
      items: [
        _buildInfoItem('Highest Education', 'High School Diploma'),
        _buildInfoItem('Institution', 'Colombo National School'),
        _buildInfoItem('Year Completed', '2018'),
        _buildInfoItem(
            'Additional Training', 'Professional Cleaning Certification'),
      ],
    );
  }

  Widget _buildCertificationsSection() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return _buildEmptySection(
          'Documents & Certifications', 'Please log in to view documents');
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _helperDataService.getHelperDocuments(currentUser['user_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSection();
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return _buildEmptySection(
              'Documents & Certifications', 'No documents uploaded yet');
        }

        // Group documents by type
        final certificates = documents
            .where((doc) => doc['document_type'] == 'certificate')
            .toList();
        final workSamples = documents
            .where((doc) => doc['document_type'] == 'work_sample')
            .toList();
        final otherDocs = documents
            .where((doc) =>
                !['certificate', 'work_sample'].contains(doc['document_type']))
            .toList();

        return _buildInfoSection(
          title: 'Documents & Certifications',
          items: [
            _buildInfoItem('Total Documents', '${documents.length} uploaded'),
            _buildInfoItem('Certificates', '${certificates.length} files'),
            _buildInfoItem('Work Samples', '${workSamples.length} files'),
            if (otherDocs.isNotEmpty)
              _buildInfoItem('Other Documents', '${otherDocs.length} files'),
            _buildInfoItem(
                'Verification Status',
                documents.any((doc) => doc['verification_status'] == 'verified')
                    ? 'Some documents verified'
                    : 'Pending verification'),
            if (documents.isNotEmpty)
              _buildInfoItem(
                  'Last Updated', _formatDate(documents.first['created_at'])),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/helper/profile/edit'),
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

  Widget _buildLoadingSection() {
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
      child: const Center(
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

  Widget _buildEmptySection(String title, String message) {
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
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
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
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateOfBirth(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 'Not provided';

    try {
      DateTime date;
      if (dateOfBirth is String) {
        date = DateTime.parse(dateOfBirth);
      } else if (dateOfBirth is DateTime) {
        date = dateOfBirth;
      } else {
        return 'Not provided';
      }

      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      final day = date.day;
      final suffix = _getDaySuffix(day);
      return '${day}${suffix} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Not provided';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
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

  Widget _buildEditButtonForCurrentTab() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          // Navigate based on current tab
          switch (_tabController.index) {
            case 0: // Profile tab
              context.push('/helper/profile/edit');
              break;
            case 1: // Jobs tab
              context.push('/helper/profile/jobs/edit');
              break;
            case 2: // Resume tab
              context.push('/helper/profile/resume/edit');
              break;
          }
        },
        icon: const Icon(
          Icons.edit,
          color: Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
