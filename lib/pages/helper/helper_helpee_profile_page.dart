import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/helper_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../common/report_page.dart';
import '../../services/messaging_service.dart';
import '../../services/webrtc_calling_service.dart';

class HelperHelpeeProfilePage extends StatefulWidget {
  final Map<String, dynamic>? helpeeData;
  final Map<String, dynamic>? helpeeStats;
  final String? helpeeId;

  const HelperHelpeeProfilePage({
    super.key,
    this.helpeeData,
    this.helpeeStats,
    this.helpeeId,
  });

  @override
  State<HelperHelpeeProfilePage> createState() =>
      _HelperHelpeeProfilePageState();
}

class _HelperHelpeeProfilePageState extends State<HelperHelpeeProfilePage> {
  final HelperDataService _helperDataService = HelperDataService();

  Map<String, dynamic>? _helpeeProfile;
  Map<String, dynamic>? _helpeeStatistics;
  List<Map<String, dynamic>>? _helpeeReviews;
  List<Map<String, dynamic>>? _emergencyContacts;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadHelpeeData();
    }
  }

  Future<void> _loadHelpeeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Extract helpee ID from navigation or widget params
      final extra =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final helpeeId = widget.helpeeId ??
          extra?['helpeeId'] ??
          widget.helpeeData?['id'] ??
          (context.mounted
              ? GoRouter.of(context).routerDelegate.currentConfiguration.extra
                  as Map<String, dynamic>?
              : null)?['helpeeId'];

      if (helpeeId == null) {
        throw Exception('Helpee ID not found');
      }

      print('🔍 Loading helpee data for ID: $helpeeId');

      // Load all helpee data in parallel
      final results = await Future.wait([
        _helperDataService.getHelpeeProfileForHelper(helpeeId),
        _helperDataService.getHelpeeJobStatistics(helpeeId),
        _helperDataService.getHelpeeRatingsAndReviews(helpeeId),
      ]);

      setState(() {
        _helpeeProfile = results[0] as Map<String, dynamic>?;
        _helpeeStatistics = results[1] as Map<String, dynamic>;
        _helpeeReviews = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      print('✅ Helpee data loaded successfully');
    } catch (e) {
      print('❌ Error loading helpee data: $e');
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
                title: 'Helpee Profile'.tr(),
                showBackButton: true,
                onBackPressed: () => context.pop(),
                rightWidget: IconButton(
                  icon: const Icon(Icons.report),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ReportPage(userType: 'helper'),
                    ),
                  ),
                ),
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
                currentTab: NavigationTab.home,
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
            'Loading helpee profile...',
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
            'Failed to load helpee profile',
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
            onPressed: _loadHelpeeData,
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
    final firstName = _helpeeProfile?['first_name'] ?? 'Unknown';
    final lastName = _helpeeProfile?['last_name'] ?? 'User';
    final fullName = '$firstName $lastName'.trim();
    final profileImageUrl = _helpeeProfile?['profile_image_url'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
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
              backgroundImage:
                  profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
              child: profileImageUrl == null || profileImageUrl.isEmpty
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'H',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Helpee Name
          Text(
            fullName,
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
    final rating = (_helpeeStatistics?['average_rating'] ?? 0.0).toDouble();
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

  Widget _buildStatItem(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildPersonalInfoSection() {
    final location = _helpeeProfile?['location_city'] ?? 'Not specified';
    final phone = _helpeeProfile?['phone'] ?? 'Not provided';
    final email = _helpeeProfile?['email'] ?? 'Not provided';
    final memberSince = _helpeeStatistics?['member_since'] ?? 'Recently';
    final age = _helpeeProfile?['age']?.toString() ?? 'Not specified';
    final aboutMe = _helpeeProfile?['about_me'] ?? 'No description provided.';

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
            'Personal Information'.tr(),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.info_outline, 'About me'.tr(), aboutMe),
          _buildInfoRow(Icons.email, 'Email'.tr(), email),
          _buildInfoRow(Icons.phone, 'Phone'.tr(), phone),
          _buildInfoRow(Icons.location_on, 'Location'.tr(), location),
          _buildInfoRow(Icons.cake, 'Age'.tr(), age),
          _buildInfoRow(Icons.access_time, 'Member since'.tr(), memberSince),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final totalReviews = _helpeeStatistics?['total_reviews'] ?? 0;

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
          Row(
            children: [
              Text(
                'Reviews from Helpers'.tr(),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$totalReviews ${'reviews'.tr()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_helpeeReviews?.isNotEmpty == true)
            ..._helpeeReviews!
                .take(3)
                .map((review) => _buildReviewItem(review))
                .toList()
          else
            _buildEmptyReviews(),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final reviewerName = review['helper'] != null
        ? '${review['helper']['first_name']} ${review['helper']['last_name'].substring(0, 1)}.'
        : 'Helper';
    final reviewText = review['review_text'] ?? 'No review text provided';
    final rating = review['rating'] ?? 0;
    final date = _formatReviewDate(review['created_at']);
    final reviewerImageUrl = review['helper']?['profile_image_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGreen,
                backgroundImage:
                    reviewerImageUrl != null && reviewerImageUrl.isNotEmpty
                        ? NetworkImage(reviewerImageUrl)
                        : null,
                child: reviewerImageUrl == null || reviewerImageUrl.isEmpty
                    ? Text(
                        reviewerName.isNotEmpty
                            ? reviewerName[0].toUpperCase()
                            : 'H',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reviewerName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.warning,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reviewText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No reviews yet'.tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    final emergencyName = _helpeeProfile?['emergency_contact_name'];
    final emergencyPhone = _helpeeProfile?['emergency_contact_phone'];

    if (emergencyName == null && emergencyPhone == null) {
      return const SizedBox.shrink();
    }

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
            'Emergency Contact'.tr(),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (emergencyName != null)
            _buildInfoRow(Icons.person, 'Name'.tr(), emergencyName),
          if (emergencyPhone != null)
            _buildInfoRow(Icons.phone, 'Phone'.tr(), emergencyPhone),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openChat,
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
            onPressed: _makeCall,
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

  String _formatReviewDate(String? dateString) {
    if (dateString == null) return 'Recently';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 1) {
        return 'Today';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
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

  Future<void> _openChat() async {
    try {
      final currentUser = CustomAuthService().currentUser;
      if (currentUser == null || _helpeeProfile == null) {
        _showErrorSnackBar('Cannot open chat: user not authenticated'.tr());
        return;
      }

      final currentUserId = currentUser['user_id'];
      final helperId = currentUserId; // Current user is helper
      final helpeeId =
          _helpeeProfile!['id'] ?? widget.helpeeId; // The helpee we're viewing

      if (helpeeId == null) {
        _showErrorSnackBar('Cannot open chat: helpee not found'.tr());
        return;
      }

      // Get or create conversation
      final conversationId = await MessagingService().getOrCreateConversation(
        jobId:
            '00000000-0000-0000-0000-000000000000', // Use null job ID for general conversation
        helperId: helperId,
        helpeeId: helpeeId,
      );

      if (conversationId != null && mounted) {
        final helpeeName =
            '${_helpeeProfile!['first_name'] ?? ''} ${_helpeeProfile!['last_name'] ?? ''}'
                .trim();

        context.push('/chat', extra: {
          'conversationId': conversationId,
          'jobId': null,
          'otherUserId': helpeeId,
          'otherUserName': helpeeName.isNotEmpty ? helpeeName : 'Helpee',
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
      if (currentUser == null || _helpeeProfile == null) {
        _showErrorSnackBar('Cannot make call: user not authenticated'.tr());
        return;
      }

      final currentUserId = currentUser['user_id'];
      final helperId = currentUserId; // Current user is helper
      final helpeeId =
          _helpeeProfile!['id'] ?? widget.helpeeId; // The helpee we're viewing

      if (helpeeId == null) {
        _showErrorSnackBar('Cannot make call: helpee not found'.tr());
        return;
      }

      // Get or create conversation for the call
      final conversationId = await MessagingService().getOrCreateConversation(
        jobId:
            '00000000-0000-0000-0000-000000000000', // Use null job ID for general conversation
        helperId: helperId,
        helpeeId: helpeeId,
      );

      if (conversationId != null) {
        final helpeeName =
            '${_helpeeProfile!['first_name'] ?? ''} ${_helpeeProfile!['last_name'] ?? ''}'
                .trim();

        // Initialize WebRTC service
        final webrtcService = WebRTCService();
        await webrtcService.initialize();

        final success = await webrtcService.makeCall(
          conversationId: conversationId,
          receiverId: helpeeId,
          callType: CallType.audio,
        );

        if (success && mounted) {
          context.push('/call', extra: {
            'callType': 'audio',
            'isIncoming': false,
            'otherUserName': helpeeName.isNotEmpty ? helpeeName : 'Helpee',
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
}
