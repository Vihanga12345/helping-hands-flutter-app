import 'package:flutter/material.dart';
import '../../widgets/admin/admin_header.dart';
import '../../services/admin_job_category_service.dart';
import '../../utils/app_colors.dart';

class AdminJobCategoryDetailsPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const AdminJobCategoryDetailsPage({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<AdminJobCategoryDetailsPage> createState() =>
      _AdminJobCategoryDetailsPageState();
}

class _AdminJobCategoryDetailsPageState
    extends State<AdminJobCategoryDetailsPage>
    with SingleTickerProviderStateMixin {
  final AdminJobCategoryService _categoryService = AdminJobCategoryService();

  late TabController _tabController;
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic>? categoryData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final categoryInfo =
          await _categoryService.getCategoryById(widget.categoryId);
      final categoryQuestions =
          await _categoryService.getCategoryQuestions(widget.categoryId);

      setState(() {
        categoryData = categoryInfo;
        questions = categoryQuestions;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading category data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          AdminHeader(
            title: widget.categoryName,
            showBackButton: true,
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primaryBlue,
              tabs: const [
                Tab(
                  icon: Icon(Icons.help_outline),
                  text: 'Questions',
                ),
                Tab(
                  icon: Icon(Icons.attach_money),
                  text: 'Hourly Rate',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionsTab(),
                _buildHourlyRateTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Job-Specific Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddQuestionDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildQuestionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add questions that helpers should answer when applying for ${widget.categoryName} jobs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddQuestionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add First Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(question, index + 1);
      },
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int questionNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (question['is_required'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleQuestionAction(action, question),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question['question'] ??
                  question['question_text'] ??
                  'No question text',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (question['placeholder_text'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Placeholder: ${question['placeholder_text']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyRateTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentRate =
        (categoryData?['default_hourly_rate'] ?? 2000.0).toDouble();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Hourly Rate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Rate',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'LKR ${currentRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const Text(
                        ' per hour',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'This is the default rate shown to helpers when they apply for ${widget.categoryName} jobs. Helpers can set their own rates, but this gives them a guideline.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showEditRateDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Rate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuestionAction(String action, Map<String, dynamic> question) {
    switch (action) {
      case 'edit':
        _showEditQuestionDialog(question);
        break;
      case 'delete':
        _showDeleteQuestionDialog(question);
        break;
    }
  }

  void _showAddQuestionDialog() {
    _showQuestionDialog();
  }

  void _showEditQuestionDialog(Map<String, dynamic> question) {
    _showQuestionDialog(question: question);
  }

  void _showQuestionDialog({Map<String, dynamic>? question}) {
    final isEdit = question != null;
    final questionController = TextEditingController(
        text: question?['question'] ?? question?['question_text'] ?? '');
    final placeholderController =
        TextEditingController(text: question?['placeholder_text'] ?? '');
    bool isRequired = question?['is_required'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Question' : 'Add New Question'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    border: OutlineInputBorder(),
                    hintText: 'Enter the question helpers should answer...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: placeholderController,
                  decoration: const InputDecoration(
                    labelText: 'Placeholder Text (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Hint text to show in the answer field...',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isRequired,
                      onChanged: (value) {
                        setDialogState(() {
                          isRequired = value ?? true;
                        });
                      },
                    ),
                    const Text('Required question'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveQuestionDialog(
                context,
                isEdit,
                question?['id'],
                questionController.text,
                placeholderController.text,
                isRequired,
              ),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestionDialog(
    BuildContext context,
    bool isEdit,
    String? questionId,
    String questionText,
    String placeholderText,
    bool isRequired,
  ) async {
    if (questionText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    bool success;
    if (isEdit && questionId != null) {
      success = await _categoryService.updateQuestion(
        questionId: questionId,
        question: questionText.trim(),
        isRequired: isRequired,
        placeholderText:
            placeholderText.trim().isEmpty ? null : placeholderText.trim(),
      );
    } else {
      success = await _categoryService.addQuestionToCategory(
        categoryId: widget.categoryId,
        question: questionText.trim(),
        isRequired: isRequired,
        placeholderText:
            placeholderText.trim().isEmpty ? null : placeholderText.trim(),
      );
    }

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Question updated successfully'
              : 'Question added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategoryData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isEdit ? 'Failed to update question' : 'Failed to add question'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteQuestionDialog(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
          'Are you sure you want to delete this question?\n\n"${question['question'] ?? question['question_text']}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteQuestion(context, question),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(
      BuildContext context, Map<String, dynamic> question) async {
    final success = await _categoryService.deleteQuestion(question['id']);

    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategoryData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete question'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditRateDialog() {
    final currentRate =
        (categoryData?['default_hourly_rate'] ?? 2000.0).toDouble();
    final rateController =
        TextEditingController(text: currentRate.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Hourly Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rateController,
              decoration: const InputDecoration(
                labelText: 'Hourly Rate (LKR)',
                border: OutlineInputBorder(),
                prefixText: 'LKR ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              'This will be the default suggested rate for ${widget.categoryName} jobs.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveRateDialog(context, rateController.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRateDialog(BuildContext context, String rateText) async {
    final rate = double.tryParse(rateText);

    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid hourly rate')),
      );
      return;
    }

    final success = await _categoryService.updateCategory(
      categoryId: widget.categoryId,
      name: categoryData?['name'] ?? widget.categoryName,
      description: categoryData?['description'] ?? '',
      hourlyRate: rate,
    );

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hourly rate updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategoryData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update hourly rate'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
