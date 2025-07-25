import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../services/admin_data_service.dart';
import '../../utils/date_time_helpers.dart';

class AdminJobsPendingPage extends StatefulWidget {
  const AdminJobsPendingPage({super.key});

  @override
  State<AdminJobsPendingPage> createState() => _AdminJobsPendingPageState();
}

class _AdminJobsPendingPageState extends State<AdminJobsPendingPage> {
  final _adminDataService = AdminDataService();
  List<Map<String, dynamic>> _pendingJobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPendingJobs();
  }

  Future<void> _loadPendingJobs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final jobs = await _adminDataService.getPendingJobs();

      if (mounted) {
        setState(() {
          _pendingJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load pending jobs: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredJobs {
    if (_searchQuery.isEmpty) return _pendingJobs;

    return _pendingJobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final category = (job['category_name'] ?? '').toString().toLowerCase();
      final helpeeName = (job['helpee_name'] ?? '').toString().toLowerCase();
      final location = (job['location'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return title.contains(query) ||
          category.contains(query) ||
          helpeeName.contains(query) ||
          location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Pending Jobs',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.warning,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/admin/home'),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.warning,
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      'Search jobs by title, category, helpee, or location...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.warning),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildJobsContent(isDesktop),
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
            onPressed: _loadPendingJobs,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsContent(bool isDesktop) {
    final filteredJobs = _filteredJobs;

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.pending_actions : Icons.search_off,
              size: 64,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No pending jobs found'
                  : 'No jobs match your search',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingJobs,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count
            Row(
              children: [
                Text(
                  'Found ${filteredJobs.length} pending jobs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadPendingJobs,
                  color: AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Jobs List
            Expanded(
              child: isDesktop
                  ? _buildJobsGrid(filteredJobs)
                  : _buildJobsList(filteredJobs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsGrid(List<Map<String, dynamic>> jobs) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return _buildJobCard(jobs[index], isGrid: true);
      },
    );
  }

  Widget _buildJobsList(List<Map<String, dynamic>> jobs) {
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildJobCard(jobs[index], isGrid: false),
        );
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, {required bool isGrid}) {
    final String title = job['title'] ?? 'Untitled Job';
    final String category = job['category_name'] ?? 'Unknown Category';
    final String helpeeName = job['helpee_name'] ?? 'Unknown Helpee';
    final String location = job['location'] ?? '';
    final String jobId = job['id'] ?? '';
    final bool isPrivate = job['is_private'] ?? false;
    final double? fee = job['fee']?.toDouble();
    final DateTime? createdAt = job['created_at'] != null
        ? DateTime.tryParse(job['created_at'].toString())
        : null;

    return GestureDetector(
      onTap: () => context.go('/admin/jobs/detail/$jobId'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1,
          ),
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
          children: [
            // Header with status and privacy badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: isGrid ? 10 : 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPrivate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PRIVATE',
                      style: TextStyle(
                        fontSize: isGrid ? 10 : 12,
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (fee != null) ...[
                  Text(
                    'Rs. ${fee.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isGrid ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Job Title
            Text(
              title,
              style: TextStyle(
                fontSize: isGrid ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: isGrid ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Category
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: isGrid ? 14 : 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: isGrid ? 12 : 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Helpee Name
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: isGrid ? 14 : 16,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    helpeeName,
                    style: TextStyle(
                      fontSize: isGrid ? 12 : 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: isGrid ? 14 : 16,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: isGrid ? 12 : 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: isGrid ? 14 : 16,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created ${DateTimeHelpers.getTimeAgo(createdAt)}',
                    style: TextStyle(
                      fontSize: isGrid ? 10 : 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
