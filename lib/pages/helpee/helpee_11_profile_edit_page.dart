import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';

class Helpee11ProfileEditPage extends StatefulWidget {
  const Helpee11ProfileEditPage({super.key});

  @override
  State<Helpee11ProfileEditPage> createState() =>
      _Helpee11ProfileEditPageState();
}

class _Helpee11ProfileEditPageState extends State<Helpee11ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current user profile data
      final userData = await _userDataService.getCurrentUserProfile();

      if (userData != null) {
        setState(() {
          _currentUserData = userData;

          // Populate form fields with real user data
          _nameController.text = userData['display_name'] ??
              '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                  .trim();
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['location_address'] ?? '';
          _emergencyNameController.text =
              userData['emergency_contact_name'] ?? '';
          _emergencyPhoneController.text =
              userData['emergency_contact_phone'] ?? '';

          _selectedLanguage = userData['preferred_language'] ?? 'English';
          _notificationsEnabled = userData['notifications_enabled'] ?? true;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Could not load user profile data'.tr();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load profile: $e'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with Save button
          AppHeader(
            title: 'Edit Profile'.tr(),
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
            rightWidget: GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _isSaving ? AppColors.lightGrey : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen),
                        ),
                      )
                    : const Icon(
                        Icons.save,
                        color: Color(0xFF8FD89F),
                        size: 18,
                      ),
              ),
            ),
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
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Profile Photo Section
                                  Container(
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
                                            CircleAvatar(
                                              radius: 50,
                                              backgroundColor:
                                                  AppColors.primaryGreen,
                                              child: Text(
                                                _getInitials(),
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primaryGreen,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: AppColors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Tap to change profile photo',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Personal Information
                                  _buildInfoSection(
                                    title: 'Personal Information',
                                    children: [
                                      _buildTextField(
                                        controller: _nameController,
                                        label: 'Full Name',
                                        icon: Icons.person,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _emailController,
                                        label: 'Email',
                                        icon: Icons.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _phoneController,
                                        label: 'Phone Number',
                                        icon: Icons.phone,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _addressController,
                                        label: 'Address',
                                        icon: Icons.location_on,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Emergency Contact
                                  _buildInfoSection(
                                    title: 'Emergency Contact',
                                    children: [
                                      _buildTextField(
                                        controller: _emergencyNameController,
                                        label: 'Emergency Contact Name',
                                        icon: Icons.contact_emergency,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _emergencyPhoneController,
                                        label: 'Emergency Contact Phone',
                                        icon: Icons.phone_in_talk,
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Preferences
                                  _buildInfoSection(
                                    title: 'Preferences',
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _selectedLanguage,
                                        decoration: InputDecoration(
                                          labelText: 'Language',
                                          prefixIcon: const Icon(Icons.language,
                                              color: AppColors.primaryGreen),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: AppColors.lightGrey),
                                          ),
                                          filled: true,
                                          fillColor: AppColors.white,
                                        ),
                                        items: ['English', 'Sinhala', 'Tamil']
                                            .map((language) => DropdownMenuItem(
                                                  value: language,
                                                  child: Text(language),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedLanguage = value!;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      SwitchListTile(
                                        title: Text('Push Notifications'.tr()),
                                        subtitle: Text(
                                            'Receive notifications about your jobs'
                                                .tr()),
                                        value: _notificationsEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _notificationsEnabled = value;
                                          });
                                        },
                                        activeColor: AppColors.primaryGreen,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Save Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isSaving ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      AppColors.white),
                                            )
                                          : Text(
                                              'Save Changes'.tr(),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: Text(
                'Retry'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label'.tr();
        }
        return null;
      },
    );
  }

  String _getInitials() {
    if (_currentUserData != null) {
      final firstName = _currentUserData!['first_name'] ?? '';
      final lastName = _currentUserData!['last_name'] ?? '';

      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
      }
    }

    final displayName = _nameController.text.trim();
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName[0].toUpperCase();
    }

    return 'U';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare updated profile data
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

      final updatedData = {
        'first_name': firstName,
        'last_name': lastName,
        'display_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location_address': _addressController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'preferred_language': _selectedLanguage,
        'notifications_enabled': _notificationsEnabled,
      };

      // Save to database
      await _userDataService.updateUserProfile(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'.tr()),
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}
