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

class HelperReviewsPage extends StatefulWidget {
  const HelperReviewsPage({super.key});

  @override
  State<HelperReviewsPage> createState() => _HelperReviewsPageState();
}

class _HelperReviewsPageState extends State<HelperReviewsPage> {
  final HelperDataService _helperDataService = HelperDataService();
  final CustomAuthService _authService = CustomAuthService();

  List<Map<String, dynamic>>? _reviews;
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final helperId = currentUser['user_id'];
      print('🔍 Loading reviews for helper: $helperId');

      // Get reviews and statistics in parallel
      final results = await Future.wait([
        _helperDataService.getHelperAllReviews(helperId),
        _helperDataService.getHelperRatingsAndReviews(helperId),
      ]);

      setState(() {
        _reviews = results[0] as List<Map<String, dynamic>>;
        _statistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });

      print('✅ Loaded ${_reviews?.length ?? 0} reviews');
    } catch (e) {
      print('❌ Error loading reviews: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
                title: 'My Reviews'.tr(),
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : _buildContent(),
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
          SizedBox(height: 16),
          Text(
            'Loading reviews...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            'Failed to load reviews',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Please try again later',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReviews,
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
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistics Summary
          _buildStatisticsSummary(),

          const SizedBox(height: 20),

          // Reviews List
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildStatisticsSummary() {
    final averageRating = (_statistics?['average_rating'] ?? 0.0).toDouble();
    final totalReviews = _statistics?['total_reviews'] ?? 0;
    final allReviews = _statistics?['reviews'] as List<dynamic>? ?? [];

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
            'Review Summary'.tr(),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                'Average Rating',
                averageRating.toStringAsFixed(1),
                Icons.star,
                AppColors.warning,
              ),
              _buildSummaryDivider(),
              _buildSummaryItem(
                'Total Reviews',
                totalReviews.toString(),
                Icons.rate_review,
                AppColors.primaryGreen,
              ),
              _buildSummaryDivider(),
              _buildSummaryItem(
                'All Reviews',
                allReviews.length.toString(),
                Icons.reviews,
                AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.tr(),
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

  Widget _buildSummaryDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildReviewsList() {
    // Use the reviews from statistics if available, otherwise use the reviews list
    final allReviews =
        _statistics?['reviews'] as List<dynamic>? ?? _reviews ?? [];

    if (allReviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
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
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Reviews Yet'.tr(),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete more jobs to receive reviews from helpees'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'All Reviews (${allReviews.length})'.tr(),
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...(allReviews.asMap().entries.map((entry) {
            final index = entry.key;
            final review = entry.value as Map<String, dynamic>;
            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1, color: AppColors.borderLight),
                _buildReviewItem(review),
              ],
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final reviewer = review['reviewer'];
    final reviewerName = reviewer != null
        ? '${reviewer['first_name'] ?? ''} ${reviewer['last_name'] ?? ''}'
            .trim()
        : 'Helpee';
    final reviewText =
        review['review'] ?? review['review_text'] ?? 'No review text provided';
    final rating = review['rating'] ?? 0;
    final date = _formatReviewDate(review['created_at']);
    final reviewerImageUrl = reviewer?['profile_image_url'];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer Info and Rating
          Row(
            children: [
              // Profile Image
              ProfileImageWidget(
                imageUrl: reviewerImageUrl,
                size: 48,
                fallbackText: reviewerName.isNotEmpty
                    ? reviewerName[0].toUpperCase()
                    : 'H',
              ),
              const SizedBox(width: 12),

              // Name and Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Star Rating
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: AppColors.warning,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          date,
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

          const SizedBox(height: 12),

          // Review Text
          if (reviewText.isNotEmpty &&
              reviewText != 'No review text provided') ...[
            Text(
              reviewText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              'No written review provided'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(String? dateString) {
    if (dateString == null) return 'Recently';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 1) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months == 1 ? '' : 's'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years == 1 ? '' : 's'} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
