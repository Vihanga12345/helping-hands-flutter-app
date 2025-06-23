import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class HelperHelpSupportPage extends StatefulWidget {
  const HelperHelpSupportPage({super.key});

  @override
  State<HelperHelpSupportPage> createState() => _HelperHelpSupportPageState();
}

class _HelperHelpSupportPageState extends State<HelperHelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Getting Started',
    'Job Management',
    'Payments',
    'Account',
    'Technical',
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I start accepting job requests?',
      'answer':
          'After completing your profile and verification, you can browse job requests in the View Requests section. Simply tap "Accept" on jobs that match your skills and availability.',
      'category': 'Getting Started',
    },
    {
      'question': 'How do I get paid for completed jobs?',
      'answer':
          'Payment is automatically processed after job completion and client confirmation. Funds are typically transferred to your linked bank account within 2-3 business days.',
      'category': 'Payments',
    },
    {
      'question': 'Can I cancel a job after accepting it?',
      'answer':
          'Yes, but frequent cancellations may affect your rating. To cancel, go to your accepted jobs and select "Cancel Job". Please provide a valid reason for cancellation.',
      'category': 'Job Management',
    },
    {
      'question': 'How do I update my available job types?',
      'answer':
          'Go to Profile > Jobs tab and tap "Manage Job Types". You can select/deselect the services you want to offer and save your preferences.',
      'category': 'Account',
    },
    {
      'question': 'What should I do if a client is not responding?',
      'answer':
          'If a client is unresponsive, try messaging them first. If there\'s still no response after 24 hours, contact our support team for assistance.',
      'category': 'Job Management',
    },
    {
      'question': 'How can I improve my rating?',
      'answer':
          'Provide excellent service, communicate clearly with clients, arrive on time, and complete jobs as described. Consistently good performance leads to higher ratings.',
      'category': 'Getting Started',
    },
    {
      'question': 'Why is my account verification taking so long?',
      'answer':
          'Verification typically takes 24-48 hours. Ensure all documents are clear and readable. Contact support if verification takes longer than 3 business days.',
      'category': 'Account',
    },
    {
      'question': 'The app is not working properly, what should I do?',
      'answer':
          'Try restarting the app first. If issues persist, check your internet connection and ensure you have the latest app version. Contact technical support if problems continue.',
      'category': 'Technical',
    },
    {
      'question': 'How do I withdraw my earnings?',
      'answer':
          'Go to the Earnings page and tap "Withdraw". Enter the amount and select your preferred withdrawal method. Minimum withdrawal amount is LKR 1,000.',
      'category': 'Payments',
    },
    {
      'question': 'Can I work in multiple locations?',
      'answer':
          'Yes, you can update your service areas in your profile settings. Make sure to set realistic travel distances to ensure you can reach clients on time.',
      'category': 'Getting Started',
    },
  ];

  List<Map<String, dynamic>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = List.from(_faqs);
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFaqs() {
    setState(() {
      String searchTerm = _searchController.text.toLowerCase();
      _filteredFaqs = _faqs.where((faq) {
        bool matchesCategory =
            _selectedCategory == 'All' || faq['category'] == _selectedCategory;
        bool matchesSearch = searchTerm.isEmpty ||
            faq['question'].toLowerCase().contains(searchTerm) ||
            faq['answer'].toLowerCase().contains(searchTerm);
        return matchesCategory && matchesSearch;
      }).toList();
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
              const AppHeader(
                title: 'Help & Support',
                showBackButton: true,
                showMenuButton: false,
                showNotificationButton: false,
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact Support Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildContactCard(
                              'Live Chat',
                              'Get instant help',
                              Icons.chat_bubble_outline,
                              AppColors.primaryGreen,
                              () => _showContactDialog('Live Chat'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildContactCard(
                              'Call Us',
                              '+94 11 123 4567',
                              Icons.phone_outlined,
                              AppColors.info,
                              () => _showContactDialog('Phone'),
                            ),
                          ),
                        ],
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
                            hintText: 'Search help topics...',
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Category Filter
                      Container(
                        padding: const EdgeInsets.all(16),
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
                            const Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _categories.map((category) {
                                  final isSelected =
                                      category == _selectedCategory;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(category),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = category;
                                          _filterFaqs();
                                        });
                                      },
                                      backgroundColor:
                                          AppColors.lightGreen.withOpacity(0.1),
                                      selectedColor: AppColors.primaryGreen,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.primaryGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // FAQ Section
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
                                'Frequently Asked Questions',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredFaqs.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final faq = _filteredFaqs[index];
                                return ExpansionTile(
                                  title: Text(
                                    faq['question'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        faq['answer'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Still Need Help Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.support_agent,
                              size: 48,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Still Need Help?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Our support team is here to help you 24/7',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showContactDialog('Support'),
                              icon: const Icon(Icons.contact_support, size: 18),
                              label: const Text('Contact Support'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.home,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(String contactType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact $contactType'),
          content: Text(
              'Would you like to contact our support team via $contactType?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening $contactType support...'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Contact'),
            ),
          ],
        );
      },
    );
  }
}
