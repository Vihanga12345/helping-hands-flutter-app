import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/localization_service.dart';

class Helpee23HelpSupportMyJobsPage extends StatefulWidget {
  const Helpee23HelpSupportMyJobsPage({super.key});

  @override
  State<Helpee23HelpSupportMyJobsPage> createState() =>
      _Helpee23HelpSupportMyJobsPageState();
}

class _Helpee23HelpSupportMyJobsPageState
    extends State<Helpee23HelpSupportMyJobsPage> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'booking',
      'question': 'How do I book a service?',
      'answer':
          'To book a service, navigate to the home page, select the service you need, choose your preferred date and time, and confirm your booking.',
    },
    {
      'category': 'payment',
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept credit/debit cards, digital wallets (PayPal, Google Pay, Apple Pay), and bank transfers.',
    },
    {
      'category': 'booking',
      'question': 'Can I reschedule my appointment?',
      'answer':
          'Yes, you can reschedule your appointment up to 2 hours before the scheduled time. Go to your job details and click "Reschedule".',
    },
    {
      'category': 'helper',
      'question': 'How are helpers vetted?',
      'answer':
          'All helpers undergo background checks, skill verification, and customer review evaluations before joining our platform.',
    },
    {
      'category': 'payment',
      'question': 'When will I be charged?',
      'answer':
          'Payment is processed after the service is completed and you have confirmed satisfaction with the work.',
    },
    {
      'category': 'cancellation',
      'question': 'What is the cancellation policy?',
      'answer':
          'You can cancel free of charge up to 24 hours before the scheduled time. Cancellations within 24 hours may incur a small fee.',
    },
    {
      'category': 'booking',
      'question': 'Can I book recurring services?',
      'answer':
          'Yes, you can set up weekly, bi-weekly, or monthly recurring services when making your initial booking.',
    },
    {
      'category': 'helper',
      'question': 'What if I\'m not satisfied with the service?',
      'answer':
          'If you\'re not satisfied, contact us within 24 hours. We\'ll work with you and the helper to resolve the issue or provide a refund.',
    },
  ];

  List<Map<String, dynamic>> get _filteredFaqs {
    var filtered = _faqs;

    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((faq) => faq['category'] == _selectedCategory)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((faq) =>
              faq['question'].toLowerCase().contains(searchTerm) ||
              faq['answer'].toLowerCase().contains(searchTerm))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Help & Support'.tr(),
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
                              hintText: 'Search for help...'.tr(),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.lightGrey),
                              ),
                              filled: true,
                              fillColor: AppColors.white,
                            ),
                            onChanged: (value) => setState(() {}),
                          ),

                          const SizedBox(height: 16),

                          // Category Filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryChip('all', 'All'.tr()),
                                _buildCategoryChip('booking', 'Booking'.tr()),
                                _buildCategoryChip('payment', 'Payment'.tr()),
                                _buildCategoryChip('helper', 'Helper'.tr()),
                                _buildCategoryChip(
                                    'cancellation', 'Cancellation'.tr()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // FAQ List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _filteredFaqs.length + 1, // +1 for contact section
                        itemBuilder: (context, index) {
                          if (index == _filteredFaqs.length) {
                            return _buildContactSection();
                          }

                          final faq = _filteredFaqs[index];
                          return _buildFaqCard(faq);
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

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
        backgroundColor: AppColors.white,
        selectedColor: AppColors.primaryGreen.withOpacity(0.2),
        checkmarkColor: AppColors.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGreen : AppColors.lightGrey,
        ),
      ),
    );
  }

  Widget _buildFaqCard(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(faq['category']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(faq['category']),
            color: _getCategoryColor(faq['category']),
            size: 20,
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
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Still need help?'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Can\'t find what you\'re looking for? Get in touch with our support team.'
                .tr(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Contact Options
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  'Chat'.tr(),
                  Icons.chat_bubble_outline,
                  () => _openChat(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  'Call'.tr(),
                  Icons.phone_outlined,
                  () => _makeCall(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: _buildContactButton(
              'Email Support'.tr(),
              Icons.email_outlined,
              () => _sendEmail(),
            ),
          ),

          const SizedBox(height: 20),

          // Contact Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Hours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Monday - Friday: 8:00 AM - 8:00 PM\nSaturday - Sunday: 9:00 AM - 6:00 PM',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Email: support@helpinghands.lk\nPhone: +94 11 234 5678',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        side: const BorderSide(color: AppColors.primaryGreen),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'booking':
        return AppColors.primaryGreen;
      case 'payment':
        return Colors.blue;
      case 'helper':
        return Colors.orange;
      case 'cancellation':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'booking':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'helper':
        return Icons.person;
      case 'cancellation':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat support...'.tr()),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling support: +94 11 234 5678'.tr()),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email client...'.tr()),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
