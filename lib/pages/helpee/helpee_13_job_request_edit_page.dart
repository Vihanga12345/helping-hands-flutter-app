import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/supabase_service.dart';
import '../../services/localization_service.dart';

class Helpee13JobRequestEditPage extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? jobData;

  const Helpee13JobRequestEditPage({
    super.key,
    this.jobId,
    this.jobData,
  });

  @override
  State<Helpee13JobRequestEditPage> createState() =>
      _Helpee13JobRequestEditPageState();
}

class _Helpee13JobRequestEditPageState
    extends State<Helpee13JobRequestEditPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedJobType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  final List<String> _jobTypes = [
    'Gardening',
    'Housekeeping', 
    'Childcare',
    'Cooking',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.jobData != null) {
      final jobData = widget.jobData!;

      print('🔍 Job data structure: $jobData');

      // Pre-populate form fields with existing job data - with safe handling
      try {
        _selectedJobType =
            _getSafeString(jobData, 'category_name', 'Housekeeping');
        _descriptionController.text =
            _getSafeString(jobData, 'description', '');
        _locationController.text = _getSafeString(jobData, 'location', '');
        _budgetController.text = _getSafeString(jobData, 'hourly_rate', '2500');
      } catch (e) {
        print('❌ Error initializing form data: $e');
        // Set default values
        _selectedJobType = 'Housekeeping';
        _descriptionController.text = '';
        _locationController.text = '';
        _budgetController.text = '2500';
      }

      // Parse date - handle both raw and formatted dates
      if (jobData['date'] != null) {
        try {
          final dateValue = jobData['date'];
          if (dateValue is String) {
            // Check if it's already formatted (like "25th Dec 2024") or raw date
            if (dateValue.contains('-') || dateValue.contains('/')) {
              _selectedDate = DateTime.parse(dateValue);
            } else {
              // Use current date if formatted string
              _selectedDate = DateTime.now();
            }
          } else {
            _selectedDate = DateTime.now();
          }
        } catch (e) {
          _selectedDate = DateTime.now();
        }
      } else {
        _selectedDate = DateTime.now();
      }

      // Parse time - handle both raw and formatted times
      if (jobData['time'] != null) {
        try {
          final timeValue = jobData['time'];
          if (timeValue is String) {
            final timeString = timeValue.toString();
            if (timeString.contains(':')) {
              // Remove AM/PM if present and parse
              final cleanTime =
                  timeString.replaceAll(RegExp(r'[APMapm\s]'), '');
              final parts = cleanTime.split(':');
              if (parts.length >= 2) {
                _selectedTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              } else {
                _selectedTime = const TimeOfDay(hour: 10, minute: 0);
              }
            } else {
              _selectedTime = const TimeOfDay(hour: 10, minute: 0);
            }
          } else {
            _selectedTime = const TimeOfDay(hour: 10, minute: 0);
          }
        } catch (e) {
          _selectedTime = const TimeOfDay(hour: 10, minute: 0);
        }
      } else {
        _selectedTime = const TimeOfDay(hour: 10, minute: 0);
      }
    } else {
      // Default values if no job data is provided
      _selectedJobType = 'Housekeeping';
      _selectedDate = DateTime.now();
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
      _budgetController.text = '2500';
    }
  }

  /// Safely extract string values from job data
  String _getSafeString(
      Map<String, dynamic> data, String key, String defaultValue) {
    try {
      final value = data[key];
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is num) return value.toString();
      return defaultValue;
    } catch (e) {
      print('❌ Error getting safe string for $key: $e');
      return defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String jobId = widget.jobId ?? 'Unknown Job';
    
    return Scaffold(
      body: Column(
        children: [
          // Header with Save button
          AppHeader(
            title: 'Edit Job Request'.tr(),
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
            rightWidget: GestureDetector(
              onTap: _saveChanges,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Warning Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info, color: AppColors.warning),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Job is under review. Some changes may require re-approval.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Service Type (Read-only)
                        const Text(
                          'Service Type', 
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                            color: AppColors.lightGrey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGrey),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedJobType ?? 'Loading...',
                                  style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.lock_outline,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Location
                        const Text(
                          'Location', 
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Enter or select location',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.lightGrey),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a location';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Date and Time
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date', 
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _selectDate,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.lightGrey),
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.white,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              color: AppColors.primaryGreen),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedDate != null
                                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                                : 'Select date',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Time', 
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _selectTime,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.lightGrey),
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.white,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              color: AppColors.primaryGreen),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedTime != null
                                                ? _selectedTime!.format(context)
                                                : 'Select time',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Description
                        const Text(
                          'Job Description', 
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe what help you need...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.lightGrey),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please provide a job description';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),

                        // Job Questions (if any)
                        if (widget.jobData != null &&
                            widget.jobData!['questions'] != null &&
                            (widget.jobData!['questions'] as List)
                                .isNotEmpty) ...[
                          const Text(
                            'Job Specifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildJobQuestionsWidget(),
                          const SizedBox(height: 20),
                        ],
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.lightGrey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
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

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Widget _buildJobQuestionsWidget() {
    final questions =
        widget.jobData!['questions'] as List<Map<String, dynamic>>;

    return Column(
      children: questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        final questionData = question['question'] as Map<String, dynamic>?;
        final questionText = questionData?['question'] ?? 'No question';
        final questionType = questionData?['question_type'] ?? 'text';
        final isRequired = questionData?['is_required'] == true;
        final currentAnswer = question['processed_answer'] ?? '';

        return Padding(
          padding:
              EdgeInsets.only(bottom: index < questions.length - 1 ? 16 : 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Q${index + 1}: $questionText',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('question_${question['id']}'),
                  initialValue: currentAnswer,
                  decoration: InputDecoration(
                    hintText: isRequired
                        ? 'Enter your answer (required)'.tr()
                        : 'Enter your answer'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            isRequired ? AppColors.error : AppColors.lightGrey,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  validator: isRequired
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This question is required'.tr();
                          }
                          return null;
                        }
                      : null,
                  onChanged: (value) {
                    // Store the answer for saving later
                    question['updated_answer'] = value;
                    question['is_answered'] = value.trim().isNotEmpty;
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveChanges() async {
    // Validate required questions first
    if (!_validateRequiredQuestions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please answer all required questions before saving.'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedJobType != null) {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saving changes...'.tr()),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        // Update job details
        final success = await _updateJobInDatabase();

        if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job request updated successfully!'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update job request. Please try again.'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating job: $e'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _validateRequiredQuestions() {
    if (widget.jobData == null || widget.jobData!['questions'] == null) {
      return true; // No questions to validate
    }

    final questions =
        widget.jobData!['questions'] as List<Map<String, dynamic>>;

    for (final question in questions) {
      final questionData = question['question'] as Map<String, dynamic>?;
      final isRequired = questionData?['is_required'] == true;

      if (isRequired) {
        final updatedAnswer = question['updated_answer'];
        final currentAnswer = question['processed_answer'] ?? '';

        // Check if the question has been answered (either updated or has existing answer)
        if ((updatedAnswer == null ||
                updatedAnswer.toString().trim().isEmpty) &&
            currentAnswer.trim().isEmpty) {
          return false; // Required question not answered
        }
      }
    }

    return true; // All required questions answered
  }

  Future<bool> _updateJobInDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final jobId = widget.jobId;

      if (jobId == null) {
        throw Exception('Job ID is required for updating');
      }

      print('🔄 Starting job update for ID: $jobId');

      // Update basic job information
      final updatedFields = <String, dynamic>{};

      if (_descriptionController.text.trim().isNotEmpty) {
        updatedFields['description'] = _descriptionController.text.trim();
      }

      if (_locationController.text.trim().isNotEmpty) {
        updatedFields['location_address'] = _locationController.text.trim();
      }

      if (_selectedDate != null) {
        updatedFields['scheduled_date'] =
            _selectedDate!.toIso8601String().split('T')[0];
      }

      if (_selectedTime != null) {
        final timeString =
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
        updatedFields['scheduled_start_time'] = timeString;
        updatedFields['scheduled_time'] = timeString;
      }

      updatedFields['updated_at'] = DateTime.now().toIso8601String();

      // Update job record
      if (updatedFields.isNotEmpty) {
        print('🔄 Updating job fields: ${updatedFields.keys.join(', ')}');
        await supabase.from('jobs').update(updatedFields).eq('id', jobId);
        print('✅ Job fields updated successfully');
      }

      // Update question answers if any questions were modified
      if (widget.jobData != null && widget.jobData!['questions'] != null) {
        final questions =
            widget.jobData!['questions'] as List<Map<String, dynamic>>;

        print('🔄 Processing ${questions.length} questions for answers...');

        for (final question in questions) {
          final updatedAnswer = question['updated_answer'];
          final currentAnswer = question['processed_answer'] ?? '';

          // Only update if answer was changed or if there's a new answer
          if (updatedAnswer != null &&
              updatedAnswer.toString().trim().isNotEmpty) {
            final questionData = question['question'] as Map<String, dynamic>?;
            final questionType = questionData?['question_type'] ?? 'text';
            final questionId = questionData?['id'];
            final answerRecordId = question['id'];

            print(
                '🔄 Updating answer for question: ${questionData?['question']}');
            print('   Answer: $updatedAnswer');
            print('   Type: $questionType');

            // Prepare answer fields - save to BOTH main answer column AND specific type column
            final answerFields = <String, dynamic>{
              'answer': updatedAnswer.toString().trim(), // Main answer column
              'updated_at': DateTime.now().toIso8601String(),
            };

            // Also save to type-specific column for proper data structure
            switch (questionType) {
              case 'text':
                answerFields['answer_text'] = updatedAnswer.toString().trim();
                break;
              case 'number':
                final numberValue = int.tryParse(updatedAnswer.toString()) ??
                    double.tryParse(updatedAnswer.toString()) ??
                    0;
                answerFields['answer_number'] = numberValue;
                answerFields['answer_text'] = updatedAnswer.toString().trim();
                break;
              case 'yes_no':
                final boolValue =
                    updatedAnswer.toString().toLowerCase() == 'yes' ||
                        updatedAnswer.toString().toLowerCase() == 'true' ||
                        updatedAnswer.toString() == '1';
                answerFields['answer_boolean'] = boolValue;
                answerFields['answer_text'] = updatedAnswer.toString().trim();
                break;
              case 'date':
                try {
                  DateTime.parse(
                      updatedAnswer.toString()); // Validate date format
                  answerFields['answer_date'] = updatedAnswer.toString();
                } catch (e) {
                  print(
                      '⚠️ Invalid date format, saving as text: $updatedAnswer');
                }
                answerFields['answer_text'] = updatedAnswer.toString().trim();
                break;
              case 'time':
                answerFields['answer_time'] = updatedAnswer.toString();
                answerFields['answer_text'] = updatedAnswer.toString().trim();
                break;
              default:
                answerFields['answer_text'] = updatedAnswer.toString().trim();
            }

            try {
              // Update existing answer record
              if (answerRecordId != null) {
                await supabase
                    .from('job_question_answers')
                    .update(answerFields)
                    .eq('id', answerRecordId);
                print('✅ Updated existing answer record');
              } else {
                // Create new answer record if it doesn't exist
                answerFields['job_id'] = jobId;
                answerFields['question_id'] = questionId;
                await supabase
                    .from('job_question_answers')
                    .insert(answerFields);
                print('✅ Created new answer record');
              }
            } catch (e) {
              print('❌ Error updating answer: $e');
              // Continue with other answers even if one fails
            }
          }
        }
        print('✅ All question answers processed');
      }

      print('✅ Job updated successfully in database');
      return true;
    } catch (e) {
      print('❌ Error updating job in database: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }
} 
