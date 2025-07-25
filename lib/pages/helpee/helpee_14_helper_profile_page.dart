import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/common/profile_image_widget.dart';
import '../../services/helper_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../../services/messaging_service.dart';
import '../../services/webrtc_calling_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Helpee14HelperProfilePage extends StatefulWidget {
  final String? helperId;
  final Map<String, dynamic>? helperData;
  final bool isSelectionMode;
  final String? returnRoute;

  const Helpee14HelperProfilePage({
    Key? key,
    this.helperId,
    this.helperData,
    this.isSelectionMode = false,
    this.returnRoute,
  }) : super(key: key);

  @override
  State<Helpee14HelperProfilePage> createState() =>
      _Helpee14HelperProfilePageState();
}

class _Helpee14HelperProfilePageState extends State<Helpee14HelperProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final HelperDataService _helperDataService = HelperDataService();
  Map<String, dynamic>? _helperProfile;
  List<Map<String, dynamic>>? _emergencyContacts;
  bool _isLoading = true;
  String? _error;
  String? _helperId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _loadHelperProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHelperProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Prioritize helperId from the widget property first
      if (widget.helperId != null && widget.helperId!.isNotEmpty) {
        _helperId = widget.helperId;
      }
      // Then, check inside helperData, which is where GoRouter puts `extra`
      else if (widget.helperData != null &&
          widget.helperData!['helperId'] != null) {
        _helperId = widget.helperData!['helperId'];
      }

      if (_helperId == null || _helperId!.isEmpty) {
        setState(() {
          _error = 'No helper ID provided';
          _isLoading = false;
        });
        print('❌ No helper ID could be found in widget props or extra data.');
        return;
      }

      print('🆔 Found helperId: $_helperId. Fetching profile...');

      // Load helper profile and latest reviews in parallel
      final results = await Future.wait([
        _helperDataService.getHelperProfileForHelpee(_helperId!),
        _helperDataService.getHelperLatestReviews(_helperId!),
      ]);

      var profile = results[0] as Map<String, dynamic>?;
      final latestReviews = results[1] as List<Map<String, dynamic>>;

      if (profile != null) {
        // Normalise field names for consistency with helper-side page
        profile = {
          ...profile,
          'full_name': profile['full_name'] ??
              '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                  .trim(),
          'phone_number': profile['phone_number'] ?? profile['phone'],
          'bio': profile['about_me'] ?? profile['bio'] ?? 'Professional Helper',
          'average_rating':
              profile['average_rating'] ?? profile['avg_rating'] ?? 0.0,
          'total_reviews':
              profile['total_reviews'] ?? profile['completed_jobs'] ?? 0,
          'profile_image_url':
              profile['profile_image_url'] ?? profile['profile_pic'],
          'latest_reviews': latestReviews,
        };

        // Get emergency contact data
        await _loadEmergencyContacts();

        // Ensure full_name is never empty
        if (profile['full_name'] == null ||
            profile['full_name'].toString().trim().isEmpty) {
          profile['full_name'] = 'Helper';
        }

        setState(() {
          _helperProfile = profile;
          _isLoading = false;
        });
        print('✅ Helper profile loaded successfully: ${profile['full_name']}');
      } else {
        setState(() {
          _error = 'Helper profile not found';
          _isLoading = false;
        });
        print('❌ Helper profile not found');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load helper profile: $e';
        _isLoading = false;
      });
      print('❌ Error loading helper profile: $e');
    }
  }

  Future<void> _loadEmergencyContacts() async {
    if (_helperId == null) return;

    try {
      print('🆘 Loading emergency contacts for helper: $_helperId');

      // First, try to get emergency contacts from the separate emergency_contacts table
      final emergencyContactsResponse = await Supabase.instance.client
          .from('emergency_contacts')
          .select('contact_name, contact_phone')
          .eq('user_id', _helperId!);

      List<Map<String, dynamic>> emergencyContacts = [];

      // Add contacts from emergency_contacts table
      for (var contact in emergencyContactsResponse) {
        emergencyContacts.add({
          'contact_name': contact['contact_name'],
          'contact_phone': contact['contact_phone'],
        });
      }

      // Also check the users table for emergency contact fields
      final userEmergencyResponse = await Supabase.instance.client
          .from('users')
          .select('emergency_contact_name, emergency_contact_phone')
          .eq('id', _helperId!)
          .maybeSingle();

      // Add emergency contact from users table if it exists
      if (userEmergencyResponse != null &&
          userEmergencyResponse['emergency_contact_name'] != null &&
          userEmergencyResponse['emergency_contact_name']
              .toString()
              .isNotEmpty) {
        emergencyContacts.add({
          'contact_name': userEmergencyResponse['emergency_contact_name'],
          'contact_phone': userEmergencyResponse['emergency_contact_phone'] ??
              'No phone provided',
        });
      }

      setState(() {
        _emergencyContacts = emergencyContacts;
      });

      print(
          '✅ Emergency contacts loaded: ${emergencyContacts.length} contacts found');
    } catch (e) {
      print('❌ Error loading emergency contacts: $e');
      setState(() {
        _emergencyContacts = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with standard notification button
          AppHeader(
            title: widget.isSelectionMode
                ? 'Select Helper'.tr()
                : 'Helper Profile'.tr(),
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
          ),

          // Styled Tab Bar directly at the top
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(25),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    height: 50,
                    text: 'Profile',
                  ),
                  Tab(
                    height: 50,
                    text: 'Jobs',
                  ),
                  Tab(
                    height: 50,
                    text: 'Resume',
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.50, 0.00),
                  end: Alignment(0.50, 1.00),
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: _buildContent(),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_error != null) {
      return Center(
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
              _error!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHelperProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_helperProfile == null) {
      return const Center(
        child: Text('No helper profile available'),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfileTab(),
        _buildJobsTab(),
        _buildResumeTab(),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Section
          _buildProfileHeader(),

          // Content with padding
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats Section (Rating | Reviews | Jobs)
                _buildStatsSection(),

                const SizedBox(height: 20),

                // Personal Information Section
                _buildPersonalInfoSection(),

                const SizedBox(height: 20),

                // Reviews Section
                _buildReviewsSection(),

                const SizedBox(height: 20),

                // Emergency Contact Section
                _buildEmergencyContactSection(),

                const SizedBox(height: 20),

                // Action Buttons
                _buildActionButtons(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_isLoading) {
      return Container(
        height: 180,
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

    final name = _helperProfile?['full_name'] ?? 'Unknown Helper';
    final profileImageUrl = _helperProfile?['profile_image_url'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          ProfileImageWidget(
            imageUrl: profileImageUrl,
            size: 120,
            fallbackText: name.isNotEmpty ? name[0].toUpperCase() : 'H',
          ),

          const SizedBox(height: 16),

          // Helper Name
          Text(
            name,
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
    final rating = (_helperProfile?['average_rating'] ?? 0.0).toDouble();
    final totalReviews = _helperProfile?['total_reviews'] ?? 0;
    final totalJobs =
        _helperProfile?['total_jobs'] ?? _helperProfile?['completed_jobs'] ?? 0;

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
            rating.toStringAsFixed(1),
            Icons.star,
            AppColors.warning,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Reviews',
            totalReviews.toString(),
            Icons.rate_review,
            AppColors.primaryGreen,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Jobs',
            totalJobs.toString(),
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
            _helperProfile?['bio'] ??
                _helperProfile?['about_me'] ??
                'Professional helper ready to assist you.',
            isMultiLine: true,
          ),
          const SizedBox(height: 16),

          // Email
          if (_helperProfile?['email'] != null) ...[
            _buildInfoRow(
              Icons.email,
              'Email',
              _helperProfile!['email'],
            ),
            const SizedBox(height: 12),
          ],

          // Phone Number
          if (_helperProfile?['phone_number'] != null ||
              _helperProfile?['phone'] != null) ...[
            _buildInfoRow(
              Icons.phone,
              'Phone Number',
              _helperProfile!['phone_number'] ?? _helperProfile!['phone'],
            ),
            const SizedBox(height: 12),
          ],

          // Location
          if (_helperProfile?['location'] != null ||
              _helperProfile?['location_city'] != null) ...[
            _buildInfoRow(
              Icons.location_on,
              'Location',
              _helperProfile!['location'] ?? _helperProfile!['location_city'],
            ),
            const SizedBox(height: 12),
          ],

          // Age
          _buildInfoRow(
            Icons.calendar_today,
            'Age',
            _calculateAge(_helperProfile?['date_of_birth']),
          ),
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

  Widget _buildJobsTab() {
    final jobTypes = _helperProfile?['job_types'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Categories',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (jobTypes.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
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
                  Icon(
                    Icons.work_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No specific job categories selected',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helper can assist with general tasks',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            ...jobTypes.map((jobType) => _buildJobTypeCard(jobType)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildResumeTab() {
    final documents = _helperProfile?['documents'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qualifications & Documents',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (documents.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
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
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents uploaded yet',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Helper hasn\'t uploaded any certificates or qualifications',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            ...documents
                .map((document) => _buildDocumentCard(document))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
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
            'About',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _helperProfile?['bio'] ??
                'Professional helper ready to assist you.',
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Contact Information
          if (_helperProfile?['location'] != null) ...[
            _buildInfoRow(
                Icons.location_on, 'Location', _helperProfile!['location']),
            const SizedBox(height: 8),
          ],
          if (_helperProfile?['phone_number'] != null) ...[
            _buildInfoRow(
                Icons.phone, 'Phone', _helperProfile!['phone_number']),
            const SizedBox(height: 8),
          ],
          if (_helperProfile?['email'] != null) ...[
            _buildInfoRow(Icons.email, 'Email', _helperProfile!['email']),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
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
            'Emergency Contacts',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_emergencyContacts == null || _emergencyContacts!.isEmpty) ...[
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
                    'No emergency contacts available',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._emergencyContacts!.map((contact) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.contact_emergency,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['contact_name'] ?? 'Unknown',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact['contact_phone'] ?? 'No phone',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Call emergency contact
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Calling ${contact['contact_name']}...'),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.call,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobTypeCard(Map<String, dynamic> jobType) {
    final categoryName =
        jobType['job_categories']?['name'] ?? 'Unknown Service';
    final hourlyRate = jobType['hourly_rate'] ?? 0;
    final experienceLevel = jobType['experience_level'] ?? 'beginner';
    final isActive = jobType['is_active'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.work,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${hourlyRate.toString()}/hr • ${experienceLevel.toString().toUpperCase()}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final documentName = document['document_name'] ?? 'Unknown Document';
    final documentType = document['document_type'] ?? 'document';
    final verificationStatus = document['verification_status'] ?? 'pending';
    final createdAt = document['created_at'] ?? '';

    // Format date
    String dateText = 'Unknown date';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        dateText = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        dateText = 'Invalid date';
      }
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (verificationStatus) {
      case 'verified':
        statusColor = AppColors.success;
        statusText = 'Verified';
        statusIcon = Icons.verified;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusText = 'Pending';
        statusIcon = Icons.pending;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${documentType.toString().toUpperCase()} • $dateText',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final latestReviews = _helperProfile?['latest_reviews'] as List? ?? [];

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
            'Recent Reviews',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (latestReviews.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to leave a review!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...latestReviews.map((review) => _buildReviewItem(review)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final reviewer = review['reviewer'];
    final helpeeName = reviewer != null
        ? '${reviewer['first_name'] ?? ''} ${reviewer['last_name'] ?? ''}'
            .trim()
        : 'Helpee';
    final reviewerImage = reviewer?['profile_image_url'];
    final reviewText = review['review_text'] ?? '';
    final rating = review['rating'] ?? 0;
    final createdAt = review['created_at'] ?? '';

    // Format date
    String timeAgo = 'Recently';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays == 0) {
          timeAgo = 'Today';
        } else if (difference.inDays == 1) {
          timeAgo = 'Yesterday';
        } else if (difference.inDays < 7) {
          timeAgo = '${difference.inDays} days ago';
        } else if (difference.inDays < 30) {
          timeAgo = '${(difference.inDays / 7).floor()} weeks ago';
        } else {
          timeAgo = '${(difference.inDays / 30).floor()} months ago';
        }
      } catch (e) {
        timeAgo = 'Recently';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileImageWidget(
                imageUrl: reviewerImage,
                size: 36,
                fallbackText:
                    helpeeName.isNotEmpty ? helpeeName[0].toUpperCase() : 'H',
                borderWidth: 0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helpeeName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: AppColors.warning,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              reviewText,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openChat(),
            icon: const Icon(Icons.message, size: 18),
            label: Text('Message'.tr()),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen, width: 2),
              foregroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _makeCall(),
            icon: const Icon(Icons.call, size: 18),
            label: Text('Call'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openChat() async {
    try {
      final currentUser = CustomAuthService().currentUser;
      if (currentUser == null || _helperId == null) {
        _showErrorSnackBar('Cannot open chat: user not authenticated'.tr());
        return;
      }

      final currentUserId = currentUser['user_id'];
      final helpeeId = currentUserId; // Current user is helpee
      final helperId = _helperId!; // The helper we're viewing

      // We need a job context for the conversation
      // For now, we'll use a general conversation without specific job
      final conversationId = await MessagingService().getOrCreateConversation(
        jobId:
            '00000000-0000-0000-0000-000000000000', // Use null job ID for general conversation
        helperId: helperId,
        helpeeId: helpeeId,
      );

      if (conversationId != null && mounted) {
        final helperName = _helperProfile?['full_name'] ?? 'Helper';

        context.push('/chat', extra: {
          'conversationId': conversationId,
          'jobId': null,
          'otherUserId': helperId,
          'otherUserName': helperName,
          'jobTitle': null,
        });
      } else {
        _showErrorSnackBar('Failed to open chat'.tr());
      }
    } catch (e) {
      print('❌ Error opening chat: $e');
      _showErrorSnackBar('Error opening chat'.tr());
    }
  }

  Future<void> _makeCall() async {
    try {
      final currentUser = CustomAuthService().currentUser;
      if (currentUser == null || _helperId == null) {
        _showErrorSnackBar('Cannot make call: user not authenticated'.tr());
        return;
      }

      final currentUserId = currentUser['user_id'];
      final helpeeId = currentUserId; // Current user is helpee
      final helperId = _helperId!; // The helper we're viewing

      // Get or create conversation for the call
      final conversationId = await MessagingService().getOrCreateConversation(
        jobId:
            '00000000-0000-0000-0000-000000000000', // Use null job ID for general conversation
        helperId: helperId,
        helpeeId: helpeeId,
      );

      if (conversationId != null) {
        final helperName = _helperProfile?['full_name'] ?? 'Helper';

        // Initialize WebRTC service
        final webrtcService = WebRTCService();
        await webrtcService.initialize();

        final success = await webrtcService.makeCall(
          conversationId: conversationId,
          receiverId: helperId,
          callType: CallType.audio,
        );

        if (success && mounted) {
          context.push('/call', extra: {
            'callType': 'audio',
            'isIncoming': false,
            'otherUserName': helperName,
          });
        } else {
          _showErrorSnackBar('Failed to initiate call'.tr());
        }
      } else {
        _showErrorSnackBar('Failed to initiate call'.tr());
      }
    } catch (e) {
      print('❌ Error making call: $e');
      _showErrorSnackBar('Error making call'.tr());
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildCompactStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Total Jobs & Completed Jobs
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  'Total Jobs',
                  (_helperProfile?['total_jobs'] ?? 0).toString(),
                  Icons.work_outline,
                  AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  'Jobs Completed',
                  (_helperProfile?['completed_jobs'] ?? 0).toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Average Rating & Total Reviews
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  'Average Rating',
                  ((_helperProfile?['average_rating'] ?? 0.0).toDouble())
                      .toStringAsFixed(1),
                  Icons.star_outline,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  'Total Reviews',
                  (_helperProfile?['total_reviews'] ?? 0).toString(),
                  Icons.rate_review_outlined,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
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
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Overview
            _buildPerformanceOverview(),

            const SizedBox(height: 20),

            // Job Statistics
            _buildJobStatistics(),

            const SizedBox(height: 20),

            // Earnings Overview
            _buildEarningsOverview(),

            const SizedBox(height: 20),

            // Time Statistics
            _buildTimeStatistics(),

            const SizedBox(height: 20),

            // Category Performance
            _buildCategoryPerformance(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final avgRating = (_helperProfile?['average_rating'] ?? 0.0).toDouble();
    final totalReviews = _helperProfile?['total_reviews'] ?? 0;
    final completedJobs = _helperProfile?['completed_jobs'] ?? 0;
    final successRate =
        completedJobs > 0 ? (completedJobs / (completedJobs + 1)) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Average Rating',
                  avgRating.toStringAsFixed(1),
                  Icons.star,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Reviews',
                  totalReviews.toString(),
                  Icons.rate_review,
                  AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completed Jobs',
                  completedJobs.toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  '${successRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobStatistics() {
    final totalJobs = _helperProfile?['total_jobs'] ?? 0;
    final completedJobs = _helperProfile?['completed_jobs'] ?? 0;
    final ongoingJobs = _helperProfile?['ongoing_jobs'] ?? 0;
    final pendingJobs = _helperProfile?['pending_jobs'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Statistics',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildJobStatRow('Total Jobs', totalJobs, AppColors.primaryGreen),
          const SizedBox(height: 12),
          _buildJobStatRow('Completed', completedJobs, AppColors.success),
          const SizedBox(height: 12),
          _buildJobStatRow('Ongoing', ongoingJobs, AppColors.warning),
          const SizedBox(height: 12),
          _buildJobStatRow('Pending', pendingJobs, AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview() {
    final totalEarnings = _helperProfile?['total_earnings'] ?? 0.0;
    final avgEarningPerJob = _helperProfile?['avg_earning_per_job'] ?? 0.0;
    final thisMonthEarnings = _helperProfile?['this_month_earnings'] ?? 0.0;
    final lastMonthEarnings = _helperProfile?['last_month_earnings'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Overview',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Earnings',
                  'LKR ${totalEarnings.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Per Job',
                  'LKR ${avgEarningPerJob.toStringAsFixed(0)}',
                  Icons.monetization_on,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  'LKR ${thisMonthEarnings.toStringAsFixed(0)}',
                  Icons.trending_up,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Last Month',
                  'LKR ${lastMonthEarnings.toStringAsFixed(0)}',
                  Icons.history,
                  AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatistics() {
    final totalHours = _helperProfile?['total_hours_worked'] ?? 0;
    final avgHoursPerJob = _helperProfile?['avg_hours_per_job'] ?? 0.0;
    final thisMonthHours = _helperProfile?['this_month_hours'] ?? 0;
    final responseTime = _helperProfile?['avg_response_time'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Statistics',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Hours',
                  '${totalHours}h',
                  Icons.access_time,
                  AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Per Job',
                  '${avgHoursPerJob.toStringAsFixed(1)}h',
                  Icons.schedule,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '${thisMonthHours}h',
                  Icons.calendar_today,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Response Time',
                  '${responseTime}min',
                  Icons.speed,
                  AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance() {
    final categoryStats = _helperProfile?['category_stats'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Performance',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (categoryStats.isEmpty)
            Center(
              child: Text(
                'No category data available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...categoryStats.map<Widget>((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryStatRow(
                  category['name'] ?? 'Unknown',
                  category['completed_jobs'] ?? 0,
                  category['total_earnings'] ?? 0.0,
                  category['avg_rating'] ?? 0.0,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobStatRow(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStatRow(
      String category, int jobs, double earnings, double rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$jobs jobs',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'LKR ${earnings.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
