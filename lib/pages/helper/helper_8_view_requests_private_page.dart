import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';

class Helper8ViewRequestsPrivatePage extends StatefulWidget {
  const Helper8ViewRequestsPrivatePage({super.key});

  @override
  State<Helper8ViewRequestsPrivatePage> createState() =>
      _Helper8ViewRequestsPrivatePageState();
}

class _Helper8ViewRequestsPrivatePageState
    extends State<Helper8ViewRequestsPrivatePage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'Urgent', 'High Pay', 'Nearby'];

  final List<Map<String, dynamic>> _privateRequests = [
    {
      'id': 'PR001',
      'title': 'House Cleaning - Luxury Villa',
      'location': 'Colombo 07, 0.8 km away',
      'pay': 'LKR 5,000',
      'duration': '6 hours',
      'date': 'Dec 25, 2024',
      'time': '9:00 AM',
      'description': 'Deep cleaning of 5-bedroom villa with pool area',
      'helpeeRating': 4.9,
      'isUrgent': true,
    },
    {
      'id': 'PR002',
      'title': 'Kitchen Deep Clean',
      'location': 'Dehiwala, 1.2 km away',
      'pay': 'LKR 3,500',
      'duration': '4 hours',
      'date': 'Dec 26, 2024',
      'time': '2:00 PM',
      'description': 'Post-party kitchen cleaning, grease removal',
      'helpeeRating': 4.7,
      'isUrgent': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Private Requests',
            showBackButton: true,
            showMenuButton: true,
            showNotificationButton: true,
            onMenuPressed: () {
              context.push('/helper/menu');
            },
            onNotificationPressed: () {
              context.push('/helper/notifications');
            },
          ),
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
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock,
                                color: AppColors.primaryGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Private requests sent directly to you',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Requests List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _privateRequests.length,
                        itemBuilder: (context, index) {
                          final request = _privateRequests[index];
                          return _buildRequestCard(request);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: request['isUrgent']
            ? Border.all(color: AppColors.error, width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request['title'],
                    style: TextStyle().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (request['isUrgent'])
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'URGENT',
                      style: TextStyle().copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(request['location'], style: TextStyle()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${request['date']} at ${request['time']}',
                    style: TextStyle()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request['pay'],
                    style: TextStyle().copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(request['duration'], style: TextStyle()),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 16),
                    Text(' ${request['helpeeRating']}', style: TextStyle()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(request['description'], style: TextStyle()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to job detail page to view full details
                      context.push('/helper/job-detail');
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Accepted ${request['id']}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
