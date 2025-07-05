import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/job_questions_widget.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';
import '../../services/supabase_service.dart';
import '../../services/job_questions_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/job_data_service.dart';

class Helpee7JobRequestPage extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? jobData;

  const Helpee7JobRequestPage({
    super.key,
    this.isEdit = false,
    this.jobData,
  });

  @override
  State<Helpee7JobRequestPage> createState() => _Helpee7JobRequestPageState();
}

class _Helpee7JobRequestPageState extends State<Helpee7JobRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategoryId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  // Job posting type
  String _jobPostingType = 'public'; // public or private

  // Helper search for private jobs
  Map<String, dynamic>? _selectedHelper;
  final _helperSearchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  List<Map<String, dynamic>> _jobCategories = [];
  List<Map<String, dynamic>> _jobQuestions = [];
  List<Map<String, dynamic>> _questionAnswers = [];
  double? _defaultHourlyRate;
  bool _isLoading = false;

  final _authService = CustomAuthService();

  @override
  void initState() {
    super.initState();
    _loadJobCategories();

    // If in edit mode, pre-populate fields
    if (widget.isEdit && widget.jobData != null) {
      _prePopulateFieldsForEdit();
    }
  }

  void _prePopulateFieldsForEdit() {
    final jobData = widget.jobData!;

    // Pre-populate basic fields
    _titleController.text = jobData['title'] ?? '';
    _descriptionController.text = jobData['description'] ?? '';
    _locationController.text = jobData['location_address'] ?? '';
    _notesController.text = jobData['notes'] ?? '';

    // Set category
    _selectedCategoryId = jobData['category_id'];

    // Set job type (private/public)
    _jobPostingType = jobData['is_private'] == true ? 'private' : 'public';

    // Set date and time
    if (jobData['scheduled_date'] != null) {
      try {
        _selectedDate = DateTime.parse(jobData['scheduled_date']);
      } catch (e) {
        print('Error parsing scheduled_date: $e');
      }
    }

    if (jobData['scheduled_time'] != null ||
        jobData['scheduled_start_time'] != null) {
      try {
        final timeString =
            jobData['scheduled_time'] ?? jobData['scheduled_start_time'];
        final time =
            TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 $timeString'));
        _selectedTime = time;
      } catch (e) {
        print('Error parsing scheduled_time: $e');
      }
    }

    // Load questions for the selected category
    if (_selectedCategoryId != null) {
      _loadJobQuestions(_selectedCategoryId!);

      // Pre-populate question answers
      final parsedQuestions = jobData['parsed_questions'] as List? ?? [];
      _questionAnswers = parsedQuestions.map((qa) {
        return {
          'question_id': qa['question_id'],
          'answer_text': qa['answer_text'],
          'answer_number': qa['answer_number'],
          'answer_date': qa['answer_date'],
          'answer_time': qa['answer_time'],
          'answer_boolean': qa['answer_boolean'],
          'selected_options': qa['selected_options'],
        };
      }).toList();
    }
  }

  Future<void> _loadJobCategories() async {
    try {
      final categories = await SupabaseService().getJobCategories();
      setState(() {
        _jobCategories = categories;
      });
    } catch (e) {
      print('Error loading job categories: $e');
    }
  }

  Future<void> _loadJobQuestions(String categoryId) async {
    try {
      final questions =
          await JobQuestionsService().getQuestionsForCategory(categoryId);

      // Get default hourly rate for this category (this would come from a job_category_rates table)
      // For now, we'll use a sample rate calculation
      double defaultRate = _calculateDefaultRate(categoryId);

      setState(() {
        _jobQuestions = questions;
        _defaultHourlyRate = defaultRate;
        _questionAnswers.clear(); // Reset answers when category changes
      });
    } catch (e) {
      print('Error loading job questions: $e');
    }
  }

  double _calculateDefaultRate(String categoryId) {
    // This would typically come from a database table with category-specific rates
    // For now, using sample rates based on category
    final Map<String, double> categoryRates = {
      'house_cleaning': 2500.0,
      'deep_cleaning': 3000.0,
      'gardening': 2000.0,
      'pet_care': 1800.0,
      'elderly_care': 3500.0,
      'tutoring': 2800.0,
      'tech_support': 4000.0,
      'photography': 5000.0,
      'fitness_training': 3200.0,
      'cooking': 2200.0,
    };

    // Try to find rate by category name or return default
    final category = _jobCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {},
    );

    if (category.isNotEmpty) {
      String categoryName =
          category['name'].toString().toLowerCase().replaceAll(' ', '_');
      return categoryRates[categoryName] ?? 2500.0;
    }

    return 2500.0; // Default rate
  }

  Future<void> _searchHelpers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search helpers by name (this would be an actual API call)
      // For now, using sample data
      await Future.delayed(const Duration(milliseconds: 500));

      final sampleHelpers = [
        {
          'id': '1',
          'name': 'John Smith',
          'rating': 4.8,
          'jobCount': 156,
          'profileImageUrl': 'https://placehold.co/50x50',
          'category': 'House Cleaning',
          'experience': '3 years',
          'hourlyRate': 2500.0,
          'distance': '2.3 km',
        },
        {
          'id': '2',
          'name': 'Sarah Johnson',
          'rating': 4.9,
          'jobCount': 203,
          'profileImageUrl': 'https://placehold.co/50x50',
          'category': 'Deep Cleaning',
          'experience': '5 years',
          'hourlyRate': 3000.0,
          'distance': '1.8 km',
        },
        {
          'id': '3',
          'name': 'Mike Wilson',
          'rating': 4.7,
          'jobCount': 98,
          'profileImageUrl': 'https://placehold.co/50x50',
          'category': 'Gardening',
          'experience': '2 years',
          'hourlyRate': 2000.0,
          'distance': '3.1 km',
        },
      ];

      final filteredResults = sampleHelpers
          .where((helper) => helper['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error searching helpers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: widget.isEdit ? 'Edit Job Request' : 'Request Helper',
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Type Dropdown
                    const Text(
                      'Job Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        hintText: 'Select job type',
                        prefixIcon: const Icon(Icons.work),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.lightGrey),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      items: _jobCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                        if (value != null) {
                          _loadJobQuestions(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a job type';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Job-Specific Questions
                    if (_jobQuestions.isNotEmpty) ...[
                      const Text(
                        'Job Requirements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      JobQuestionsWidget(
                        questions: _jobQuestions,
                        onAnswersChanged: (answers) {
                          setState(() {
                            _questionAnswers = answers;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Job Title
                    const Text(
                      'Job Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter a clear job title',
                        prefixIcon: const Icon(Icons.title),
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
                          return 'Please enter a job title';
                        }
                        return null;
                      },
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
                        hintText: 'Enter job location',
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
                          return 'Please enter the job location';
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: AppColors.lightGrey),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedDate != null
                                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                            : 'Select date',
                                        style: TextStyle(
                                          color: _selectedDate != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: AppColors.lightGrey),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedTime != null
                                            ? _selectedTime!.format(context)
                                            : 'Select time',
                                        style: TextStyle(
                                          color: _selectedTime != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
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

                    // Default Hourly Rate Display
                    if (_defaultHourlyRate != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money,
                                color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Text(
                              'Suggested Rate: LKR ${_defaultHourlyRate!.toStringAsFixed(0)}/hour',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Job Type Selection (Public/Private) - Styled Radio Buttons
                    const Text(
                      'Job Visibility',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _jobPostingType = 'public';
                                _selectedHelper = null;
                                _helperSearchController.clear();
                                _searchResults = [];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _jobPostingType == 'public'
                                    ? AppColors.primaryGreen.withOpacity(0.1)
                                    : AppColors.white,
                                border: Border.all(
                                  color: _jobPostingType == 'public'
                                      ? AppColors.primaryGreen
                                      : AppColors.lightGrey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _jobPostingType == 'public'
                                            ? AppColors.primaryGreen
                                            : AppColors.lightGrey,
                                        width: 2,
                                      ),
                                      color: _jobPostingType == 'public'
                                          ? AppColors.primaryGreen
                                          : AppColors.white,
                                    ),
                                    child: _jobPostingType == 'public'
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: AppColors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Public Job',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'All helpers can see and apply',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _jobPostingType = 'private';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _jobPostingType == 'private'
                                    ? AppColors.primaryGreen.withOpacity(0.1)
                                    : AppColors.white,
                                border: Border.all(
                                  color: _jobPostingType == 'private'
                                      ? AppColors.primaryGreen
                                      : AppColors.lightGrey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _jobPostingType == 'private'
                                            ? AppColors.primaryGreen
                                            : AppColors.lightGrey,
                                        width: 2,
                                      ),
                                      color: _jobPostingType == 'private'
                                          ? AppColors.primaryGreen
                                          : AppColors.white,
                                    ),
                                    child: _jobPostingType == 'private'
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: AppColors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Private Job',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Invite specific helper',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
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
                      ],
                    ),

                    // Helper Search for Private Jobs
                    if (_jobPostingType == 'private') ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Search Helper',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Selected Helper Display
                      if (_selectedHelper != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: HelperProfileBar(
                                  name: _selectedHelper!['name'],
                                  rating: _selectedHelper!['rating'],
                                  jobCount: _selectedHelper!['jobCount'],
                                  jobTypes: [
                                    _selectedHelper!['category']
                                            ?.toLowerCase() ??
                                        'general'
                                  ],
                                  profileImageUrl:
                                      _selectedHelper!['profileImageUrl'],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedHelper = null;
                                    _helperSearchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.close,
                                    color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Helper Search Field
                        TextFormField(
                          controller: _helperSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search helper by name...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.lightGrey),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          onChanged: _searchHelpers,
                          validator: (value) {
                            if (_jobPostingType == 'private' &&
                                _selectedHelper == null) {
                              return 'Please select a helper for private jobs';
                            }
                            return null;
                          },
                        ),

                        // Search Results
                        if (_searchResults.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final helper = _searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(helper['profileImageUrl']),
                                    radius: 20,
                                  ),
                                  title: Text(helper['name']),
                                  subtitle: Text(
                                      '${helper['category']} • ${helper['distance']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                      Text(helper['rating'].toString()),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedHelper = helper;
                                      _helperSearchController.clear();
                                      _searchResults = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ],

                    const SizedBox(height: 20),

                    // Additional Notes
                    const Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Any additional information or special requirements...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.lightGrey),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
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
                                widget.isEdit
                                    ? 'Update Job Request'
                                    : (_jobPostingType == 'private'
                                        ? 'Send Private Request'
                                        : 'Post Public Job'),
                                style: const TextStyle(
                                  fontSize: 18,
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

          // Bottom Navigation
          const AppNavigationBar(
            currentTab: NavigationTab.calendar,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date for the job'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time for the job'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate required questions first
    bool hasValidQuestionAnswers = true;
    List<String> missingRequiredQuestions = [];

    for (final question in _jobQuestions) {
      final isRequired = question['is_required'] == true;
      if (isRequired) {
        final questionId = question['id'];
        final questionText = question['question'];

        // Check if this question has been answered
        final answer = _questionAnswers.firstWhere(
          (answer) => answer['question_id'] == questionId,
          orElse: () => {},
        );

        if (answer.isEmpty) {
          hasValidQuestionAnswers = false;
          missingRequiredQuestions.add(questionText);
        } else {
          // Check if the answer has content
          final hasContent = (answer['answer_text'] != null &&
                  answer['answer_text'].toString().trim().isNotEmpty) ||
              (answer['answer_number'] != null) ||
              (answer['answer_boolean'] != null) ||
              (answer['selected_options'] != null &&
                  (answer['selected_options'] as List).isNotEmpty);

          if (!hasContent) {
            hasValidQuestionAnswers = false;
            missingRequiredQuestions.add(questionText);
          }
        }
      }
    }

    if (!hasValidQuestionAnswers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please answer all required questions:\n• ${missingRequiredQuestions.join('\n• ')}',
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare question answers for submission
      final questionAnswers = _questionAnswers.map((answer) {
        return {
          'question_id': answer['question_id'],
          'answer_text': answer['answer_text'],
          'answer_number': answer['answer_number'],
          'answer_date': answer['answer_date'],
          'answer_time': answer['answer_time'],
          'answer_boolean': answer['answer_boolean'],
          'selected_options': answer['selected_options'],
        };
      }).toList();

      print(
          '🔄 Submitting job with ${questionAnswers.length} question answers');
      print('🎯 Selected Category ID: $_selectedCategoryId');
      print('🎯 Job Posting Type (public/private): $_jobPostingType');
      print(
          '🎯 Selected Helper: ${_selectedHelper?['name'] ?? 'None (public job)'}');
      for (final answer in questionAnswers) {
        print(
            '   Question ${answer['question_id']}: ${answer['answer_text']} (${answer.keys.where((k) => k != 'question_id' && answer[k] != null).join(', ')})');
      }

      if (widget.isEdit && widget.jobData != null) {
        // Update existing job
        final jobDataService = JobDataService();
        final jobCategoryName = _jobCategories.firstWhere(
          (cat) => cat['id'] == _selectedCategoryId,
          orElse: () => {'name': 'Unknown'},
        )['name'];

        final success = await jobDataService.updateJobWithQuestions(
          jobId: widget.jobData!['id'],
          title: _titleController.text.trim(),
          description: _notesController.text.trim(),
          categoryId: _selectedCategoryId!,
          jobCategoryName: jobCategoryName,
          hourlyRate: _defaultHourlyRate ?? 2500.0,
          scheduledDate: _selectedDate!,
          scheduledTime:
              '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          locationAddress: _locationController.text.trim(),
          isPrivate: _jobPostingType == 'private',
          notes: _notesController.text.trim(),
          questionAnswers: questionAnswers,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Job request updated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        } else {
          throw Exception('Failed to update job');
        }
      } else {
        // Create new job
        final jobCategoryName = _jobCategories.firstWhere(
          (cat) => cat['id'] == _selectedCategoryId,
          orElse: () => {'name': 'Unknown'},
        )['name'];

        final jobData = await SupabaseService().createJobWithQuestions(
          helpeeId: _authService.currentUser?['user_id'] ?? '',
          categoryId: _selectedCategoryId!,
          jobCategoryName: jobCategoryName,
          title: _titleController.text.trim(),
          description: _notesController.text.trim(),
          jobType: _jobPostingType,
          hourlyRate: _defaultHourlyRate ?? 2500.0,
          scheduledDate: _selectedDate!.toIso8601String().split('T')[0],
          scheduledStartTime:
              '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          locationLatitude: 6.9271, // TODO: Get from map selection
          locationLongitude: 79.8612, // TODO: Get from map selection
          locationAddress: _locationController.text.trim(),
          questionAnswers: questionAnswers,
          invitedHelperEmail:
              _jobPostingType == 'private' && _selectedHelper != null
                  ? _selectedHelper![
                      'email'] // This would come from the helper data
                  : null,
          specialInstructions: _notesController.text.trim(),
        );

        if (jobData != null) {
          print('✅ Job created successfully with ID: ${jobData['id']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_jobPostingType == 'private'
                    ? 'Private job request sent successfully!'
                    : 'Public job posted successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Navigate back to home or jobs page
            if (context.canPop()) {
            context.pop();
            } else {
              context.go('/helpee/home');
            }
          }
        } else {
          throw Exception('Failed to create job - no data returned');
        }
      }
    } catch (e) {
      print('❌ Error ${widget.isEdit ? 'updating' : 'submitting'} job: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${widget.isEdit ? 'updating' : 'submitting'} job: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
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
    _descriptionController.dispose();
    _locationController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _helperSearchController.dispose();
    super.dispose();
  }
}
