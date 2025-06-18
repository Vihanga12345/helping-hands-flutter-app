import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class Helper4RegistrationPage2 extends StatefulWidget {
  const Helper4RegistrationPage2({super.key});

  @override
  State<Helper4RegistrationPage2> createState() =>
      _Helper4RegistrationPage2State();
}

class _Helper4RegistrationPage2State extends State<Helper4RegistrationPage2> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _selectedServices = [];
  final List<String> _availableServices = [
    'Gardening',
    'Housekeeping',
    'Childcare',
    'Cooking',
    'Pet Care',
    'Elderly Care',
    'Tutoring',
    'Maintenance',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration - Step 2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Indicator
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Professional Details',
                    style: TextStyle(),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Tell us about your skills and experience',
                    style: TextStyle().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Services Selection
                  const Text(
                    'Services You Offer',
                    style: TextStyle(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableServices.map((service) {
                      final isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        label: Text(service),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              _selectedServices.remove(service);
                            }
                          });
                        },
                        backgroundColor: AppColors.white,
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Experience
                  const Text('Years of Experience', style: TextStyle()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter years of experience',
                      suffixText: 'years',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your experience';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Hourly Rate
                  const Text('Hourly Rate', style: TextStyle()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _hourlyRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter your hourly rate',
                      prefixText: 'LKR ',
                      suffixText: '/hour',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your hourly rate';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Bio
                  const Text('About You', style: TextStyle()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Tell potential clients about yourself, your skills, and experience...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please provide information about yourself';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Availability Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Availability',
                          style: TextStyle(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            const Text('Monday - Friday: 9:00 AM - 5:00 PM'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.weekend,
                                color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            const Text('Weekends: Available on request'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Availability settings coming soon!')),
                            );
                          },
                          child: const Text('Customize Availability'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _continueToNext,
                      child: const Text(
                        'Continue',
                        style: TextStyle(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _continueToNext() {
    if (_formKey.currentState!.validate()) {
      if (_selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one service'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professional details saved!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to next registration step
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Next registration step coming soon!')),
      );
    }
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
