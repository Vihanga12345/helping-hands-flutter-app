import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/helper_data_service.dart';

class Helpee14HelperProfilePage extends StatefulWidget {
  final String? helperId;
  final Map<String, dynamic>? helperData;

  const Helpee14HelperProfilePage({
    Key? key,
    this.helperId,
    this.helperData,
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
      var profile =
          await _helperDataService.getHelperProfileForHelpee(_helperId!);

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
        };

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with standard notification button
          AppHeader(
            title: 'Helper Profile',
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: true,
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
                // Personal Information Card
                _buildPersonalInfoCard(),

                const SizedBox(height: 20),

                // Statistics Section
                _buildCompactStatisticsSection(),

                const SizedBox(height: 20),

                // Reviews Section
                _buildReviewsSection(),

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
    final rating = (_helperProfile?['average_rating'] ?? 0.0).toDouble();
    final totalReviews = _helperProfile?['total_reviews'] ?? 0;
    final profileImageUrl = _helperProfile?['profile_image_url'];
    final isAvailable = _helperProfile?['is_available'] ?? true;
    final availabilityStatus =
        _helperProfile?['availability_status'] ?? 'Available Now';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture with availability indicator
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGreen,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryGreen,
                  backgroundImage:
                      profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                  child: profileImageUrl == null || profileImageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    isAvailable ? Icons.check : Icons.schedule,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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

          const SizedBox(height: 8),

          // Rating and Reviews
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${rating.toStringAsFixed(1)} ($totalReviews reviews)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Availability Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAvailable ? AppColors.success : AppColors.warning,
                width: 1,
              ),
            ),
            child: Text(
              availabilityStatus,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isAvailable ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
    final reviews = _helperProfile?['reviews'] as List? ?? [];

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
          if (reviews.isEmpty) ...[
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
            ...reviews.take(3).map((review) {
              final helpeeName = review['reviewer']?['first_name'] != null
                  ? '${review['reviewer']['first_name']} ${review['reviewer']['last_name'] ?? ''}'
                      .trim()
                  : 'Anonymous';
              final reviewerImage = review['reviewer']?['profile_image_url'];
              final reviewText = review['review'] ?? '';
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

              return _buildReviewItem(
                  helpeeName, reviewText, rating, timeAgo, reviewerImage);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewItem(String helpeeName, String reviewText, int rating,
      String timeAgo, String? reviewerImage) {
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryGreen,
                backgroundImage:
                    reviewerImage != null && reviewerImage.isNotEmpty
                        ? NetworkImage(reviewerImage)
                        : null,
                child: (reviewerImage == null || reviewerImage.isEmpty)
                    ? Text(
                        helpeeName.isNotEmpty
                            ? helpeeName[0].toUpperCase()
                            : 'A',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
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
    final helperName = _helperProfile?['full_name'] ?? 'this helper';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message feature coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Message'),
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
            onPressed: () {
              _showHireDialog(context);
            },
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Hire Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
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

  void _showHireDialog(BuildContext context) {
    final helperName = _helperProfile?['full_name'] ?? 'this helper';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hire Helper',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Do you want to send a job request to $helperName?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Job request sent to $helperName!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Send Request',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
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

          // Row 1: Private Requests & Completed Jobs
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  'Private Requests',
                  (_helperProfile?['private_requests_received'] ?? 0)
                      .toString(),
                  Icons.person_outline,
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

          // Row 2: Average Rating & Response Time
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
                  'Response Time',
                  '${(_helperProfile?['avg_response_time'] ?? 2)} mins',
                  Icons.schedule,
                  AppColors.primaryGreen,
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
