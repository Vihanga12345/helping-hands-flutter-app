import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

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

  // Available job types/services
  final List<Map<String, dynamic>> _availableJobTypes = [
    {
      'id': 'house_cleaning',
      'name': 'House Cleaning',
      'icon': Icons.cleaning_services,
      'description': 'General house cleaning services',
    },
    {
      'id': 'deep_cleaning',
      'name': 'Deep Cleaning',
      'icon': Icons.auto_awesome,
      'description': 'Thorough deep cleaning services',
    },
    {
      'id': 'gardening',
      'name': 'Gardening',
      'icon': Icons.yard,
      'description': 'Garden maintenance and landscaping',
    },
    {
      'id': 'cooking',
      'name': 'Cooking',
      'icon': Icons.restaurant,
      'description': 'Meal preparation and cooking',
    },
    {
      'id': 'elderly_care',
      'name': 'Elderly Care',
      'icon': Icons.elderly,
      'description': 'Care for elderly individuals',
    },
    {
      'id': 'childcare',
      'name': 'Childcare',
      'icon': Icons.child_care,
      'description': 'Looking after children',
    },
    {
      'id': 'pet_care',
      'name': 'Pet Care',
      'icon': Icons.pets,
      'description': 'Pet sitting and care',
    },
    {
      'id': 'tutoring',
      'name': 'Tutoring',
      'icon': Icons.school,
      'description': 'Educational tutoring services',
    },
  ];

  // Certificate tracking
  final Map<String, bool> _certificatesUploaded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Types & Certificates'),
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
          child: Form(
            key: _formKey,
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
                          _buildProgressBubble(true, 2), // Current page
                          _buildProgressLine(false),
                          _buildProgressBubble(false, 3),
                          _buildProgressLine(false),
                          _buildProgressBubble(false, 4),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Step 2 of 4: Select Your Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the services you offer and upload relevant certificates',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Types Selection
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
                                  Icon(
                                    Icons.work_outline,
                                    color: AppColors.primaryGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Select Job Types',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose all services you can provide (select at least 2)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Job Types Grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.1,
                                ),
                                itemCount: _availableJobTypes.length,
                                itemBuilder: (context, index) {
                                  final jobType = _availableJobTypes[index];
                                  final isSelected =
                                      _selectedJobTypes.contains(jobType['id']);

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedJobTypes
                                              .remove(jobType['id']);
                                          _certificatesUploaded
                                              .remove(jobType['id']);
                                        } else {
                                          _selectedJobTypes.add(jobType['id']);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                                .withOpacity(0.1)
                                            : AppColors.lightGrey
                                                .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryGreen
                                              : AppColors.lightGrey,
                                          width: 2,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  jobType['icon'],
                                                  size: 32,
                                                  color: isSelected
                                                      ? AppColors.primaryGreen
                                                      : AppColors.textSecondary,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  jobType['name'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? AppColors.primaryGreen
                                                        : AppColors.textPrimary,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  jobType['description'],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: AppColors.white,
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
                                    Icon(
                                      Icons.file_upload,
                                      color: AppColors.primaryGreen,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Upload Certificates',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload certificates or training documents for your selected services (optional but recommended)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Certificate upload for each selected job type
                                ..._selectedJobTypes.map((jobTypeId) {
                                  final jobType = _availableJobTypes.firstWhere(
                                    (jt) => jt['id'] == jobTypeId,
                                  );
                                  final isUploaded =
                                      _certificatesUploaded[jobTypeId] ?? false;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isUploaded
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.lightGrey
                                              .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isUploaded
                                            ? AppColors.success
                                            : AppColors.lightGrey,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          jobType['icon'],
                                          color: isUploaded
                                              ? AppColors.success
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${jobType['name']} Certificate',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                isUploaded
                                                    ? 'Certificate uploaded successfully'
                                                    : 'Upload relevant certificates or training documents',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isUploaded
                                                      ? AppColors.success
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _uploadCertificate(jobTypeId),
                                          icon: Icon(
                                            isUploaded
                                                ? Icons.check
                                                : Icons.upload_file,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isUploaded ? 'Uploaded' : 'Upload',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isUploaded
                                                ? AppColors.success
                                                : AppColors.primaryGreen,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],

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
                          onPressed:
                              _selectedJobTypes.length >= 2 && !_isLoading
                                  ? _continueToNext
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
                                  _selectedJobTypes.length >= 2
                                      ? 'Continue to Documents'
                                      : 'Select at least 2 services',
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
