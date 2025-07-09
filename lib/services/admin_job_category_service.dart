import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class AdminJobCategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all job categories for admin management
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    print('🔍 Fetching all categories...');

    try {
      final response = await _supabase.from('job_categories').select('''
            id, name, description, default_hourly_rate, icon_name, is_active, 
            created_at, updated_at
          ''').eq('is_active', true).order('name');

      print('✅ Categories fetched from direct query: ${response.length}');

      // Add question count manually for each category
      List<Map<String, dynamic>> categories =
          List<Map<String, dynamic>>.from(response);

      for (var category in categories) {
        final questionCount = await _getQuestionCount(category['id']);
        category['question_count'] = questionCount;
      }

      print('✅ Categories loaded successfully: ${categories.length}');
      return categories;
    } catch (e) {
      print('❌ Error getting categories: $e');
      return [];
    }
  }

  /// Get question count for a category
  Future<int> _getQuestionCount(String categoryId) async {
    try {
      final response = await _supabase
          .from('job_category_questions')
          .select('id')
          .eq('category_id', categoryId)
          .eq('is_active', true);
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      final response = await _supabase.from('job_categories').select('''
            id, name, description, default_hourly_rate, icon_name, is_active, 
            created_at, updated_at
          ''').eq('id', categoryId).eq('is_active', true).single();

      print('✅ Category fetched by ID: ${response['name']}');
      return response;
    } catch (e) {
      print('❌ Error getting category by ID: $e');
      return null;
    }
  }

  /// Get questions for a specific category
  Future<List<Map<String, dynamic>>> getCategoryQuestions(
      String categoryId) async {
    try {
      final response = await _supabase
          .from('job_category_questions')
          .select('''
            id, question, question_order, is_required, placeholder_text, 
            created_at, updated_at
          ''')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('question_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting category questions: $e');
      return [];
    }
  }

  /// Create a new job category
  Future<bool> createCategory({
    required String name,
    required String description,
    required double hourlyRate,
    String? iconName,
  }) async {
    try {
      await _supabase.from('job_categories').insert({
        'name': name,
        'description': description,
        'default_hourly_rate': hourlyRate,
        'icon_name': iconName,
        'is_active': true,
      });

      print('✅ Category created successfully: $name');
      return true;
    } catch (e) {
      print('❌ Error creating category: $e');
      return false;
    }
  }

  /// Update an existing job category
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    required double hourlyRate,
    String? iconName,
  }) async {
    try {
      await _supabase.from('job_categories').update({
        'name': name,
        'description': description,
        'default_hourly_rate': hourlyRate,
        'icon_name': iconName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', categoryId);

      print('✅ Category updated successfully: $name');
      return true;
    } catch (e) {
      print('❌ Error updating category: $e');
      return false;
    }
  }

  /// Add a question to a category
  Future<bool> addQuestionToCategory({
    required String categoryId,
    required String question,
    bool isRequired = true,
    String? placeholderText,
  }) async {
    try {
      // Get next order number
      final existingQuestions = await _supabase
          .from('job_category_questions')
          .select('question_order')
          .eq('category_id', categoryId)
          .order('question_order', ascending: false)
          .limit(1);

      int nextOrder = 1;
      if (existingQuestions.isNotEmpty) {
        nextOrder = (existingQuestions.first['question_order'] ?? 0) + 1;
      }

      await _supabase.from('job_category_questions').insert({
        'category_id': categoryId,
        'question': question,
        'question_text':
            question, // Populate both fields to avoid NOT NULL constraint
        'question_type': 'text',
        'question_order': nextOrder,
        'order_index': nextOrder,
        'is_required': isRequired,
        'placeholder_text': placeholderText,
        'is_active': true,
      });

      print('✅ Question added successfully to category');
      return true;
    } catch (e) {
      print('❌ Error adding question: $e');
      return false;
    }
  }

  /// Update a question
  Future<bool> updateQuestion({
    required String questionId,
    required String question,
    bool isRequired = true,
    String? placeholderText,
  }) async {
    try {
      await _supabase.from('job_category_questions').update({
        'question': question,
        'question_text':
            question, // Populate both fields to avoid NOT NULL constraint
        'is_required': isRequired,
        'placeholder_text': placeholderText,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', questionId);

      print('✅ Question updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating question: $e');
      return false;
    }
  }

  /// Delete a question (soft delete)
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _supabase.from('job_category_questions').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', questionId);

      print('✅ Question deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting question: $e');
      return false;
    }
  }

  /// Delete a category (soft delete)
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('job_categories').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', categoryId);

      print('✅ Category deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting category: $e');
      return false;
    }
  }

  /// Get category statistics
  Future<Map<String, dynamic>> getCategoryStats() async {
    try {
      final categories = await _supabase
          .from('job_categories')
          .select('id')
          .eq('is_active', true);

      final questions = await _supabase
          .from('job_category_questions')
          .select('id')
          .eq('is_active', true);

      return {
        'total_categories': categories.length,
        'total_questions': questions.length,
        'avg_questions_per_category': categories.isEmpty
            ? 0
            : (questions.length / categories.length).toStringAsFixed(1),
      };
    } catch (e) {
      print('❌ Error getting category stats: $e');
      return {
        'total_categories': 0,
        'total_questions': 0,
        'avg_questions_per_category': '0.0',
      };
    }
  }
}
