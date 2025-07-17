import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/custom_auth_service.dart';
import '../../services/popup_manager_service.dart';
import '../../services/helper_data_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../widgets/common/universal_page_header.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/progress_indicator.dart' as custom;

class Helper5RegistrationPage3 extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const Helper5RegistrationPage3({super.key, this.registrationData});

  @override
  State<Helper5RegistrationPage3> createState() =>
      _Helper5RegistrationPage3State();
}

class _Helper5RegistrationPage3State extends State<Helper5RegistrationPage3> {
  bool _isLoading = false;
  bool _idFrontUploaded = false;
  bool _idBackUploaded = false;
  bool _isUploadingIdFront = false;
  bool _isUploadingIdBack = false;

  // Store uploaded file information
  Map<String, dynamic>? _idFrontFile;
  Map<String, dynamic>? _idBackFile;

  final _popupManager = PopupManagerService();

  @override
  Widget build(BuildContext context) {
    final canComplete = _idFrontUploaded && _idBackUploaded;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Universal Page Header
          UniversalPageHeader(
            title: 'Helper Registration',
            subtitle: 'Step 3 of 3',
            onBackPressed: () => context.pop(),
          ),

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Progress Indicator
                  custom.ProgressIndicator(
                    totalSteps: 3,
                    currentStep: 3,
                    stepTitles: [
                      'Personal Info',
                      'Select Services',
                      'Upload Documents'
                    ],
                    onStepTapped: (step) {
                      // Handle step navigation
                      if (step == 1) {
                        context.go('/helper-register');
                      } else if (step == 2) {
                        context.go('/helper-register-2');
                      } else if (step == 3) {
                        // Already on step 3
                        return;
                      }
                    },
                    enableNavigation: true,
                  ),

                  const SizedBox(height: 24),

                  // Security Notice
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.security,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure & Confidential',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your ID documents are encrypted and used only for verification purposes.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ID Front Upload
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _idFrontUploaded
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _idFrontUploaded
                                    ? Icons.check_circle_outline
                                    : Icons.credit_card,
                                color: _idFrontUploaded
                                    ? AppColors.success
                                    : AppColors.primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID Card Front Side',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Upload a clear photo of the front of your National ID',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Upload area for front
                        GestureDetector(
                          onTap: _isUploadingIdFront ? null : _uploadIdFront,
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _idFrontUploaded
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.lightGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _idFrontUploaded
                                    ? AppColors.success
                                    : AppColors.lightGrey.withOpacity(0.3),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _isUploadingIdFront
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryGreen),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Uploading ID front...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _idFrontUploaded
                                            ? Icons.check_circle
                                            : Icons.camera_alt_outlined,
                                        size: 32,
                                        color: _idFrontUploaded
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _idFrontUploaded
                                            ? 'ID Front Uploaded Successfully'
                                            : 'Tap to upload ID front photo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _idFrontUploaded
                                              ? AppColors.success
                                              : AppColors.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (!_idFrontUploaded) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Camera or Gallery',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (_idFrontUploaded &&
                                          _idFrontFile != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'File: ${_idFrontFile!['name']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ID Back Upload
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _idBackUploaded
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _idBackUploaded
                                    ? Icons.check_circle_outline
                                    : Icons.credit_card,
                                color: _idBackUploaded
                                    ? AppColors.success
                                    : AppColors.primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID Card Back Side',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Upload a clear photo of the back of your National ID',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Upload area for back
                        GestureDetector(
                          onTap: _isUploadingIdBack ? null : _uploadIdBack,
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _idBackUploaded
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.lightGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _idBackUploaded
                                    ? AppColors.success
                                    : AppColors.lightGrey.withOpacity(0.3),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _isUploadingIdBack
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryGreen),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Uploading ID back...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _idBackUploaded
                                            ? Icons.check_circle
                                            : Icons.camera_alt_outlined,
                                        size: 32,
                                        color: _idBackUploaded
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _idBackUploaded
                                            ? 'ID Back Uploaded Successfully'
                                            : 'Tap to upload ID back photo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _idBackUploaded
                                              ? AppColors.success
                                              : AppColors.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (!_idBackUploaded) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Camera or Gallery',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (_idBackUploaded &&
                                          _idBackFile != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'File: ${_idBackFile!['name']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bottom Actions
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
                      children: [
                        CustomButton(
                          text: canComplete
                              ? 'Complete Registration'
                              : 'Upload both ID photos to continue',
                          onPressed: canComplete &&
                                  !_isLoading &&
                                  !_isUploadingIdFront &&
                                  !_isUploadingIdBack
                              ? _completeRegistration
                              : null,
                          isLoading: _isLoading,
                          icon: Icons.check_circle,
                          enabled: canComplete &&
                              !_isLoading &&
                              !_isUploadingIdFront &&
                              !_isUploadingIdBack,
                        ),

                        const SizedBox(height: 16),

                        // Back Button
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.textSecondary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Back to Previous Step',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadIdFront() async {
    try {
      setState(() {
        _isUploadingIdFront = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          throw Exception('File size must be less than 10MB');
        }

        // Validate file type
        final allowedTypes = ['jpg', 'jpeg', 'png'];
        final extension =
            path.extension(file.name).toLowerCase().replaceAll('.', '');
        if (!allowedTypes.contains(extension)) {
          throw Exception('Only JPG, JPEG, and PNG files are allowed');
        }

        // TODO: In a real app, you would upload to Supabase Storage here
        // For now, we'll simulate the upload process
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          _idFrontFile = {
            'name': file.name,
            'size': file.size,
            'type': file.extension,
            'data': file.bytes,
          };
          _idFrontUploaded = true;
          _isUploadingIdFront = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID front photo uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _isUploadingIdFront = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingIdFront = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading ID front: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _uploadIdBack() async {
    try {
      setState(() {
        _isUploadingIdBack = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          throw Exception('File size must be less than 10MB');
        }

        // Validate file type
        final allowedTypes = ['jpg', 'jpeg', 'png'];
        final extension =
            path.extension(file.name).toLowerCase().replaceAll('.', '');
        if (!allowedTypes.contains(extension)) {
          throw Exception('Only JPG, JPEG, and PNG files are allowed');
        }

        // TODO: In a real app, you would upload to Supabase Storage here
        // For now, we'll simulate the upload process
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          _idBackFile = {
            'name': file.name,
            'size': file.size,
            'type': file.extension,
            'data': file.bytes,
          };
          _idBackUploaded = true;
          _isUploadingIdBack = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID back photo uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _isUploadingIdBack = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingIdBack = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading ID back: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeRegistration() async {
    if (!_idFrontUploaded || !_idBackUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both ID photos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Complete registration with all collected data
      final registrationData = widget.registrationData ?? {};

      final result = await CustomAuthService().register(
        username: registrationData['username'] ?? '',
        email: registrationData['email'] ?? '',
        password: registrationData['password'] ?? '',
        userType: 'helper',
        firstName: registrationData['firstName'] ?? '',
        lastName: registrationData['lastName'] ?? '',
        phone: registrationData['phone'] ?? '',
      );

      if (result['success']) {
        if (mounted) {
          // Auto-save selected job categories to helper profile
          await _saveSelectedJobCategoriesToProfile(result['user']);

          // Show account creation popup
          _popupManager.showAccountCreationPopup();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Registration completed successfully! Welcome to Helping Hands!'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate to helper home page
          context.go('/helper/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Registration failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
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

  Future<void> _saveSelectedJobCategoriesToProfile(
      Map<String, dynamic> user) async {
    try {
      final registrationData = widget.registrationData ?? {};
      final selectedJobTypes =
          registrationData['selectedJobTypes'] as List<String>?;

      if (selectedJobTypes != null &&
          selectedJobTypes.isNotEmpty &&
          user['user_id'] != null) {
        print('💾 Saving selected job categories to helper profile...');
        print('   Helper ID: ${user['user_id']}');
        print('   Selected categories: $selectedJobTypes');

        final helperDataService = HelperDataService();
        await helperDataService.saveHelperJobTypes(
            user['user_id'], selectedJobTypes);

        print('✅ Job categories saved successfully to helper profile');
      }
    } catch (e) {
      print('❌ Error saving job categories to profile: $e');
      // Don't show error to user since registration was successful
      // The user can always add job categories later in their profile
    }
  }
}
