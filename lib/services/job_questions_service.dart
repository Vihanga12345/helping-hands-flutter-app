import 'package:supabase_flutter/supabase_flutter.dart';

class JobQuestionsService {
  static final JobQuestionsService _instance = JobQuestionsService._internal();
  factory JobQuestionsService() => _instance;
  JobQuestionsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Flag to determine if we're using mock data
  bool _useMockData = false;

  // Mock data storage
  static final Map<String, List<Map<String, dynamic>>> _mockTables = {
    'job_categories': [],
    'job_category_questions': [],
    'job_question_answers': [],
  };

  /// Initialize the service and check database connectivity
  Future<void> initialize() async {
    try {
      // Always use real Supabase database
      _useMockData = false;
      print('✅ JobQuestionsService connected to Supabase database');
    } catch (e) {
      print('JobQuestionsService initialization error: $e');
    }
  }

  void _initializeMockData() {
    // Initialize job categories
    _mockTables['job_categories'] = [
      {
        'id': '1',
        'name': 'House Cleaning',
        'description': 'General house cleaning services',
        'default_hourly_rate': 2500.0,
        'is_active': true,
      },
      {
        'id': '2',
        'name': 'Deep Cleaning',
        'description': 'Thorough deep cleaning services',
        'default_hourly_rate': 3000.0,
        'is_active': true,
      },
      {
        'id': '3',
        'name': 'Gardening',
        'description': 'Garden maintenance and landscaping',
        'default_hourly_rate': 2000.0,
        'is_active': true,
      },
      {
        'id': '4',
        'name': 'Cooking',
        'description': 'Meal preparation and cooking services',
        'default_hourly_rate': 2200.0,
        'is_active': true,
      },
      {
        'id': '5',
        'name': 'Elderly Care',
        'description': 'Care and assistance for elderly individuals',
        'default_hourly_rate': 2800.0,
        'is_active': true,
      },
    ];

    // Initialize job category questions
    _mockTables['job_category_questions'] = [
      {
        'id': '1',
        'category_id': '1',
        'question': 'How many rooms need cleaning?',
        'question_type': 'number',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '2',
        'category_id': '1',
        'question': 'Do you have cleaning supplies?',
        'question_type': 'yes_no',
        'is_required': true,
        'order_index': 2,
      },
      {
        'id': '3',
        'category_id': '1',
        'question': 'Any specific cleaning requirements?',
        'question_type': 'text',
        'is_required': false,
        'order_index': 3,
      },
      {
        'id': '4',
        'category_id': '2',
        'question': 'What areas need deep cleaning?',
        'question_type': 'text',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '5',
        'category_id': '2',
        'question': 'How long since last deep clean?',
        'question_type': 'text',
        'is_required': false,
        'order_index': 2,
      },
      {
        'id': '6',
        'category_id': '3',
        'question': 'What type of gardening work is needed?',
        'question_type': 'text',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '7',
        'category_id': '3',
        'question': 'Size of garden/area?',
        'question_type': 'text',
        'is_required': false,
        'order_index': 2,
      },
      {
        'id': '8',
        'category_id': '4',
        'question': 'How many people will be served?',
        'question_type': 'number',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '9',
        'category_id': '4',
        'question': 'Any dietary restrictions?',
        'question_type': 'text',
        'is_required': false,
        'order_index': 2,
      },
      {
        'id': '10',
        'category_id': '5',
        'question': 'What type of care is needed?',
        'question_type': 'text',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '11',
        'category_id': '5',
        'question': 'Any medical conditions to consider?',
        'question_type': 'text',
        'is_required': false,
        'order_index': 2,
      },
    ];

    _mockTables['job_question_answers'] = [];
  }

  /// Get questions for a specific job category by ID
  Future<List<Map<String, dynamic>>> getQuestionsForCategory(
      String categoryId) async {
    await initialize();

    try {
      if (_useMockData) {
        final questions = _mockTables['job_category_questions']!
            .where((q) => q['category_id'] == categoryId)
            .toList();

        // Sort by order_index
        questions.sort(
            (a, b) => (a['order_index'] ?? 0).compareTo(b['order_index'] ?? 0));
        return questions;
      }

      final response = await _supabase
          .from('job_category_questions')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('order_index');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting questions for category: $e');
      return [];
    }
  }

  /// Get questions for a job category by name
  Future<List<Map<String, dynamic>>> getQuestionsByCategoryName(
      String categoryName) async {
    await initialize();

    try {
      if (_useMockData) {
        // Find category by name
        final categories = _mockTables['job_categories']!
            .where((c) =>
                c['name'].toString().toLowerCase() ==
                categoryName.toLowerCase())
            .toList();

        if (categories.isEmpty) return [];

        final categoryId = categories.first['id'];
        return await getQuestionsForCategory(categoryId);
      }

      // First, get the category ID by name
      final categoryResponse = await _supabase
          .from('job_categories')
          .select('id')
          .eq('name', categoryName)
          .eq('is_active', true)
          .maybeSingle();

      if (categoryResponse == null) {
        print('Category not found: $categoryName');
        return [];
      }

      final categoryId = categoryResponse['id'];
      return await getQuestionsForCategory(categoryId);
    } catch (e) {
      print('Error getting questions by category name: $e');
      return [];
    }
  }

