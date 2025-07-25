import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/helper_data_service.dart';
import '../../services/custom_auth_service.dart';

class Helper21ProfileTabPage extends StatefulWidget {
  final int initialTabIndex;

  const Helper21ProfileTabPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<Helper21ProfileTabPage> createState() => _Helper21ProfileTabPageState();
}

class _Helper21ProfileTabPageState extends State<Helper21ProfileTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Services
  final UserDataService _userDataService = UserDataService();
  final HelperDataService _helperDataService = HelperDataService();
  final CustomAuthService _authService = CustomAuthService();

  // Data variables
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStatistics;
  List<Map<String, dynamic>> _helperJobTypes = [];
  List<Map<String, dynamic>> _helperDocuments = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return;
      }

      _currentUserId = currentUser['user_id'];
      print('👤 Loading profile for helper: $_currentUserId');

      // Load all data in parallel
      final results = await Future.wait([
        _userDataService.getCurrentUserProfile(),
        _userDataService.getHelperStatistics(_currentUserId!),
        _helperDataService.getHelperJobTypes(_currentUserId!),
        _helperDataService.getHelperDocuments(_currentUserId!),
      ]);

      setState(() {
        _userProfile = results[0] as Map<String, dynamic>?;
        _userStatistics = results[1] as Map<String, dynamic>;
        _helperJobTypes = results[2] as List<Map<String, dynamic>>;
        _helperDocuments = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      print('✅ Profile data loaded successfully');
      print('📊 Job types: ${_helperJobTypes.length}');
      print('📄 Documents: ${_helperDocuments.length}');
    } catch (e) {
      print('❌ Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              // Header with notification button (edit button removed)
              AppHeader(
                title: 'Profile',
                showMenuButton: true,
                showNotificationButton: true,
                onMenuPressed: () {
                  context.push('/helper/menu');
                },
                onNotificationPressed: () {
                  context.push('/helper/notifications');
                },
              ),

              // Tab Bar and Edit Button Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    // Tab Bar Container (takes up available space but compressed to left)
                    Flexible(
                      flex: 3,
                      child: Container(
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
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelStyle: AppTextStyles.buttonMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            unselectedLabelStyle:
                                AppTextStyles.buttonMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            tabs: const [
                              Tab(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text('Profile'),
                                ),
                              ),
                              Tab(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text('Jobs'),
                                ),
                              ),
                              Tab(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text('Resume'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Spacer between TabBar and Edit Button
                    const SizedBox(width: 16),

                    // Edit Button
                    _buildEditButtonForCurrentTab(),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Tab Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProfileTab(),
                          _buildJobsTab(),
                          _buildResumeTab(),
                        ],
                      ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.profile,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_userProfile == null) {
      return const Center(
        child: Text('Unable to load profile data'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Image Section
          _buildProfileImageSection(),

          const SizedBox(height: 20),

          // Stats Section (Rating | Reviews | Jobs)
          _buildStatsSection(),

          const SizedBox(height: 20),

          // Personal Information Section
          _buildPersonalInfoSection(),

          const SizedBox(height: 20),

          // Emergency Contact Section
          _buildEmergencyContactSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final firstName = _userProfile!['first_name'] ?? '';
    final lastName = _userProfile!['last_name'] ?? '';
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
              backgroundImage: _userProfile!['profile_image_url'] != null
                  ? NetworkImage(_userProfile!['profile_image_url'])
                  : null,
              child: _userProfile!['profile_image_url'] == null
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

  Widget _buildStatsSection() {
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
            '${_userStatistics?['rating']?.toStringAsFixed(1) ?? '0.0'}',
            Icons.star,
            AppColors.warning,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Reviews',
            '${_userStatistics?['total_reviews'] ?? 0}',
            Icons.rate_review,
            AppColors.primaryGreen,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Jobs',
            '${_userStatistics?['total_jobs'] ?? 0}',
            Icons.work,
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
            _userProfile!['about_me'] ?? 'No bio available',
            isMultiLine: true,
          ),
          const SizedBox(height: 16),

          // Email
          _buildInfoRow(
            'Email',
            _userProfile!['email'] ?? 'Not provided',
            Icons.email,
          ),
          const SizedBox(height: 12),

          // Phone Number
          _buildInfoRow(
            'Phone Number',
            _userProfile!['phone'] ?? 'Not provided',
            Icons.phone,
          ),
          const SizedBox(height: 12),

          // Location
          _buildInfoRow(
            'Location',
            _userProfile!['location_city'] ?? 'Not provided',
            Icons.location_on,
          ),
          const SizedBox(height: 12),

          // Age
          _buildInfoRow(
            'Age',
            _calculateAge(_userProfile!['date_of_birth']),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    final emergencyName = _userProfile!['emergency_contact_name'];
    final emergencyPhone = _userProfile!['emergency_contact_phone'];

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

  Widget _buildJobsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Types List
          if (_helperJobTypes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
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
              child: Column(
                children: [
                  Icon(
                    Icons.work_off,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Job Types Selected',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add job types to show your skills',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // Job Types Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _helperJobTypes.length,
              itemBuilder: (context, index) {
                final jobType = _helperJobTypes[index];
                final categoryName =
                    jobType['job_categories']['name'] ?? 'Unknown';
                final hourlyRate = (jobType['hourly_rate'] ?? 0).toDouble();
                final experienceLevel =
                    jobType['experience_level'] ?? 'beginner';

                return Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work,
                        color: AppColors.primaryGreen,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        categoryName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LKR ${hourlyRate.toStringAsFixed(0)}/hr',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        experienceLevel.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Documents Grid
          if (_helperDocuments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
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
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Documents Uploaded',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload certificates and work samples\nto showcase your qualifications',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // Documents Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _helperDocuments.length,
              itemBuilder: (context, index) {
                final document = _helperDocuments[index];
                final fileName = document['document_name'] ?? 'Unknown File';
                final fileType = document['file_type'] ?? '';
                final isImage =
                    ['jpg', 'jpeg', 'png'].contains(fileType.toLowerCase());
                final fileSize = _formatFileSize(document['file_size_bytes']);
                final uploadDate = _formatDate(document['created_at']);

                return Container(
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
                  child: Column(
                    children: [
                      // File Preview
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isImage
                                ? AppColors.lightGrey
                                : AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              isImage ? Icons.image : Icons.description,
                              size: 40,
                              color: isImage
                                  ? AppColors.textSecondary
                                  : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),

                      // File Info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fileSize,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              uploadDate,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryGreen,
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
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getJobIcon(String jobType) {
    switch (jobType.toLowerCase()) {
      case 'house cleaning':
      case 'deep cleaning':
        return Icons.cleaning_services;
      case 'gardening':
        return Icons.yard;
      case 'pet care':
        return Icons.pets;
      case 'cooking':
        return Icons.restaurant;
      case 'elderly care':
        return Icons.elderly;
      case 'laundry service':
        return Icons.local_laundry_service;
      case 'organizing':
        return Icons.inventory;
      default:
        return Icons.work;
    }
  }

  IconData _getDocumentIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  Color _getVerificationColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
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
      return 'Unknown date';
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

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 KB';

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 'Age not specified';
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age years';
    } catch (e) {
      return 'Age not specified';
    }
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
