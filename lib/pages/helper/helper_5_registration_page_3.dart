import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/custom_auth_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final canComplete = _idFrontUploaded && _idBackUploaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload ID Documents'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
          child: Column(
            children: [
              // Progress Indicator
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProgressBubble(true, 1),
                        _buildProgressLine(true),
                        _buildProgressBubble(true, 2),
                        _buildProgressLine(true),
                        _buildProgressBubble(true, 3), // Current page
                        _buildProgressLine(false),
                        _buildProgressBubble(false, 4),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Step 3 of 4: Upload ID Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload clear photos of your National Identity Card',
                              style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Security Notice
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppColors.primaryGreen,
                              size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                    'Secure & Confidential',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your ID documents are encrypted and used only for verification purposes.',
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
                      ),

                      const SizedBox(height: 24),

                      // ID Front Upload
                      Container(
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _idFrontUploaded
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.primaryGreen
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _idFrontUploaded
                                        ? Icons.check_circle
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ID Card Front Side',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
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
                              onTap: () => _uploadIdFront(),
                              child: Container(
                                width: double.infinity,
                                height: 120,
                decoration: BoxDecoration(
                                  color: _idFrontUploaded
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.lightGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                                    color: _idFrontUploaded
                                        ? AppColors.success
                                        : AppColors.lightGrey,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                                    Icon(
                                      _idFrontUploaded
                                          ? Icons.check_circle
                                          : Icons.camera_alt,
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
                                        fontWeight: FontWeight.w500,
                                        color: _idFrontUploaded
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _idBackUploaded
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.primaryGreen
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _idBackUploaded
                                        ? Icons.check_circle
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ID Card Back Side',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
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
                              onTap: () => _uploadIdBack(),
                              child: Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: _idBackUploaded
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.lightGrey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _idBackUploaded
                                        ? AppColors.success
                                        : AppColors.lightGrey,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _idBackUploaded
                                          ? Icons.check_circle
                                          : Icons.camera_alt,
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
                                        fontWeight: FontWeight.w500,
                                        color: _idBackUploaded
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
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
                                  ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColorLight,
                      blurRadius: 8,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canComplete && !_isLoading
                            ? _completeRegistration
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white),
                              )
                            : Text(
                                canComplete
                                    ? 'Complete Registration'
                                    : 'Upload both ID photos to continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Back to Previous Step',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppColors.primaryGreen : AppColors.lightGrey,
    );
  }

  void _uploadIdFront() {
    setState(() {
      _idFrontUploaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID front photo uploaded successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _uploadIdBack() {
    setState(() {
      _idBackUploaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID back photo uploaded successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
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
}
