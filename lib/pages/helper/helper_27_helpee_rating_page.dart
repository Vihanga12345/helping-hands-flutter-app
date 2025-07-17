import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/supabase_service.dart';

class Helper27HelpeeRatingPage extends StatefulWidget {
  final String? helpeeId;
  final Map<String, dynamic>? helpeeData;

  const Helper27HelpeeRatingPage({
    Key? key,
    this.helpeeId,
    this.helpeeData,
  }) : super(key: key);

  @override
  State<Helper27HelpeeRatingPage> createState() =>
      _Helper27HelpeeRatingPageState();
}

class _Helper27HelpeeRatingPageState extends State<Helper27HelpeeRatingPage> {
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  Map<String, dynamic>? _helpeeProfile;
  Map<String, dynamic>? _helpeeStatistics;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error;
  String? _helpeeId;

  @override
  void initState() {
    super.initState();
    _loadHelpeeProfile();
  }

  Future<void> _loadHelpeeProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get helpee ID from widget properties or passed data
      if (widget.helpeeId != null && widget.helpeeId!.isNotEmpty) {
        _helpeeId = widget.helpeeId;
      } else if (widget.helpeeData != null &&
          widget.helpeeData!['helpeeId'] != null) {
        _helpeeId = widget.helpeeData!['helpeeId'];
      }

      if (_helpeeId == null || _helpeeId!.isEmpty) {
        setState(() {
          _error = 'No helpee ID provided';
          _isLoading = false;
        });
        return;
      }

      print('📋 Loading helpee profile: $_helpeeId');

      // Load helpee profile and statistics
      final results = await Future.wait([
        SupabaseService().getUserProfile(_helpeeId!),
        _userDataService.getUserStatistics(_helpeeId!),
        _loadReviews(),
      ]);

      setState(() {
        _helpeeProfile = results[0] as Map<String, dynamic>?;
        _helpeeStatistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });

      print('✅ Helpee profile loaded successfully');
    } catch (e) {
      print('❌ Error loading helpee profile: $e');
      setState(() {
        _error = 'Failed to load helpee profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadReviews() async {
    if (_helpeeId == null) return [];

    try {
      // This should load reviews FROM helpers ABOUT this helpee
      // For now, return mock data - in real app, implement proper review fetching
      final mockReviews = [
        {
          'reviewer': {
            'first_name': 'Maria',
            'last_name': 'Silva',
            'profile_image_url': null,
          },
          'rating': 5,
          'review':
              'Excellent helpee! Very clear instructions and fair payment.',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        },
        {
          'reviewer': {
            'first_name': 'John',
            'last_name': 'Doe',
            'profile_image_url': null,
          },
          'rating': 4,
          'review': 'Good communication and timely payments. Recommended!',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
        },
        {
          'reviewer': {
            'first_name': 'Ahmed',
            'last_name': 'Hassan',
            'profile_image_url': null,
          },
          'rating': 5,
          'review':
              'Very professional and respectful. Great working experience.',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 10))
              .toIso8601String(),
        },
      ];

      setState(() {
        _reviews = mockReviews;
      });

      return mockReviews;
    } catch (e) {
      print('❌ Error loading reviews: $e');
      return [];
    }
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
              // Header
              AppHeader(
                title: 'Helpee Profile',
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen),
                        ),
                      )
                    : _error != null
                        ? _buildErrorState()
                        : SingleChildScrollView(
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

                                // Reviews Section
                                _buildReviewsSection(),

                                const SizedBox(height: 20),

                                // Emergency Contact Section
                                _buildEmergencyContactSection(),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.activity,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final firstName = _helpeeProfile?['first_name'] ?? '';
    final lastName = _helpeeProfile?['last_name'] ?? '';
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
              backgroundImage: _helpeeProfile?['profile_image_url'] != null
                  ? NetworkImage(_helpeeProfile!['profile_image_url'])
                  : null,
              child: _helpeeProfile?['profile_image_url'] == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'H',
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
            displayName.isNotEmpty ? displayName : 'Helpee',
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
    final rating = (_helpeeStatistics?['rating'] ?? 0.0).toDouble();
    final totalReviews = _helpeeStatistics?['total_reviews'] ?? 0;
    final totalJobs = _helpeeStatistics?['total_jobs'] ?? 0;

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
            _helpeeProfile?['about_me'] ?? 'No bio available',
            isMultiLine: true,
          ),
          const SizedBox(height: 16),

          // Email
          if (_helpeeProfile?['email'] != null) ...[
            _buildInfoRow(
              Icons.email,
              'Email',
              _helpeeProfile!['email'],
            ),
            const SizedBox(height: 12),
          ],

          // Phone Number
          if (_helpeeProfile?['phone'] != null) ...[
            _buildInfoRow(
              Icons.phone,
              'Phone Number',
              _helpeeProfile!['phone'],
            ),
            const SizedBox(height: 12),
          ],

          // Location
          if (_helpeeProfile?['location_city'] != null ||
              _helpeeProfile?['location_address'] != null) ...[
            _buildInfoRow(
              Icons.location_on,
              'Location',
              _helpeeProfile!['location_city'] ??
                  _helpeeProfile!['location_address'] ??
                  'Not provided',
            ),
            const SizedBox(height: 12),
          ],

          // Age
          _buildInfoRow(
            Icons.calendar_today,
            'Age',
            _calculateAge(_helpeeProfile?['date_of_birth']),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
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
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty) ...[
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
                    'Reviews from helpers will appear here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._reviews.take(3).map((review) {
              return _buildReviewItem(review);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    final emergencyName = _helpeeProfile?['emergency_contact_name'];
    final emergencyPhone = _helpeeProfile?['emergency_contact_phone'];

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
              Icons.person,
              'Name',
              emergencyName ?? 'Not provided',
            ),
            const SizedBox(height: 12),

            // Phone
            _buildInfoRow(
              Icons.phone,
              'Phone',
              emergencyPhone ?? 'Not provided',
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

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final reviewerName = review['reviewer'] != null
        ? '${review['reviewer']['first_name'] ?? ''} ${review['reviewer']['last_name'] ?? ''}'
            .trim()
        : 'Anonymous Helper';
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
                        reviewerName.isNotEmpty
                            ? reviewerName[0].toUpperCase()
                            : 'H',
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
                      reviewerName,
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
            Text(
              'Unable to load profile',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHelpeeProfile,
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
}
