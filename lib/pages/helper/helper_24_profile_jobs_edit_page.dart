import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/helper_data_service.dart';
import '../../services/custom_auth_service.dart';

class Helper24ProfileJobsEditPage extends StatefulWidget {
  const Helper24ProfileJobsEditPage({super.key});

  @override
  State<Helper24ProfileJobsEditPage> createState() =>
      _Helper24ProfileJobsEditPageState();
}

class _Helper24ProfileJobsEditPageState
    extends State<Helper24ProfileJobsEditPage> {
  final HelperDataService _helperDataService = HelperDataService();
  final CustomAuthService _authService = CustomAuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allJobCategories = [];
  List<String> _selectedJobCategoryIds = [];
  List<Map<String, dynamic>> _filteredJobCategories = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterJobCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      _currentUserId = currentUser['user_id'];
      print('🔍 Loading job data for helper: $_currentUserId');

      // Load all available job categories
      final allCategories =
          await _helperDataService.getAvailableJobCategories();

      // Load helper's current job types
      final helperJobTypes =
          await _helperDataService.getHelperJobTypes(_currentUserId!);
      final selectedIds = helperJobTypes
          .map((jt) => jt['job_categories']['id'].toString())
          .toList();

      setState(() {
        _allJobCategories = allCategories;
        _selectedJobCategoryIds = selectedIds;
        _filteredJobCategories = List.from(allCategories);
        _isLoading = false;
      });

      print(
          '✅ Loaded ${allCategories.length} job categories, ${selectedIds.length} selected');
    } catch (e) {
      print('❌ Error loading job data: $e');
      setState(() {
        _error = 'Failed to load job data: $e';
        _isLoading = false;
      });
    }
  }

  void _filterJobCategories() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredJobCategories = List.from(_allJobCategories);
      } else {
        _filteredJobCategories = _allJobCategories
            .where((category) => category['name']
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleJobCategory(String categoryId) {
    setState(() {
      if (_selectedJobCategoryIds.contains(categoryId)) {
        _selectedJobCategoryIds.remove(categoryId);
      } else {
        _selectedJobCategoryIds.add(categoryId);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_currentUserId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      print('💾 Saving job types for helper: $_currentUserId');
      print('   Selected IDs: $_selectedJobCategoryIds');

      await _helperDataService.updateHelperJobTypes(
          _currentUserId!, _selectedJobCategoryIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job preferences saved successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      print('❌ Error saving job types: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save job preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
                title: 'Edit Job Types',
                showBackButton: true,
                showMenuButton: false,
                showNotificationButton: false,
                rightWidget: TextButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGreen),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
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
            'Loading job categories...',
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
              'Error Loading Job Categories',
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
              onPressed: _loadData,
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '${_selectedJobCategoryIds.length} Job Types Selected',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the types of jobs you want to offer',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColorLight,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search job types...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Job Types List
          _buildJobCategoriesList(),

          const SizedBox(height: 20),

          // Action Buttons
          _buildActionButtons(),

          const SizedBox(height: 16),

          // Save Button
          _buildSaveButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildJobCategoriesList() {
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
              'Available Job Types',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredJobCategories.length,
            itemBuilder: (context, index) {
              final category = _filteredJobCategories[index];
              final isSelected =
                  _selectedJobCategoryIds.contains(category['id'].toString());

              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen.withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: CheckboxListTile(
                  title: Text(
                    category['name'],
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    _toggleJobCategory(category['id'].toString());
                  },
                  activeColor: AppColors.primaryGreen,
                  checkColor: AppColors.white,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedJobCategoryIds.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedJobCategoryIds =
                    List.from(_allJobCategories.map((c) => c['id'].toString()));
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Select All',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Job Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
