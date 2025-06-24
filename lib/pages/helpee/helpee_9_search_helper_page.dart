import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';

class Helpee9SearchHelperPage extends StatefulWidget {
  const Helpee9SearchHelperPage({super.key});

  @override
  State<Helpee9SearchHelperPage> createState() =>
      _Helpee9SearchHelperPageState();
}

class _Helpee9SearchHelperPageState extends State<Helpee9SearchHelperPage> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Gardening',
    'Housekeeping',
    'Childcare',
    'Cooking'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Find Helpers',
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
          ),

          // Body Content
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
                    // Search and Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search helpers...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.filter_list),
                                onPressed: () {
                                  _showFilterDialog();
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.lightGrey),
                              ),
                              filled: true,
                              fillColor: AppColors.white,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),

                          const SizedBox(height: 16),

                          // Category Filter
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    _selectedCategory == category;
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    },
                                    backgroundColor: AppColors.white,
                                    selectedColor: AppColors.primaryGreen,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Helper List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5, // Demo helpers
                        itemBuilder: (context, index) {
                          return _buildHelperSearchResult(
                            name: 'John Smith ${index + 1}',
                            category: _categories[(index % 4) + 1],
                            rating: 4.5 + (index * 0.1),
                            jobCount: 50 + (index * 10),
                            experience: '${index + 2} years',
                            rate: 'LKR ${(index + 15) * 100}/hour',
                            distance: '${index + 1}.2 km away',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.home,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildHelperSearchResult({
    required String name,
    required String category,
    required double rating,
    required int jobCount,
    required String experience,
    required String rate,
    required String distance,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Helper Profile Bar
          HelperProfileBar(
            name: name,
            rating: rating,
            jobCount: jobCount,
            onTap: () {
              context.push('/helpee/helper-profile');
            },
          ),

          const SizedBox(height: 8),

          // Additional Info and Action Buttons
          Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
                // Additional Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 14,
                            fontWeight: FontWeight.w600,
                      ),
                        ),
                        Text(
                          '$experience experience',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    distance,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                          context.push('/helpee/helper-profile');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request sent to helper!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Request'),
                ),
              ),
            ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Helpers'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter options coming soon!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
