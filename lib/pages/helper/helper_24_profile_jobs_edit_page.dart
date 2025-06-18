import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper24ProfileJobsEditPage extends StatefulWidget {
  const Helper24ProfileJobsEditPage({Key? key}) : super(key: key);

  @override
  State<Helper24ProfileJobsEditPage> createState() =>
      _Helper24ProfileJobsEditPageState();
}

class _Helper24ProfileJobsEditPageState
    extends State<Helper24ProfileJobsEditPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedTab = 'Jobs';

  // Available job types
  final List<Map<String, dynamic>> jobTypes = [
    {'name': 'House Cleaning', 'selected': true},
    {'name': 'Gardening', 'selected': false},
    {'name': 'Cooking', 'selected': true},
    {'name': 'Childcare', 'selected': false},
    {'name': 'Pet Care', 'selected': false},
    {'name': 'Elderly Care', 'selected': true},
    {'name': 'Plumbing', 'selected': false},
    {'name': 'Electrical Work', 'selected': false},
    {'name': 'Painting', 'selected': false},
    {'name': 'Tutoring', 'selected': false},
  ];

  List<Map<String, dynamic>> filteredJobTypes = [];

  @override
  void initState() {
    super.initState();
    filteredJobTypes = List.from(jobTypes);
  }

  void _filterJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredJobTypes = List.from(jobTypes);
      } else {
        filteredJobTypes = jobTypes
            .where((job) =>
                job['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleJobSelection(int index) {
    setState(() {
      int originalIndex = jobTypes
          .indexWhere((job) => job['name'] == filteredJobTypes[index]['name']);
      jobTypes[originalIndex]['selected'] =
          !jobTypes[originalIndex]['selected'];
      filteredJobTypes[index]['selected'] = jobTypes[originalIndex]['selected'];
    });
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
                title: 'Edit Job Preferences',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                rightWidget: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Job preferences saved!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.pop();
                  },
                  child: Text(
                    'Save',
                    style: TextStyle().copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 80,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Edit Job Preferences',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Job preferences editing will be implemented here',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              AppNavigationBar(
                currentTab: NavigationTab.profile,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle().copyWith(
            color: Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
