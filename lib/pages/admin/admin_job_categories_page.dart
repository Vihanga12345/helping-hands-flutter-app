import 'package:flutter/material.dart';
import 'package:helping_hands_app/services/admin_job_category_service.dart';
import 'package:helping_hands_app/services/notification_popup_service.dart';

class AdminJobCategoriesPage extends StatefulWidget {
  @override
  _AdminJobCategoriesPageState createState() => _AdminJobCategoriesPageState();
}

class _AdminJobCategoriesPageState extends State<AdminJobCategoriesPage> {
  final _adminJobCategoryService = AdminJobCategoryService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feeController = TextEditingController();

  Future<void> _createCategory() async {
    if (_nameController.text.trim().isEmpty) {
      NotificationPopupService.showError(
        context,
        'Please enter a category name',
      );
      return;
    }

    try {
      final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;

      await _adminJobCategoryService.createCategory(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        hourlyRate: fee,
      );

      _nameController.clear();
      _descriptionController.clear();
      _feeController.clear();

      NotificationPopupService.showSuccess(
        context,
        'Job category created successfully',
      );

      await _loadCategories();
    } catch (e) {
      NotificationPopupService.showError(
        context,
        'Failed to create category: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build your widget tree here
  }
}