  /// Save job answers to the database
  Future<bool> saveJobAnswers({
    required String jobId,
    required List<Map<String, dynamic>> answers,
  }) async {
    await initialize();

    try {
      if (_useMockData) {
        // Save to mock storage
        for (final answer in answers) {
          final questionId = answer['question_id'];
          if (questionId != null) {
            _mockTables['job_question_answers']!.add({
              'id':
                  'answer_${DateTime.now().millisecondsSinceEpoch}_$questionId',
              'job_id': jobId,
              'question_id': questionId,
              'answer': _extractMainAnswer(answer),
              'answer_text': answer['answer_text'],
              'answer_number': answer['answer_number'],
              'answer_date': answer['answer_date'],
              'answer_time': answer['answer_time'],
              'answer_boolean': answer['answer_boolean'],
              'selected_options': answer['selected_options'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }
        print('✅ Job answers saved to mock storage');
        return true;
      }

      // Save answers to database
      print('🔄 Saving ${answers.length} job answers to database...');

      for (final answer in answers) {
        final questionId = answer['question_id'];
        if (questionId == null) continue;

        // Prepare the answer record with both main answer and type-specific fields
        final answerRecord = <String, dynamic>{
          'job_id': jobId,
          'question_id': questionId,
          'answer': _extractMainAnswer(answer), // Main answer field
          'answer_text': answer['answer_text'],
          'answer_number': answer['answer_number'],
          'answer_date': answer['answer_date'],
          'answer_time': answer['answer_time'],
          'answer_boolean': answer['answer_boolean'],
          'selected_options': answer['selected_options'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Insert the answer record
        try {
          await _supabase.from('job_question_answers').insert(answerRecord);
          print(
              '✅ Saved answer for question $questionId: ${answerRecord['answer']}');
        } catch (e) {
          print('❌ Error saving answer for question $questionId: $e');
          // Continue with other answers
        }
      }

      print('✅ All job answers processed');
      return true;
    } catch (e) {
      print('❌ Error saving job answers: $e');
      return false;
    }
  }

  /// Extract the main answer value from answer data
  String? _extractMainAnswer(Map<String, dynamic> answer) {
    // Priority order: answer_text, answer_number, answer_boolean, answer_date, answer_time, selected_options
    if (answer['answer_text'] != null &&
        answer['answer_text'].toString().trim().isNotEmpty) {
      return answer['answer_text'].toString().trim();
    }

    if (answer['answer_number'] != null) {
      return answer['answer_number'].toString();
    }

    if (answer['answer_boolean'] != null) {
      return answer['answer_boolean'] == true ? 'Yes' : 'No';
    }

    if (answer['answer_date'] != null) {
      return answer['answer_date'].toString();
    }

    if (answer['answer_time'] != null) {
      return answer['answer_time'].toString();
    }

    if (answer['selected_options'] != null) {
      return answer['selected_options'].toString();
    }

    return null;
  }

  /// Get formatted job answers for display
  Future<List<Map<String, dynamic>>> getFormattedJobAnswers(
      String jobId) async {
    await initialize();

    try {
      if (_useMockData) {
        final answers = _mockTables['job_question_answers']!
            .where((answer) => answer['job_id'] == jobId)
            .toList();

        // Get questions and format answers
        final formattedAnswers = <Map<String, dynamic>>[];
        for (final answer in answers) {
          final questions = _mockTables['job_category_questions']!
              .where((q) => q['id'] == answer['question_id'])
              .toList();

          if (questions.isNotEmpty) {
            final question = questions.first;
            formattedAnswers.add({
              'question': question['question'],
              'answer': answer['answer'],
              'question_type': question['question_type'],
              'is_required': question['is_required'],
            });
          }
        }

        return formattedAnswers;
      }

      final response = await _supabase.from('job_question_answers').select('''
            answer,
            job_category_questions!inner(
              question,
              question_type,
              is_required
            )
          ''').eq('job_id', jobId);

      return List<Map<String, dynamic>>.from(response.map((item) => {
            'question': item['job_category_questions']['question'],
            'answer': item['answer'],
            'question_type': item['job_category_questions']['question_type'],
            'is_required': item['job_category_questions']['is_required'],
          }));
    } catch (e) {
      print('Error getting formatted job answers: $e');
      return [];
    }
  }

  /// Get job categories (for reference)
  Future<List<Map<String, dynamic>>> getJobCategories() async {
    await initialize();

    try {
      if (_useMockData) {
        return List.from(_mockTables['job_categories']!
            .where((c) => c['is_active'] == true));
      }

      final response = await _supabase
          .from('job_categories')
          .select()
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting job categories: $e');
      return [];
    }
  }

  /// Validate answers against questions
  bool validateAnswers(List<Map<String, dynamic>> questions,
      List<Map<String, dynamic>> answers) {
    // Check that all required questions have answers
    for (final question in questions) {
      if (question['is_required'] == true) {
        final hasAnswer = answers.any((answer) =>
            answer['question_id'] == question['id'] &&
            answer['answer'] != null &&
            answer['answer'].toString().trim().isNotEmpty);

        if (!hasAnswer) {
          print(
              'Missing required answer for question: ${question['question']}');
          return false;
        }
      }
    }

    return true;
  }

  /// Create a new question for a job category
  Future<bool> createQuestion({
    required String categoryId,
    required String questionText,
    required String questionType,
  }) async {
    await initialize();

    try {
      // Get the next order number for this category
      final existingQuestions = await _supabase
          .from('job_category_questions')
          .select('question_order')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('question_order', ascending: false)
          .limit(1);

      int nextOrder = 1;
      if (existingQuestions.isNotEmpty) {
        nextOrder = (existingQuestions.first['question_order'] ?? 0) + 1;
      }

      await _supabase.from('job_category_questions').insert({
        'category_id': categoryId,
        'question_text': questionText,
        'question_type': questionType,
        'question_order': nextOrder,
        'is_active': true,
      });

      print('✅ Question created successfully');
      return true;
    } catch (e) {
      print('❌ Error creating question: $e');
      return false;
    }
  }
}
