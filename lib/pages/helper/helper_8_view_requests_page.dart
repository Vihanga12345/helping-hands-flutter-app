import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/common/public_job_tile.dart';

class Helper8ViewRequestsPage extends StatefulWidget {
  final int initialTabIndex;

  const Helper8ViewRequestsPage({super.key, this.initialTabIndex = 0});

  @override
  State<Helper8ViewRequestsPage> createState() =>
      _Helper8ViewRequestsPageState();
}

class _Helper8ViewRequestsPageState extends State<Helper8ViewRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();
  late Future<List<Map<String, dynamic>>> _publicJobsFuture;
  late Future<List<Map<String, dynamic>>> _privateJobsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final helperId = currentUser['user_id'];
      _privateJobsFuture =
          _jobDataService.getPrivateJobRequestsForHelper(helperId);
      _publicJobsFuture = _jobDataService.getPublicJobRequests(helperId);
    } else {
      _privateJobsFuture = Future.value([]);
      _publicJobsFuture = Future.value([]);
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
              AppHeader(
                title: 'View Requests',
                showMenuButton: true,
                showNotificationButton: true,
                onMenuPressed: () => context.push('/helper/menu'),
                onNotificationPressed: () =>
                    context.push('/helper/notifications'),
              ),

              // Styled TabBar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: AppTextStyles.buttonMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: AppTextStyles.buttonMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Private Requests'))),
                      Tab(
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Public Jobs'))),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Live Private Job Requests List
                    _buildPrivateJobsList(),
                    // Live Public Jobs List
                    _buildPublicJobsList(),
                  ],
                ),
              ),

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

  Widget _buildPrivateJobsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _privateJobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading private requests: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No private requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Private job requests assigned\nto you will appear here',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final jobs = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            return PublicJobTile(job: jobs[index]);
          },
        );
      },
    );
  }

  Widget _buildPublicJobsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _publicJobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading public jobs: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No public jobs available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Public job opportunities\nwill appear here',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final jobs = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            return PublicJobTile(job: jobs[index]);
          },
        );
      },
    );
  }

  Widget _buildComingSoon(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.construction,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            '$feature Coming Soon',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 10),
          const Text(
            'This feature is under development.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
