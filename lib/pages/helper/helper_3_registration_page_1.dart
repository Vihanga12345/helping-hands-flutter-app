import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/common/universal_page_header.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/progress_indicator.dart' as custom;

class Helper3RegistrationPage1 extends StatefulWidget {
  const Helper3RegistrationPage1({super.key});

  @override
  State<Helper3RegistrationPage1> createState() =>
      _Helper3RegistrationPage1State();
}

class _Helper3RegistrationPage1State extends State<Helper3RegistrationPage1> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Universal Page Header
          UniversalPageHeader(
            title: 'Helper Registration'.tr(),
            subtitle: 'Step 1 of 3'.tr(),
            onBackPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Progress Indicator
                    custom.ProgressIndicator(
                      totalSteps: 3,
                      currentStep: 1,
                      stepTitles: [
                        'Personal Info'.tr(),
                        'Select Services'.tr(),
                        'Upload Documents'.tr()
                      ],
                      onStepTapped: (step) {
                        // Handle step navigation
                        if (step == 1) {
                          // Already on step 1
                          return;
                        } else if (step == 2) {
                          context.go('/helper-register-2');
                        } else if (step == 3) {
                          context.go('/helper-register-3');
                        }
                      },
                      enableNavigation: true,
                    ),

                    const SizedBox(height: 24),

                    // Registration Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Form Title
                          Text(
                            'Personal Information'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // First Name Field
                          CustomTextField(
                            label: 'First Name'.tr(),
                            hint: 'Enter your first name'.tr(),
                            controller: _firstNameController,
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name'.tr();
                              }
                              return null;
                            },
                          ),

                          // Last Name Field
                          CustomTextField(
                            label: 'Last Name'.tr(),
                            hint: 'Enter your last name'.tr(),
                            controller: _lastNameController,
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name'.tr();
                              }
                              return null;
                            },
                          ),

                          // Username Field
                          CustomTextField(
                            label: 'Username'.tr(),
                            hint: 'Choose a unique username'.tr(),
                            controller: _usernameController,
                            prefixIcon:
                                const Icon(Icons.account_circle_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username'.tr();
                              }
                              if (value.length < 3) {
                                return 'Username must be at least 3 characters'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          // Email Field
                          CustomTextField(
                            label: 'Email'.tr(),
                            hint: 'Enter your email address'.tr(),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email'.tr();
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email address'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          // Phone Field
                          CustomTextField(
                            label: 'Phone Number'.tr(),
                            hint: 'Enter your phone number'.tr(),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number'.tr();
                              }
                              return null;
                            },
                          ),

                          // Birthday Field
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Birth'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 18),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.lightGrey
                                              .withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedDate != null
                                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                                : 'Select your birthday'.tr(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _selectedDate != null
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary
                                                      .withOpacity(0.7),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Password Field
                          CustomTextField(
                            label: 'Password'.tr(),
                            hint: 'Create a secure password'.tr(),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password'.tr();
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          // Confirm Password Field
                          CustomTextField(
                            label: 'Confirm Password'.tr(),
                            hint: 'Re-enter your password'.tr(),
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password'.tr();
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match'.tr();
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // Next Button
                          CustomButton(
                            text: 'Next'.tr(),
                            onPressed: _handleNext,
                            isLoading: _isLoading,
                            icon: Icons.arrow_forward,
                          ),

                          const SizedBox(height: 16),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ".tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/helper-login'),
                                child: Text(
                                  'Login'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBubble(bool isActive, int step) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primaryGreen : AppColors.lightGrey,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine() {
    return Container(
      width: 40,
      height: 2,
      color: AppColors.lightGrey,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 6570)), // Must be at least 18
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select your birthday'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Store data temporarily for next pages
      Map<String, dynamic> registrationData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birthday': _selectedDate?.toIso8601String(),
      };

      // Navigate to page 2 with registration data
      if (mounted) {
        context.go('/helper-register-2', extra: registrationData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
