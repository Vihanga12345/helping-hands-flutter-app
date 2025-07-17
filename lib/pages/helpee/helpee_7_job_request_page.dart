import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
import '../../services/localization_service.dart';
import '../../services/popup_manager_service.dart';

class Helpee7JobRequestPage extends StatefulWidget {
  const Helpee7JobRequestPage({
    super.key,
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

  // Location coordinates for map integration
  double? _selectedLatitude;
  double? _selectedLongitude;

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
  bool _hasAIBotAnswers = false; // Track if answers came from AI bot
  double? _defaultHourlyRate;
  bool _isLoading = false;

  final _authService = CustomAuthService();
  final _popupManager = PopupManagerService();

  @override
  void initState() {
    super.initState();
    _loadJobCategories();

    // Handle returning data from helper selection and AI bot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleReturningData();
      _handleAIBotData();
    });
  }

  // Handle extracted data from AI bot conversation
  void _handleAIBotData() {
    final context = this.context;
    if (context.mounted) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

      if (extra != null && extra['extractedData'] != null) {
        final extractedData = extra['extractedData'] as Map<String, dynamic>;
        print('🤖 AI Bot data received: $extractedData');

        setState(() {
          // Populate form fields with AI extracted data
          if (extractedData['jobCategoryId'] != null) {
            _selectedCategoryId = extractedData['jobCategoryId'];
          }

          if (extractedData['title'] != null) {
            _titleController.text = extractedData['title'];
          }

          if (extractedData['description'] != null) {
            _descriptionController.text = extractedData['description'];
            _notesController.text = extractedData['description'];
          }

          if (extractedData['location'] != null) {
            _locationController.text = extractedData['location'];
          }

          if (extractedData['defaultHourlyRate'] != null) {
            _defaultHourlyRate = extractedData['defaultHourlyRate'].toDouble();
          }

          // Handle job posting type and selected helper
          if (extractedData['jobPostingType'] != null) {
            _jobPostingType = extractedData['jobPostingType'];
            print('✅ Job posting type set to: $_jobPostingType');
          }

          if (extractedData['selectedHelper'] != null) {
            _selectedHelper = extractedData['selectedHelper'];
            _helperSearchController.text =
                _selectedHelper!['full_name']?.toString() ?? '';
            print('✅ Selected helper: ${_selectedHelper!['full_name']}');
          }

          if (extractedData['preferredDate'] != null) {
            try {
              _selectedDate = DateTime.parse(extractedData['preferredDate']);
            } catch (e) {
              print('Error parsing date: $e');
            }
          }

          if (extractedData['preferredTime'] != null) {
            try {
              final timeStr = extractedData['preferredTime'] as String;
              final timeParts = timeStr.split(':');
              if (timeParts.length >= 2) {
                _selectedTime = TimeOfDay(
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1]),
                );
              }
            } catch (e) {
              print('Error parsing time: $e');
            }
          }

          // Handle job-specific question answers
          if (extractedData['jobQuestionAnswers'] != null) {
            final answers = extractedData['jobQuestionAnswers'] as List;
            _questionAnswers = answers
                .map((answer) => {
                      'question_id': answer['questionId'],
                      'answer_text': answer[
                          'answer'], // Map 'answer' to 'answer_text' for widget compatibility
                      'selected_options':
                          null, // Initialize for multiple choice questions
                    })
                .toList();
            _hasAIBotAnswers = true; // Mark that these answers came from AI bot
            print(
                '✅ Job-specific answers populated: ${_questionAnswers.length} answers');
            print('📋 Answer details: $_questionAnswers');
          }
        });

        // Load job questions for the selected category
        if (_selectedCategoryId != null) {
          _loadJobQuestions(_selectedCategoryId!);
        }

