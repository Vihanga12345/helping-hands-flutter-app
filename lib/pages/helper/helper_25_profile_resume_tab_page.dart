import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper25ProfileResumeTabPage extends StatefulWidget {
  const Helper25ProfileResumeTabPage({Key? key}) : super(key: key);

  @override
  State<Helper25ProfileResumeTabPage> createState() =>
      _Helper25ProfileResumeTabPageState();
}

class _Helper25ProfileResumeTabPageState
    extends State<Helper25ProfileResumeTabPage> {
  String selectedTab = 'Resume';

  // Sample data
  final String aboutMe =
      "I am a dedicated helper with over 5 years of experience in household services. I specialize in house cleaning, cooking, and childcare. I am reliable, trustworthy, and always strive to provide the best service to my clients. I am available for both part-time and full-time work.";

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
                title: 'Profile Resume',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                rightWidget: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/helper/profile/resume/edit'),
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
                            // About Me Section
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
                                    'About Me',
                                    style: TextStyle().copyWith(
                                      fontSize: 18,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    aboutMe,
                                    style: TextStyle().copyWith(
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // My Certificates Section
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
                                  Text(
                                    'My Certificates',
                                    style: TextStyle().copyWith(
                                      fontSize: 18,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Certificates Grid
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 15,
                                      mainAxisSpacing: 15,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemCount: certificates.length,
                                    itemBuilder: (context, index) {
                                      return _buildCertificateCard(
                                          certificates[index]);
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

  Widget _buildCertificateCard(Map<String, String> certificate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certificate Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                image: DecorationImage(
                  image: NetworkImage(certificate['image']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Certificate Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    certificate['title']!,
                    style: TextStyle().copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    certificate['issuer']!,
                    style: TextStyle().copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    certificate['date']!,
                    style: TextStyle().copyWith(
                      color: AppColors.primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
