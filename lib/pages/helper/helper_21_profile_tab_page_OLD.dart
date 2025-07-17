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

              // Tab Bar
              Container(
                margin: const EdgeInsets.all(16),
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
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicator: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Jobs'),
                    Tab(text: 'Resume'),
                  ],
                ),
              ),

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
          // Profile Image and Basic Info
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
                // Profile Image
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
                  child: ClipOval(
                    child: _userProfile!['profile_image_url'] != null
                        ? Image.network(
                            _userProfile!['profile_image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.lightGrey,
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.lightGrey,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Username (First name + Last name)
                Text(
                  '${_userProfile!['first_name'] ?? ''} ${_userProfile!['last_name'] ?? ''}',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Rating and Job Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_userStatistics?['rating']?.toStringAsFixed(1) ?? '0.0'} (${_userStatistics?['total_reviews'] ?? 0} reviews)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Personal Information
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
                Text(
                  'Personal Information',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                    'Telephone',
                    _userProfile!['phone_number'] ?? 'Not provided',
                    Icons.phone),
                const SizedBox(height: 12),
                _buildInfoRow('Gender',
                    _userProfile!['gender'] ?? 'Not specified', Icons.person),
                const SizedBox(height: 12),
                _buildInfoRow('Birthday',
                    _formatDate(_userProfile!['date_of_birth']), Icons.cake),
                const SizedBox(height: 12),
                _buildInfoRow(
                    'Location',
                    _userProfile!['location_city'] ?? 'Not specified',
                    Icons.location_on),
                const SizedBox(height: 12),
                _buildInfoRow('Email', _userProfile!['email'] ?? 'Not provided',
                    Icons.email),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About Me
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
                Text(
                  'About Me',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userProfile!['bio'] ?? 'No bio available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Emergency Contact
          if (_userProfile!['emergency_contact_name'] != null ||
              _userProfile!['emergency_contact_phone'] != null)
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
                  Text(
                    'Emergency Contact',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      'Name',
                      _userProfile!['emergency_contact_name'] ?? 'Not provided',
                      Icons.person),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      'Telephone',
                      _userProfile!['emergency_contact_phone'] ??
                          'Not provided',
                      Icons.phone),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Job Types Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Job Types',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_helperJobTypes.length} job types selected',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/helper/profile/jobs/edit');
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Job Types List
          if (_helperJobTypes.isEmpty)
            Container(
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
              child: Column(
                children: [
                  const Icon(
                    Icons.work_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Job Types Selected',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select job types to start receiving job requests',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/helper/profile/jobs/edit');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Select Job Types'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _helperJobTypes.length,
              itemBuilder: (context, index) {
                final jobType = _helperJobTypes[index];
                final category = jobType['job_categories'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Row(
                    children: [
                      // Job Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getJobIcon(category?['name'] ?? 'Unknown'),
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Job Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category?['name'] ?? 'Unknown Job Type',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${jobType['hourly_rate']?.toStringAsFixed(0) ?? '2000'}/Hr',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Active',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
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
          // Documents Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documents & Attachments',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_helperDocuments.length} documents uploaded',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/helper/profile/resume/edit');
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Documents List
          if (_helperDocuments.isEmpty)
            Container(
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
              child: Column(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Documents Uploaded',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload certificates and documents to enhance your profile',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/helper/profile/resume/edit');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Upload Documents'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _helperDocuments.length,
              itemBuilder: (context, index) {
                final document = _helperDocuments[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Row(
                    children: [
                      // Document Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getDocumentIcon(document['file_type'] ?? 'unknown'),
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Document Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document['document_name'] ?? 'Unknown Document',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${document['document_type']?.toUpperCase() ?? 'DOCUMENT'} • ${_formatFileSize(document['file_size_bytes'])}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(document['created_at']),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Verification Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getVerificationColor(
                                  document['verification_status'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          document['verification_status']?.toUpperCase() ??
                              'PENDING',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getVerificationColor(
                                document['verification_status']),
                            fontWeight: FontWeight.w600,
                          ),
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
}
