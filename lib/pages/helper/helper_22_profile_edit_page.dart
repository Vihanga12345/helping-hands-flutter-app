import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';

class Helper22ProfileEditPage extends StatefulWidget {
  const Helper22ProfileEditPage({super.key});

  @override
  State<Helper22ProfileEditPage> createState() =>
      _Helper22ProfileEditPageState();
}

class _Helper22ProfileEditPageState extends State<Helper22ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  // Text Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  DateTime _selectedBirthDate = DateTime(1990, 5, 15);

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userProfile;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return;
      }

      _currentUserId = currentUser['user_id'];
      print('👤 Loading profile for editing: $_currentUserId');

      final userProfile = await _userDataService.getCurrentUserProfile();

      if (userProfile != null && mounted) {
        setState(() {
          _userProfile = userProfile;

          // Populate form fields with real data
          _firstNameController.text = userProfile['first_name'] ?? '';
          _lastNameController.text = userProfile['last_name'] ?? '';
          _phoneController.text = userProfile['phone'] ?? '';
          _emailController.text = userProfile['email'] ?? '';
          _locationController.text = userProfile['location_city'] ?? '';
          _aboutMeController.text = userProfile['about_me'] ?? '';
          _emergencyNameController.text =
              userProfile['emergency_contact_name'] ?? '';
          _emergencyPhoneController.text =
              userProfile['emergency_contact_phone'] ?? '';

          // Set birth date
          if (userProfile['date_of_birth'] != null) {
            try {
              _selectedBirthDate = DateTime.parse(userProfile['date_of_birth']);
            } catch (e) {
              print('Error parsing birth date: $e');
              _selectedBirthDate = DateTime(1990, 5, 15);
            }
          }

          _isLoading = false;
        });

        print('✅ Profile data loaded for editing');
      }
    } catch (e) {
      print('❌ Error loading profile for editing: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _aboutMeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
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
                title: 'Edit Profile',
                showBackButton: true,
                showMenuButton: true,
                showNotificationButton: true,
                onMenuPressed: () {
                  context.push('/helper/menu');
                },
                onNotificationPressed: () {
                  context.push('/helper/notifications');
                },
                rightWidget: TextButton(
                  onPressed: _isSaving ? null : _saveProfile,
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
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryGreen),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading profile data...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Image Section
                              _buildProfileImageSection(),

                              const SizedBox(height: 20),

                              // Personal Information Form
                              _buildPersonalInfoForm(),

                              const SizedBox(height: 20),

                              // Emergency Contact Form
                              _buildEmergencyContactForm(),

                              const SizedBox(height: 32),

                              // Save Button
                              _buildSaveButton(),

                              const SizedBox(height: 20),
                            ],
                          ),
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

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGreen,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _userProfile?['profile_image_url'] != null
                      ? Image.network(
                          _userProfile!['profile_image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppColors.lightGrey,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.lightGrey,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to change profile photo',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    return Container(
      width: double.infinity,
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
            'Personal Information',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // First Name
          _buildTextFormField(
            label: 'First Name',
            controller: _firstNameController,
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Last Name
          _buildTextFormField(
            label: 'Last Name',
            controller: _lastNameController,
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // About Me
          _buildTextFormField(
            label: 'About me',
            controller: _aboutMeController,
            icon: Icons.info_outline,
            maxLines: 4,
            hintText:
                'Tell clients about yourself, your experience, and what makes you special...',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please tell us about yourself';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Email
          _buildTextFormField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Phone Number
          _buildTextFormField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Location
          _buildTextFormField(
            label: 'Location',
            controller: _locationController,
            icon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your location';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Age (Birthday)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birthday',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Age',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _calculateAge(_selectedBirthDate),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactForm() {
    return Container(
      width: double.infinity,
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
            'Emergency Contact',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Emergency Contact Name
          _buildTextFormField(
            label: 'Name',
            controller: _emergencyNameController,
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Emergency Contact Phone
          _buildTextFormField(
            label: 'Phone',
            controller: _emergencyPhoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact phone';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryGreen),
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              )
            : Text(
                'Save Changes',
                style: AppTextStyles.buttonMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return '$age years old';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('💾 Saving profile for user: $_currentUserId');

      final updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'location_city': _locationController.text.trim(),
        'about_me': _aboutMeController.text.trim(),
        'date_of_birth': _selectedBirthDate.toIso8601String().split('T')[0],
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _userDataService.updateUserProfile(updateData);

      print('✅ Profile saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      print('❌ Error saving profile: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
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
}
