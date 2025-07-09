import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';
import '../../services/localization_service.dart';

class Helpee9SearchHelperPage extends StatefulWidget {
  const Helpee9SearchHelperPage({super.key});

  @override
  State<Helpee9SearchHelperPage> createState() =>
      _Helpee9SearchHelperPageState();
}

class _Helpee9SearchHelperPageState extends State<Helpee9SearchHelperPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  List<Map<String, dynamic>> _allHelpers = [];
  List<Map<String, dynamic>> _filteredHelpers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHelpers();
  }

  Future<void> _loadHelpers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Replace hardcoded sample data with real database query
      final helpers = await _userDataService.getRegisteredHelpers();
      print('🔍 Found ${helpers.length} registered helpers in database');

      // If no helpers found in database, return empty list
      if (helpers.isEmpty) {
        print('⚠️ No helpers found in database');
        _allHelpers = [];
        _filteredHelpers = [];
      } else {
        _allHelpers = List.from(helpers);
        _filteredHelpers = List.from(helpers);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load helpers: $e'.tr();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getSampleHelpers() async {
    // Replace hardcoded sample data with real database query
    try {
      // Query real helpers from database instead of returning sample data
      final helpers = await _userDataService.getRegisteredHelpers();
      print('🔍 Found ${helpers.length} registered helpers in database');

      // If no helpers found in database, return empty list
      if (helpers.isEmpty) {
        print('⚠️ No helpers found in database');
        return [];
      }

      // Transform database helper data to match expected structure
      return helpers.map((helper) {
        return {
          'id': helper['id'],
          'first_name': helper['first_name'] ?? '',
          'last_name': helper['last_name'] ?? '',
          'display_name': helper['display_name'] ??
              '${helper['first_name']} ${helper['last_name']}',
          'location_city': helper['location_city'] ?? 'Unknown',
          'rating': helper['average_rating'] ?? 0.0,
          'total_reviews': helper['total_reviews'] ?? 0,
          'skills': helper['skills'] ?? [],
          'hourly_rate': helper['hourly_rate_default'] ?? 0.0,
          'distance': _calculateDistance(helper), // Calculate based on location
          'is_available': helper['availability_status'] == 'available',
          'profile_image_url': helper['profile_image_url'],
          'total_jobs': helper['total_jobs'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('❌ Error fetching real helpers: $e');
      // Return empty list instead of sample data on error
      return [];
    }
  }

  String _calculateDistance(Map<String, dynamic> helper) {
    // In a real implementation, calculate actual distance based on coordinates
    // For now, return a placeholder
    return 'Distance unknown'.tr();
  }

  void _filterHelpers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHelpers = List.from(_allHelpers);
      } else {
        _filteredHelpers = _allHelpers.where((helper) {
          final name = (helper['display_name'] ?? '').toLowerCase();
          final skills = (helper['skills'] as List<dynamic>? ?? [])
              .map((skill) => skill.toString().toLowerCase())
              .join(' ');
          final location = (helper['location_city'] ?? '').toLowerCase();

          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              skills.contains(searchLower) ||
              location.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Search Helpers'.tr(),
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: true,
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
                    // Search Bar
                    _buildSearchBar(),

                    // Filters
                    _buildFilters(),

                    // Results
                    Expanded(
                      child: _buildSearchResults(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppNavigationBar(
            currentTab: NavigationTab.search,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterHelpers,
        decoration: InputDecoration(
          hintText: 'Search by name, skill, or location...'.tr(),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All'.tr(), true),
          _buildFilterChip('Available Now'.tr(), false),
          _buildFilterChip('Nearby'.tr(), false),
          _buildFilterChip('Top Rated'.tr(), false),
          _buildFilterChip('House Cleaning'.tr(), false),
          _buildFilterChip('Gardening'.tr(), false),
          _buildFilterChip('Cooking'.tr(), false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Implement filter logic here
          setState(() {
            // Update filter state
          });
        },
        selectedColor: AppColors.primaryGreen.withOpacity(0.2),
        checkmarkColor: AppColors.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredHelpers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredHelpers.length,
      itemBuilder: (context, index) {
        final helper = _filteredHelpers[index];
        return _buildHelperCard(helper);
      },
    );
  }

  Widget _buildHelperCard(Map<String, dynamic> helper) {
    final isAvailable = helper['is_available'] ?? false;
    final skills = (helper['skills'] as List<dynamic>? ?? [])
        .map((skill) => skill.toString())
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: HelperProfileBar(
        name: helper['display_name'] ?? 'Unknown Helper'.tr(),
        rating: (helper['rating'] ?? 0.0).toDouble(),
        jobCount: helper['total_jobs'] ?? 0,
        jobTypes: skills,
        profileImageUrl: helper['profile_image_url'],
        helperId: helper['id'],
        helperData: {
          'id': helper['id'],
          'full_name': helper['display_name'],
          'average_rating': helper['rating'],
          'total_reviews': helper['total_reviews'],
          'job_type_names': skills,
          'bio': 'Professional helper ready to assist you'.tr(),
          'location': helper['location_city'],
          'phone_number': helper['phone_number'],
          'email': helper['email'],
          'is_available': isAvailable,
          'availability_status':
              isAvailable ? 'Available Now'.tr() : 'Busy'.tr(),
        },
        onTap: () {
          context.push('/helpee/helper-profile', extra: {
            'helperId': helper['id'],
            'helperData': {
              'id': helper['id'],
              'full_name': helper['display_name'],
              'average_rating': helper['rating'],
              'total_reviews': helper['total_reviews'],
              'job_type_names': skills,
              'bio': 'Professional helper ready to assist you'.tr(),
              'location': helper['location_city'],
              'phone_number': helper['phone_number'],
              'email': helper['email'],
              'is_available': isAvailable,
              'availability_status':
                  isAvailable ? 'Available Now'.tr() : 'Busy'.tr(),
              'response_time': '< 1hr',
              'total_jobs': helper['total_jobs'] ?? 0,
              'experience_years': 1,
              'job_types': [],
              'documents': [],
              'reviews': [],
            },
          });
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      ),
    );
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
              'Unable to load helpers'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error'.tr(),
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHelpers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: Text(
                'Retry'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No helpers found'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters to find more helpers.'
                  .tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _filterHelpers('');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: Text(
                'Clear Search'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
