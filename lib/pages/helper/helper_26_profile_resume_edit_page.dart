import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper26ProfileResumeEditPage extends StatefulWidget {
  const Helper26ProfileResumeEditPage({super.key});

  @override
  State<Helper26ProfileResumeEditPage> createState() =>
      _Helper26ProfileResumeEditPageState();
}

class _Helper26ProfileResumeEditPageState
    extends State<Helper26ProfileResumeEditPage> {
  // Sample attachments data - will be replaced with real data from database
  List<Map<String, String>> _attachments = [
    {
      'name': 'Cleaning Certificate.pdf',
      'type': 'document',
      'size': '2.1 MB',
      'date': '2024-01-15',
      'id': '1'
    },
    {
      'name': 'Work Sample 1.jpg',
      'type': 'image',
      'size': '1.8 MB',
      'date': '2024-02-20',
      'id': '2'
    },
    {
      'name': 'First Aid Certificate.pdf',
      'type': 'document',
      'size': '1.2 MB',
      'date': '2024-03-10',
      'id': '3'
    },
    {
      'name': 'Work Sample 2.jpg',
      'type': 'image',
      'size': '2.3 MB',
      'date': '2024-03-15',
      'id': '4'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              // Header
              AppHeader(
                title: 'Edit Resume',
                showBackButton: true,
                showMenuButton: true,
                showNotificationButton: true,
                onMenuPressed: () {
                  context.push('/helper/menu');
                },
                onNotificationPressed: () {
                  context.push('/helper/notifications');
                },
                rightWidget: TextButton(
                  onPressed: _saveChanges,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add Files Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add Resume Files',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload certificates, work samples, and other documents',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _addDocument,
                                    icon:
                                        const Icon(Icons.description, size: 20),
                                    label: const Text('Add Document'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _addImage,
                                    icon: const Icon(Icons.image, size: 20),
                                    label: const Text('Add Image'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Current Files Section
                      if (_attachments.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Files',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_attachments.length} files',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Files Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            final attachment = _attachments[index];
                            final isImage = attachment['type'] == 'image';

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowColorLight,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      // File Preview
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isImage
                                                ? AppColors.lightGrey
                                                : AppColors.primaryGreen
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: isImage
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.asset(
                                                      'assets/images/work_sample.jpg',
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                        Icons.image,
                                                        size: 40,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.description,
                                                    size: 40,
                                                    color:
                                                        AppColors.primaryGreen,
                                                  ),
                                          ),
                                        ),
                                      ),

                                      // File Info
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              attachment['name']!,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  isImage
                                                      ? Icons.image
                                                      : Icons.description,
                                                  size: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    attachment['size']!,
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              attachment['date']!,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Delete button
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _removeAttachment(index),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: AppColors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        // Empty state
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
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
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Files Added Yet',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload your certificates, work samples,\nand other resume documents',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // File Guidelines
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'File Guidelines',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildGuideline(
                                '• Supported formats: PDF, JPG, PNG'),
                            _buildGuideline(
                                '• Maximum file size: 5 MB per file'),
                            _buildGuideline(
                                '• Upload relevant certificates and work samples'),
                            _buildGuideline(
                                '• Clear, high-quality images work best'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.profile,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _addDocument() {
    // Simulate adding a document
    setState(() {
      _attachments.add({
        'name': 'New Certificate.pdf',
        'type': 'document',
        'size': '1.5 MB',
        'date': '2024-12-01',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document would be uploaded here'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _addImage() {
    // Simulate adding an image
    setState(() {
      _attachments.add({
        'name': 'New Work Sample.jpg',
        'type': 'image',
        'size': '2.0 MB',
        'date': '2024-12-01',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image would be uploaded here'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _removeAttachment(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove File'),
        content: Text(
            'Are you sure you want to remove "${_attachments[index]['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _attachments.removeAt(index);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File removed successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    // Here you would typically save to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resume files updated successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }
}
