import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/admin_data_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/admin/jobs_visible_toggle_switch.dart';
import '../../widgets/common/profile_image_widget.dart';

class AdminUsersHelpersPage extends StatefulWidget {
  const AdminUsersHelpersPage({super.key});

  @override
  State<AdminUsersHelpersPage> createState() => _AdminUsersHelpersPageState();
}

class _AdminUsersHelpersPageState extends State<AdminUsersHelpersPage> {
  final AdminDataService _adminData = AdminDataService();
  List<Map<String, dynamic>> _helpers = [];
  Map<String, int> _visibilityStats = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'rating', 'jobs', 'status'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final helpers = await _adminData.getAllHelpers();
      final stats = await _adminData.getHelperVisibilityStats();

      if (mounted) {
        setState(() {
          _helpers = helpers;
          _visibilityStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load helpers: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onHelperVisibilityChanged(String helperId, bool newValue) {
    setState(() {
      final helperIndex = _helpers.indexWhere((h) => h['id'] == helperId);
      if (helperIndex != -1) {
        _helpers[helperIndex]['jobs_visible'] = newValue;

        // Update stats
        if (newValue) {
          _visibilityStats['visible_helpers'] =
              (_visibilityStats['visible_helpers'] ?? 0) + 1;
          _visibilityStats['restricted_helpers'] =
              (_visibilityStats['restricted_helpers'] ?? 1) - 1;
        } else {
          _visibilityStats['visible_helpers'] =
              (_visibilityStats['visible_helpers'] ?? 1) - 1;
          _visibilityStats['restricted_helpers'] =
              (_visibilityStats['restricted_helpers'] ?? 0) + 1;
        }
      }
    });
  }

  List<Map<String, dynamic>> get _filteredAndSortedHelpers {
    var filtered = _helpers.where((helper) {
      if (_searchQuery.isEmpty) return true;

      final name = '${helper['first_name'] ?? ''} ${helper['last_name'] ?? ''}'
          .toLowerCase();
      final email = (helper['email'] ?? '').toLowerCase();
      final location = (helper['location_city'] ?? '').toLowerCase();

      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          location.contains(_searchQuery.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      int compare = 0;
      switch (_sortBy) {
        case 'name':
          final nameA =
              '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
          final nameB =
              '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
          compare = nameA.compareTo(nameB);
          break;
        case 'rating':
          final ratingA = (a['rating'] ?? 0.0).toDouble();
          final ratingB = (b['rating'] ?? 0.0).toDouble();
          compare = ratingA.compareTo(ratingB);
          break;
        case 'jobs':
          final jobsA = a['total_jobs_completed'] ?? 0;
          final jobsB = b['total_jobs_completed'] ?? 0;
          compare = jobsA.compareTo(jobsB);
          break;
        case 'status':
          final statusA = a['jobs_visible'] ?? true;
          final statusB = b['jobs_visible'] ?? true;
          compare = statusA == statusB ? 0 : (statusA ? 1 : -1);
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Helpers Management'.tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/admin/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildHelpersContent(),
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
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: Text('Retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpersContent() {
    return Column(
      children: [
        _buildStatsCard(),
        _buildSearchAndSort(),
        Expanded(
          child: _buildHelpersList(),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final totalHelpers = _visibilityStats['total_helpers'] ?? 0;
    final visibleHelpers = _visibilityStats['visible_helpers'] ?? 0;
    final restrictedHelpers = _visibilityStats['restricted_helpers'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Helper Visibility Overview'.tr(),
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Helpers',
                  totalHelpers.toString(),
                  Icons.people,
                  AppColors.primaryBlue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Jobs Visible',
                  visibleHelpers.toString(),
                  Icons.visibility,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Restricted',
                  restrictedHelpers.toString(),
                  Icons.visibility_off,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.tr(),
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search helpers by name, email, or location...'.tr(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Sort Options
          Row(
            children: [
              Text('Sort by:'.tr(), style: AppTextStyles.bodyMedium),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                  items: [
                    DropdownMenuItem(value: 'name', child: Text('Name'.tr())),
                    DropdownMenuItem(
                        value: 'rating', child: Text('Rating'.tr())),
                    DropdownMenuItem(
                        value: 'jobs', child: Text('Jobs Completed'.tr())),
                    DropdownMenuItem(
                        value: 'status', child: Text('Visibility Status'.tr())),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpersList() {
    final filteredHelpers = _filteredAndSortedHelpers;

    if (filteredHelpers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No helpers found matching your search'.tr()
                  : 'No helpers found'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredHelpers.length,
      itemBuilder: (context, index) {
        final helper = filteredHelpers[index];
        return _buildHelperCard(helper);
      },
    );
  }

  Widget _buildHelperCard(Map<String, dynamic> helper) {
    final String helperId = helper['id'] ?? '';
    final String firstName = helper['first_name'] ?? '';
    final String lastName = helper['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String email = helper['email'] ?? '';
    final String phone = helper['phone'] ?? '';
    final String location = helper['location_city'] ?? '';
    final double rating = (helper['rating'] ?? 0.0).toDouble();
    final int totalJobs = helper['total_jobs_completed'] ?? 0;
    final bool jobsVisible = helper['jobs_visible'] ?? true;
    final String profileImageUrl = helper['profile_image_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/admin/helper-profile/$helperId'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Profile Image
                  ProfileImageWidget(
                    imageUrl: profileImageUrl,
                    fallbackText:
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'H',
                    size: 60,
                  ),
                  const SizedBox(width: 16),
                  // Helper Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : 'Unknown Helper',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Rating and Jobs
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (rating > 0) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '$totalJobs ${'jobs'.tr()}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Jobs Visibility Toggle
              JobsVisibleToggleSwitch(
                helperId: helperId,
                helperName: fullName,
                initialValue: jobsVisible,
                onChanged: (value) =>
                    _onHelperVisibilityChanged(helperId, value),
                showLabel: true,
                isCompact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