        print('✅ Job request form populated with AI bot data');
      }
    }
  }

  // Handle returning data from helper selection
  void _handleReturningData() {
    // Check if returning from helper selection
    final context = this.context;
    if (context.mounted) {
      final routeData = ModalRoute.of(context)?.settings.arguments;
      if (routeData is Map<String, dynamic> &&
          routeData['selectedHelper'] != null) {
        setState(() {
          _selectedHelper = routeData['selectedHelper'];
          _helperSearchController.text =
              _selectedHelper!['full_name']?.toString() ?? '';
        });
      }
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

      // Get the selected category to access its default hourly rate
      final selectedCategory = _jobCategories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {},
      );

      // Get default hourly rate from the category
      double defaultRate = selectedCategory.isNotEmpty &&
              selectedCategory['default_hourly_rate'] != null
          ? double.parse(selectedCategory['default_hourly_rate'].toString())
          : 2500.0; // Fallback default rate

      setState(() {
        _jobQuestions = questions;
        _defaultHourlyRate = defaultRate;
        // Only clear answers if they're not from AI bot
        if (_questionAnswers.isEmpty || !_hasAIBotAnswers) {
          _questionAnswers.clear(); // Reset answers when category changes
          _hasAIBotAnswers = false; // Reset flag when clearing manually
        } else {
          print('🤖 Preserving AI bot answers during job questions load');
        }
      });

      // Update the UI to show the hourly rate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Default hourly rate for this category: LKR ${defaultRate.toStringAsFixed(2)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error loading job questions: $e');
    }
  }

  // Navigation method for helper search
  Future<void> _navigateToHelperSearch() async {
    final selectedHelper = await context.push<Map<String, dynamic>>(
      '/helpee/search-helper',
      extra: {
        'isSelectionMode': true,
        'selectedCategoryId': _selectedCategoryId,
        'returnRoute': '/helpee/job-request',
      },
    );

    if (selectedHelper != null) {
      setState(() {
        _selectedHelper = selectedHelper;
        _helperSearchController.text =
            selectedHelper['full_name']?.toString() ?? '';
      });
    }
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
            title: 'Request Helper',
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
                        initialAnswers: _questionAnswers, // Pass AI bot answers
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

                    const SizedBox(height: 12),

                    // Map Location Picker Button
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withOpacity(0.1),
                            AppColors.primaryGreen.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showLocationPicker,
                        icon: const Icon(
                          Icons.map,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        label: Text(
                          _selectedLatitude != null &&
                                  _selectedLongitude != null
                              ? 'Location Selected ✓'
                              : 'Pick Location on Map',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Location coordinates display (if selected)
                    if (_selectedLatitude != null &&
                        _selectedLongitude != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primaryGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Coordinates: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLatitude = null;
                                  _selectedLongitude = null;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: AppColors.primaryGreen,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                                  name: _selectedHelper!['full_name']
                                          ?.toString() ??
                                      'Helper',
                                  jobTypes:
                                      _selectedHelper!['job_type_names'] ?? [],
                                  profileImageUrl:
                                      _selectedHelper!['profile_image_url'],
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
                        // Helper Search Field with Search Button
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _helperSearchController,
                                decoration: InputDecoration(
                                  hintText: 'Search helper by name...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.lightGrey),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                ),
                                readOnly:
                                    true, // Make it read-only, search via button
                                validator: (value) {
                                  if (_jobPostingType == 'private' &&
                                      _selectedHelper == null) {
                                    return 'Please select a helper for private jobs';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _navigateToHelperSearch,
                              icon: const Icon(Icons.search),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
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
                                (_jobPostingType == 'private'
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

  Future<void> _showLocationPicker() async {
    try {
      // Show center popup instead of bottom sheet
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) => Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 340,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _buildLocationSelectionContent(),
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error selecting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting location: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildLocationSelectionContent() {
    final List<String> predefinedLocations = [
      'Colombo, Sri Lanka',
      'Kandy, Sri Lanka',
      'Galle, Sri Lanka',
      'Jaffna, Sri Lanka',
      'Anuradhapura, Sri Lanka',
      'Batticaloa, Sri Lanka',
      'Negombo, Sri Lanka',
      'Kurunegala, Sri Lanka',
    ];

    return Column(
      children: [
        // Header with close button
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Location'.tr(),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Custom address input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Custom Address'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Type your address here...'.tr(),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.lightGrey.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      if (_locationController.text.trim().isNotEmpty) {
                        Navigator.of(context).pop();
                        _showLocationSuccess();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                maxLines: 2,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.of(context).pop();
                    _showLocationSuccess();
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Predefined locations
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Popular Locations'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Location options
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              itemCount: predefinedLocations.length,
              itemBuilder: (context, index) {
                final location = predefinedLocations[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _locationController.text = location;
                        });
                        Navigator.of(context).pop();
                        _showLocationSuccess();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightGrey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                location,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  void _showLocationSuccess() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location selected successfully!'.tr()),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
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

      // Create new job
      final jobCategoryName = _jobCategories.firstWhere(
        (cat) => cat['id'] == _selectedCategoryId,
        orElse: () => {'name': 'Unknown'},
      )['name'];

      Map<String, dynamic>? jobData;

      if (_jobPostingType == 'private' && _selectedHelper != null) {
        // Use enhanced service for private jobs with helper assignment
        jobData = await SupabaseService().createPrivateJobWithHelperAssignment(
          helpeeId: _authService.currentUser?['user_id'] ?? '',
          categoryId: _selectedCategoryId!,
          jobCategoryName: jobCategoryName,
          title: _titleController.text.trim(),
          description: _notesController.text.trim(),
          hourlyRate: _defaultHourlyRate ?? 2500.0,
          scheduledDate: _selectedDate!.toIso8601String().split('T')[0],
          scheduledStartTime:
              '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          locationLatitude: _selectedLatitude ?? 6.9271,
          locationLongitude: _selectedLongitude ?? 79.8612,
          locationAddress: _locationController.text.trim(),
          questionAnswers: questionAnswers,
          selectedHelper: _selectedHelper!,
          specialInstructions: _notesController.text.trim(),
        );
      } else {
        // Use standard service for public jobs
        jobData = await SupabaseService().createJobWithQuestions(
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
          locationLatitude: _selectedLatitude ?? 6.9271,
          locationLongitude: _selectedLongitude ?? 79.8612,
          locationAddress: _locationController.text.trim(),
          questionAnswers: questionAnswers,
          invitedHelperEmail: null,
          specialInstructions: _notesController.text.trim(),
        );
      }

      if (jobData != null) {
        print('✅ Job created successfully with ID: ${jobData['id']}');

        // Show success popup
        _popupManager.showJobCreatedPopup(jobData);

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
    } catch (e) {
      print('❌ Error submitting job: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting job: ${e.toString()}'),
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
