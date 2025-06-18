import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper26ProfileResumeEditPage extends StatefulWidget {
  const Helper26ProfileResumeEditPage({Key? key}) : super(key: key);

  @override
  State<Helper26ProfileResumeEditPage> createState() =>
      _Helper26ProfileResumeEditPageState();
}

class _Helper26ProfileResumeEditPageState
    extends State<Helper26ProfileResumeEditPage> {
  final _aboutController = TextEditingController(
      text:
          "I am a dedicated helper with over 5 years of experience in household services. I specialize in house cleaning, cooking, and childcare. I am reliable, trustworthy, and always strive to provide the best service to my clients.");

  // Sample certificate data
  final List<Map<String, String>> certificates = [
    {
      'title': 'First Aid Certificate',
      'issuer': 'Red Cross',
      'date': '2023',
      'image': 'https://placehold.co/150x100'
    },
    {
      'title': 'Childcare Training',
      'issuer': 'Child Development Center',
      'date': '2022',
      'image': 'https://placehold.co/150x100'
    },
    {
      'title': 'Cooking Certificate',
      'issuer': 'Culinary Institute',
      'date': '2021',
      'image': 'https://placehold.co/150x100'
    },
  ];

  @override
  void dispose() {
    _aboutController.dispose();
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
              // Header
              AppHeader(
                title: 'Edit Resume',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                rightWidget: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resume updated successfully!'),
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
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _buildTab('Profile', false),
                          const SizedBox(width: 10),
                          _buildTab('Jobs', false),
                          const SizedBox(width: 10),
                          _buildTab('Resume', true),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Edit About Me Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit About Me',
                                    style: TextStyle().copyWith(
                                      fontSize: 18,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  TextFormField(
                                    controller: _aboutController,
                                    maxLines: 8,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Tell others about yourself and your experience...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.lightGrey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.primaryGreen,
                                            width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Certificate Management Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 100),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'My Certificates',
                                          style: TextStyle().copyWith(
                                            fontSize: 18,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Add certificate functionality will be implemented'),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Add'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),

                                  // Certificates List
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: certificates.length,
                                    itemBuilder: (context, index) {
                                      return _buildEditableCertificateCard(
                                          certificates[index], index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
      child: GestureDetector(
        onTap: () {
          if (title == 'Profile') {
            context.go('/helper-profile');
          } else if (title == 'Jobs') {
            context.go('/helper-profile-jobs');
          }
        },
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
      ),
    );
  }

  Widget _buildEditableCertificateCard(
      Map<String, String> certificate, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Certificate Image
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(certificate['image']!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Certificate Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate['title']!,
                  style: TextStyle().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  certificate['issuer']!,
                  style: TextStyle().copyWith(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  certificate['date']!,
                  style: TextStyle().copyWith(
                    color: AppColors.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Column(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Edit ${certificate['title']}'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, color: AppColors.primaryGreen),
                iconSize: 20,
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete ${certificate['title']}'),
                    ),
                  );
                },
                icon: const Icon(Icons.delete, color: AppColors.error),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
