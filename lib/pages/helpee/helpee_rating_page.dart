import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/rating_service.dart';
import '../../services/custom_auth_service.dart';
import '../../widgets/star_rating_widget.dart';

class HelpeeRatingPage extends StatefulWidget {
  final String jobId;

  const HelpeeRatingPage({
    super.key,
    required this.jobId,
  });

  @override
  State<HelpeeRatingPage> createState() => _HelpeeRatingPageState();
}

class _HelpeeRatingPageState extends State<HelpeeRatingPage> {
  final CustomAuthService _authService = CustomAuthService();
  final TextEditingController _reviewController = TextEditingController();

  int _rating = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _jobDetails;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobDetails =
          await RatingService.getJobDetailsForRating(widget.jobId);

      if (jobDetails != null) {
        setState(() {
          _jobDetails = jobDetails;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load job details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading job details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null || _jobDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not authenticated'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final helperId = _jobDetails!['assigned_helper']['id'];

      final success = await RatingService.submitRating(
        jobId: widget.jobId,
        raterId: currentUser['user_id'],
        ratedUserId: helperId,
        rating: _rating,
        reviewText: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.go('/helpee/home');
      } else {
        throw Exception('Failed to submit rating');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Rate Helper',
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
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : _buildRatingContent(),
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

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
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
              'Error Loading Job',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.error,
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadJobDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingContent() {
    final helper = _jobDetails!['assigned_helper'];
    final jobTitle = _jobDetails!['title'] ?? 'Job';
    final helperName =
        '${helper['first_name'] ?? ''} ${helper['last_name'] ?? ''}'.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Job Info Card
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
                // Helper Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryGreen,
                  backgroundImage: helper['profile_image_url'] != null
                      ? NetworkImage(helper['profile_image_url'])
                      : null,
                  child: helper['profile_image_url'] == null
                      ? Text(
                          helperName.isNotEmpty
                              ? helperName[0].toUpperCase()
                              : 'H',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Helper Name
                Text(
                  helperName.isNotEmpty ? helperName : 'Helper',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Job Title
                Text(
                  jobTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Rating Section
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
                  'How was your experience?',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rate your helper and help others make informed decisions',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Star Rating
                Center(
                  child: StarRatingWidget(
                    initialRating: _rating,
                    onRatingChanged: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                    starSize: 48,
                    activeColor: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 8),

                // Rating Text
                Center(
                  child: Text(
                    _getRatingText(_rating),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Review Section
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
                  'Write a Review (Optional)',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share details about your experience',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Review Text Field
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Tell others about your experience with this helper...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lightGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primaryGreen),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    )
                  : Text(
                      'Submit Rating',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}
