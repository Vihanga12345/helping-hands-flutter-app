import 'package:flutter/material.dart';
import '../../services/admin_job_category_service.dart';
import '../../services/job_questions_service.dart';

class AdminJobQuestionsPage extends StatefulWidget {
  @override
  _AdminJobQuestionsPageState createState() => _AdminJobQuestionsPageState();
}

class _AdminJobQuestionsPageState extends State<AdminJobQuestionsPage> {
  final _adminJobCategoryService = AdminJobCategoryService();
  final _jobQuestionsService = JobQuestionsService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _categories = [];
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final categories = await _adminJobCategoryService.getAllCategories();
      final questions = await _jobQuestionsService.getAllQuestions();

      if (mounted) {
        setState(() {
          _categories = categories;
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Job Questions'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_questions[index].title),
                    );
                  },
                ),
    );
  }
}
