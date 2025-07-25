import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../services/admin_auth_service.dart';
import '../../widgets/common/app_header.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _adminAuthService = AdminAuthService();
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _adminAuthService.initialize();

    // Check if admin is logged in
    if (!_adminAuthService.isLoggedIn) {
      if (mounted) {
        context.go('/admin/login');
      }
      return;
    }

    await _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stats = await _adminAuthService.getDashboardStats();

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dashboard statistics';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _adminAuthService.logout();
    if (mounted) {
      context.go('/admin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          // Admin profile info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _adminAuthService.currentAdminName ?? 'Admin',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _adminAuthService.currentAdminUsername ?? '',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.white,
                  radius: 18,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDashboardStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGreen,
                  AppColors.darkGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_adminAuthService.currentAdminName ?? 'Admin'}!',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage users, oversee jobs, and monitor your Helping Hands platform',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Users Segment
          _buildSegment(
            'Users',
            Icons.people,
            [
              _buildTile(
                'Helpees',
                'View all helpee profiles',
                Icons.person,
                AppColors.primaryBlue,
                () => context.go('/admin/users/helpees'),
                isDesktop: isDesktop,
              ),
              _buildTile(
                'Helpers',
                'View all helper profiles',
                Icons.person_pin,
                AppColors.primaryOrange,
                () => context.go('/admin/users/helpers'),
                isDesktop: isDesktop,
              ),
            ],
            isDesktop: isDesktop,
          ),

          const SizedBox(height: 32),

          // Jobs Segment
          _buildSegment(
            'Jobs',
            Icons.work,
            [
              _buildTile(
                'Pending Jobs',
                'View pending job requests',
                Icons.pending_actions,
                AppColors.warning,
                () => context.go('/admin/jobs/pending'),
                isDesktop: isDesktop,
              ),
              _buildTile(
                'Ongoing Jobs',
                'Monitor active jobs',
                Icons.work_outline,
                AppColors.primaryGreen,
                () => context.go('/admin/jobs/ongoing'),
                isDesktop: isDesktop,
              ),
              _buildTile(
                'Completed Jobs',
                'Review completed jobs',
                Icons.check_circle,
                AppColors.primaryPurple,
                () => context.go('/admin/jobs/completed'),
                isDesktop: isDesktop,
              ),
            ],
            isDesktop: isDesktop,
          ),

          const SizedBox(height: 32),

          // Reports Segment
          _buildSegment(
            'Reports',
            Icons.analytics,
            [
              _buildTile(
                'View Reports',
                'System reports and analytics',
                Icons.assessment,
                AppColors.error,
                () => context.go('/admin/reports'),
                isDesktop: isDesktop,
              ),
            ],
            isDesktop: isDesktop,
          ),

          const SizedBox(height: 32),

          // Job Management Segment
          _buildSegment(
            'Job Management',
            Icons.settings,
            [
              _buildTile(
                'Create Jobs',
                'Add new job categories and rates',
                Icons.add_business,
                AppColors.darkGreen,
                () => context.go('/admin/job-categories'),
                isDesktop: isDesktop,
              ),
              _buildTile(
                'Job Questions',
                'Manage job-related questions',
                Icons.quiz,
                AppColors.primaryBlue,
                () => context.go('/admin/job-questions'),
                isDesktop: isDesktop,
              ),
            ],
            isDesktop: isDesktop,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSegment(String title, IconData icon, List<Widget> tiles,
      {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segment Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tiles Grid
        if (isDesktop)
          GridView.count(
            crossAxisCount: tiles.length > 2 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: tiles,
          )
        else
          Column(
            children: tiles
                .map((tile) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: tile,
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTile(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap,
      {required bool isDesktop}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: isDesktop ? 32 : 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
