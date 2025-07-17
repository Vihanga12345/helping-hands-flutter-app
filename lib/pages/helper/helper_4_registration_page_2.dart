import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/job_questions_service.dart';
import '../../widgets/common/universal_page_header.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/progress_indicator.dart' as custom;

class Helper4RegistrationPage2 extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const Helper4RegistrationPage2({super.key, this.registrationData});

  @override
  State<Helper4RegistrationPage2> createState() =>
      _Helper4RegistrationPage2State();
}

class _Helper4RegistrationPage2State extends State<Helper4RegistrationPage2> {
  final _formKey = GlobalKey<FormState>();
  List<String> _selectedJobTypes = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  // Job categories from database
  List<Map<String, dynamic>> _availableJobTypes = [];

  // Certificate tracking
  final Map<String, bool> _certificatesUploaded = {};

  @override
  void initState() {
    super.initState();
    _loadJobCategories();
  }

  Future<void> _loadJobCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
        _errorMessage = null;
      });

      final jobQuestionsService = JobQuestionsService();
      final categories = await jobQuestionsService.getJobCategories();

      setState(() {
        _availableJobTypes = categories.map((category) {
          return {
            'id': category['id'].toString(),
            'name': category['name'],
            'icon': _getIconForCategory(category['name']),
            'description':
                category['description'] ?? 'No description available',
            'hourly_rate': category['default_hourly_rate'] ?? 0.0,
          };
        }).toList();
        _isLoadingCategories = false;
      });

      print(
          '✅ Loaded ${_availableJobTypes.length} job categories from database');
    } catch (e) {
      print('❌ Error loading job categories: $e');
      setState(() {
        _errorMessage = 'Failed to load job categories. Please try again.';
        _isLoadingCategories = false;
      });
    }
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'house cleaning':
        return Icons.cleaning_services;
      case 'deep cleaning':
        return Icons.auto_awesome;
      case 'gardening':
        return Icons.yard;
      case 'cooking':
        return Icons.restaurant;
      case 'elderly care':
        return Icons.elderly;
      case 'childcare':
        return Icons.child_care;
      case 'pet care':
        return Icons.pets;
      case 'tutoring':
        return Icons.school;
      case 'car washing':
        return Icons.local_car_wash;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'home maintenance':
        return Icons.home_repair_service;
      case 'delivery':
        return Icons.delivery_dining;
      default:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Universal Page Header
          UniversalPageHeader(
            title: 'Helper Registration',
            subtitle: 'Step 2 of 3',
            onBackPressed: () => context.pop(),
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
                      currentStep: 2,
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
                          // Already on step 2
                          return;
                        } else if (step == 3) {
                          context.go('/helper-register-3');
                        }
                      },
                      enableNavigation: true,
                    ),

                    const SizedBox(height: 24),

                    // Main Content
                    _isLoadingCategories
                        ? Container(
                            height: 400,
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
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryGreen),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading job categories...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _errorMessage != null
                            ? Container(
                                height: 400,
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
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.error,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      CustomButton(
                                        text: 'Retry',
                                        onPressed: _loadJobCategories,
                                        width: 120,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  // Job Types Selection
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.work_outline,
                                                color: AppColors.primaryGreen,
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
                                                    'Select Job Types',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Choose all services you can provide (select at least 2)',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),

                                        // Job Types Grid
                                        _availableJobTypes.isEmpty
                                            ? Container(
                                                height: 200,
                                                child: Center(
                                                  child: Text(
                                                    'No job categories available',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  crossAxisSpacing: 16,
                                                  mainAxisSpacing: 16,
                                                  childAspectRatio: 1.1,
                                                ),
                                                itemCount:
                                                    _availableJobTypes.length,
                                                itemBuilder: (context, index) {
                                                  final jobType =
                                                      _availableJobTypes[index];
                                                  final isSelected =
                                                      _selectedJobTypes
                                                          .contains(
                                                              jobType['id']);

                                                  return GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        if (isSelected) {
                                                          _selectedJobTypes
                                                              .remove(jobType[
                                                                  'id']);
                                                          _certificatesUploaded
                                                              .remove(jobType[
                                                                  'id']);
                                                        } else {
                                                          _selectedJobTypes.add(
                                                              jobType['id']);
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? AppColors
                                                                .primaryGreen
                                                                .withOpacity(
                                                                    0.1)
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? AppColors
                                                                  .primaryGreen
                                                              : AppColors
                                                                  .lightGrey
                                                                  .withOpacity(
                                                                      0.3),
                                                          width: 2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.05),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  jobType[
                                                                      'icon'],
                                                                  size: 36,
                                                                  color: isSelected
                                                                      ? AppColors
                                                                          .primaryGreen
                                                                      : AppColors
                                                                          .textSecondary,
                                                                ),
                                                                const SizedBox(
                                                                    height: 12),
                                                                Text(
                                                                  jobType[
                                                                      'name'],
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: isSelected
                                                                        ? AppColors
                                                                            .primaryGreen
                                                                        : AppColors
                                                                            .textPrimary,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Text(
                                                                  jobType[
                                                                      'description'],
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: AppColors
                                                                        .textSecondary,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (isSelected)
                                                            Positioned(
                                                              top: 8,
                                                              right: 8,
                                                              child: Container(
                                                                width: 24,
                                                                height: 24,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: AppColors
                                                                      .primaryGreen,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: Icon(
                                                                  Icons.check,
                                                                  size: 16,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Certificates Upload Section
                                  if (_selectedJobTypes.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.file_upload_outlined,
                                                  color: AppColors.primaryGreen,
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
                                                      'Upload Certificates',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Upload certificates or training documents (optional but recommended)',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          // Certificate upload for each selected job type
                                          ..._selectedJobTypes.map((jobTypeId) {
                                            final jobType =
                                                _availableJobTypes.firstWhere(
                                              (jt) => jt['id'] == jobTypeId,
                                              orElse: () => {
                                                'id': jobTypeId,
                                                'name': 'Unknown Category',
                                                'icon': Icons.work,
                                              },
                                            );
                                            final isUploaded =
                                                _certificatesUploaded[
                                                        jobTypeId] ??
                                                    false;

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 16),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: isUploaded
                                                    ? AppColors.success
                                                        .withOpacity(0.1)
                                                    : AppColors.lightGrey
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isUploaded
                                                      ? AppColors.success
                                                      : AppColors.lightGrey
                                                          .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    jobType['icon'],
                                                    color: isUploaded
                                                        ? AppColors.success
                                                        : AppColors
                                                            .textSecondary,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${jobType['name']} Certificate',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          isUploaded
                                                              ? 'Certificate uploaded successfully'
                                                              : 'Upload relevant certificates or training documents',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isUploaded
                                                                ? AppColors
                                                                    .success
                                                                : AppColors
                                                                    .textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  CustomButton(
                                                    text: isUploaded
                                                        ? 'Uploaded'
                                                        : 'Upload',
                                                    onPressed: () =>
                                                        _uploadCertificate(
                                                            jobTypeId),
                                                    width: 100,
                                                    height: 40,
                                                    backgroundColor: isUploaded
                                                        ? AppColors.success
                                                        : AppColors
                                                            .primaryGreen,
                                                    icon: isUploaded
                                                        ? Icons.check
                                                        : Icons.upload_file,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
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
                            text: _selectedJobTypes.length >= 2
                                ? 'Continue to Documents'
                                : 'Select at least 2 services',
                            onPressed: _selectedJobTypes.length >= 2 &&
                                    !_isLoading &&
                                    !_isLoadingCategories
                                ? _continueToNext
                                : null,
                            isLoading: _isLoading,
                            icon: Icons.arrow_forward,
                            enabled: _selectedJobTypes.length >= 2 &&
                                !_isLoading &&
                                !_isLoadingCategories,
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
                                  color:
                                      AppColors.textSecondary.withOpacity(0.3),
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
          ),
        ],
      ),
    );
  }

  void _uploadCertificate(String jobTypeId) {
    setState(() {
      _certificatesUploaded[jobTypeId] = true;
    });

    final jobType =
        _availableJobTypes.firstWhere((jt) => jt['id'] == jobTypeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${jobType['name']} certificate uploaded successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _continueToNext() {
    if (_selectedJobTypes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 services'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine registration data with job types and certificates
      Map<String, dynamic> updatedData =
          Map.from(widget.registrationData ?? {});
      updatedData['selectedJobTypes'] = _selectedJobTypes;
      updatedData['certificates'] = _certificatesUploaded;

      // Navigate to page 3 with updated data
      if (mounted) {
        context.go('/helper-register-3', extra: updatedData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
