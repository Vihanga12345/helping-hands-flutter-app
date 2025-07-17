import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import '../../widgets/admin/admin_header.dart';
import '../../services/admin_job_category_service.dart';
import '../../utils/app_colors.dart';
import 'admin_job_category_details_page.dart';

class AdminManageJobsPage extends StatefulWidget {
  const AdminManageJobsPage({Key? key}) : super(key: key);

  @override
  State<AdminManageJobsPage> createState() => _AdminManageJobsPageState();
}

class _AdminManageJobsPageState extends State<AdminManageJobsPage> {
  final AdminJobCategoryService _categoryService = AdminJobCategoryService();

  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      final categoriesData = await _categoryService.getAllCategories();
      setState(() {
        categories = categoriesData;
        isLoading = false;
      });
      print('✅ Categories loaded successfully: ${categories.length}');
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredCategories {
    if (searchQuery.isEmpty) {
      return categories;
    }
    return categories.where((category) {
      final name = (category['name'] ?? '').toString().toLowerCase();
      final description =
          (category['description'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const AdminHeader(
            title: 'Manage Job Categories',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildCategoriesGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[500], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search categories...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showCreateCategoryDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Category'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No job categories found'
                  : 'No categories match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty
                  ? 'Create your first job category to get started'
                  : 'Try adjusting your search terms',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            if (searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreateCategoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create First Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final questionCount = category['question_count'] ?? 0;
    final hourlyRate = (category['default_hourly_rate'] ?? 0.0).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCategoryDetails(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category['icon_name']),
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleCategoryAction(action, category),
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
                    child: Icon(Icons.more_vert, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                category['name'] ?? 'Unnamed Category',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                category['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.help_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '$questionCount questions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'LKR ${hourlyRate.toStringAsFixed(0)}/hr',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'garden':
        return Icons.local_florist;
      case 'pets':
        return Icons.pets;
      case 'cooking':
        return Icons.restaurant;
      case 'elderly':
        return Icons.elderly;
      case 'child':
        return Icons.child_care;
      case 'tech':
        return Icons.computer;
      case 'tutoring':
        return Icons.school;
      case 'fitness':
        return Icons.fitness_center;
      case 'photography':
        return Icons.camera_alt;
      default:
        return Icons.work;
    }
  }

  void _navigateToCategoryDetails(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminJobCategoryDetailsPage(
          categoryId: category['id'],
          categoryName: category['name'] ?? 'Category',
        ),
      ),
    ).then((_) => _loadCategories()); // Refresh when returning
  }

  void _handleCategoryAction(String action, Map<String, dynamic> category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(category);
        break;
    }
  }

  void _showCreateCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descriptionController =
        TextEditingController(text: category?['description'] ?? '');
    final hourlyRateController = TextEditingController(
        text: category != null
            ? (category['default_hourly_rate'] ?? 0.0).toString()
            : '2000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Create New Category'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Default Hourly Rate (LKR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () => _saveCategoryDialog(
              context,
              isEdit,
              category?['id'],
              nameController.text,
              descriptionController.text,
              hourlyRateController.text,
            ),
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategoryDialog(
    BuildContext context,
    bool isEdit,
    String? categoryId,
    String name,
    String description,
    String hourlyRateText,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    final hourlyRate = double.tryParse(hourlyRateText) ?? 2000.0;

    bool success;
    if (isEdit && categoryId != null) {
      success = await _categoryService.updateCategory(
        categoryId: categoryId,
        name: name.trim(),
        description: description.trim(),
        hourlyRate: hourlyRate,
      );
    } else {
      success = await _categoryService.createCategory(
        name: name.trim(),
        description: description.trim(),
        hourlyRate: hourlyRate,
      );
    }

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Category updated successfully'
              : 'Category created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Failed to update category'
              : 'Failed to create category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category['name']}"? '
          'This will also delete all questions associated with this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCategory(context, category),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(
      BuildContext context, Map<String, dynamic> category) async {
    final success = await _categoryService.deleteCategory(category['id']);

    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
