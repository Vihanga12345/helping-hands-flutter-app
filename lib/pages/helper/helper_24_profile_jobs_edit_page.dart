import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper24ProfileJobsEditPage extends StatefulWidget {
  const Helper24ProfileJobsEditPage({super.key});

  @override
  State<Helper24ProfileJobsEditPage> createState() =>
      _Helper24ProfileJobsEditPageState();
}

class _Helper24ProfileJobsEditPageState
    extends State<Helper24ProfileJobsEditPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _allJobTypes = [
    'House Cleaning',
    'Deep Cleaning',
    'Laundry Service',
    'Kitchen Cleaning',
    'Bathroom Cleaning',
    'Window Cleaning',
    'Carpet Cleaning',
    'Organizing',
    'Gardening',
    'Pet Care',
    'Elderly Care',
    'Baby Sitting',
    'Cooking',
    'Grocery Shopping',
    'Home Maintenance',
    'Electrical Work',
    'Plumbing',
    'Painting',
    'Moving Help',
    'Event Setup',
    'Tutoring',
    'Car Washing',
    'Furniture Assembly',
    'Interior Design',
    'Party Planning',
    'Photography',
    'Tech Support',
    'Language Teaching',
    'Fitness Training',
    'Music Lessons',
  ];

  List<String> _selectedJobTypes = [
    'House Cleaning',
    'Deep Cleaning',
    'Laundry Service',
    'Kitchen Cleaning',
    'Organizing',
  ];

  List<String> _filteredJobTypes = [];

  @override
  void initState() {
    super.initState();
    _filteredJobTypes = List.from(_allJobTypes);
    _searchController.addListener(_filterJobTypes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterJobTypes() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredJobTypes = List.from(_allJobTypes);
      } else {
        _filteredJobTypes = _allJobTypes
            .where((job) => job
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleJobType(String jobType) {
    setState(() {
      if (_selectedJobTypes.contains(jobType)) {
        _selectedJobTypes.remove(jobType);
      } else {
        _selectedJobTypes.add(jobType);
      }
    });
  }

  void _saveChanges() {
    // Here you would typically save to a backend or local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job preferences saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
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
                  onPressed: _saveChanges,
                  child: const Text(
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
                child: SingleChildScrollView(
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
                          border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_selectedJobTypes.length} Job Types Selected',
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
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Job Types List
                      Container(
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
                              itemCount: _filteredJobTypes.length,
                              itemBuilder: (context, index) {
                                final jobType = _filteredJobTypes[index];
                                final isSelected =
                                    _selectedJobTypes.contains(jobType);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                            .withOpacity(0.05)
                                        : Colors.transparent,
                                  ),
                                  child: CheckboxListTile(
                                    title: Text(
                                      jobType,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      _toggleJobType(jobType);
                                    },
                                    activeColor: AppColors.primaryGreen,
                                    checkColor: AppColors.white,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 4),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedJobTypes.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                  _selectedJobTypes = List.from(_allJobTypes);
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primaryGreen),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                      ),

                      const SizedBox(height: 16),

                      // Save Button
                      SizedBox(
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
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
}
