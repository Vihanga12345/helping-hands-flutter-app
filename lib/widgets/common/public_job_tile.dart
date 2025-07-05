import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/job_action_buttons.dart';

class PublicJobTile extends StatefulWidget {
  final Map<String, dynamic> job;

  const PublicJobTile({super.key, required this.job});

  @override
  State<PublicJobTile> createState() => _PublicJobTileState();
}

class _PublicJobTileState extends State<PublicJobTile> {
  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final bool isPrivate = job['is_private'] == true;

    return Column(
      children: [
        GestureDetector(
      onTap: () {
        // Navigate to comprehensive job detail page, passing the job ID
        final jobId = job['id'] as String;
        context.push('/helper/comprehensive-job-detail/$jobId');
      },
      child: Container(
            padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Header with title and status
            Row(
              children: [
                    Expanded(
                      child: Text(
                        job['title'] ?? 'Unknown Job',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                        color: isPrivate
                            ? AppColors.primaryGreen.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                      child: Text(
                        isPrivate ? 'PRIVATE' : 'PUBLIC',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isPrivate
                              ? AppColors.primaryGreen
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pay rate
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        job['pay'] ?? 'Rate not set',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info pills
                _buildInfoPill(job['date'] ?? 'Date not set'),
                const SizedBox(height: 8),
                _buildInfoPill(job['time'] ?? 'Time not set'),
                const SizedBox(height: 8),
                _buildInfoPill(job['location'] ?? 'Location not set'),
                const SizedBox(height: 16),

                // Category info pill
                _buildCategoryPill(job['category'] ?? 'General'),
                const SizedBox(height: 16),

                // Client info
                if (job['helpee_name'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client Information',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['helpee_name'] ?? 'Unknown Client',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (job['helpee_location'] != null)
                          Text(
                            job['helpee_location'],
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons for requests
                JobActionButtons(
                  job: job,
                  userType: 'helper',
                  onJobUpdated: () => setState(() {}),
                  showTimer: false, // No timer for request tiles
                ),
              ],
            ),
          ),
            ),
            const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoPill(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '🔧 $category',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
