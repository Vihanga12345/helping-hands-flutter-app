import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class Helper5RegistrationPage3 extends StatefulWidget {
  const Helper5RegistrationPage3({super.key});

  @override
  State<Helper5RegistrationPage3> createState() =>
      _Helper5RegistrationPage3State();
}

class _Helper5RegistrationPage3State extends State<Helper5RegistrationPage3> {
  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'National Identity Card',
      'description': 'Clear photo of both sides of your NIC',
      'required': true,
      'uploaded': false,
      'icon': Icons.credit_card,
    },
    {
      'title': 'Police Clearance Certificate',
      'description': 'Valid police clearance (not older than 6 months)',
      'required': true,
      'uploaded': false,
      'icon': Icons.security,
    },
    {
      'title': 'Professional Certificates',
      'description': 'Relevant training or certification documents',
      'required': false,
      'uploaded': false,
      'icon': Icons.school,
    },
    {
      'title': 'Bank Account Details',
      'description': 'Bank statement or account verification',
      'required': true,
      'uploaded': false,
      'icon': Icons.account_balance,
    },
    {
      'title': 'Profile Photo',
      'description': 'Professional headshot for your profile',
      'required': true,
      'uploaded': false,
      'icon': Icons.person,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final requiredDocuments = _documents.where((doc) => doc['required']).length;
    final uploadedRequired =
        _documents.where((doc) => doc['required'] && doc['uploaded']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Upload'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
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
              // Progress Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step 3 of 4',
                                style: TextStyle().copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Upload Documents',
                                style: TextStyle(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.75,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen),
                    ),
                  ],
                ),
              ),

              // Progress Summary
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.upload_file,
                        color: AppColors.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Documents uploaded: $uploadedRequired/$requiredDocuments required',
                        style: TextStyle().copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Documents List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final document = _documents[index];
                    return _buildDocumentCard(document, index);
                  },
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColorLight,
                      blurRadius: 8,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: uploadedRequired == requiredDocuments
                            ? () => context.go('/helper-register-4')
                            : null,
                        child: Text(
                          uploadedRequired == requiredDocuments
                              ? 'Continue to Verification'
                              : 'Upload Required Documents',
                          style: TextStyle(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Registration progress saved')),
                        );
                      },
                      child: const Text('Save and Continue Later'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: document['uploaded']
            ? Border.all(color: AppColors.success, width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: document['uploaded']
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    document['uploaded']
                        ? Icons.check_circle
                        : document['icon'],
                    color: document['uploaded']
                        ? AppColors.success
                        : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            document['title'],
                            style: TextStyle().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (document['required'])
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle().copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document['description'],
                        style: TextStyle().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (document['uploaded'])
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Document uploaded successfully',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _replaceDocument(index),
                      child: const Text('Replace'),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _uploadDocument(index),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _uploadDocument(index),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload File'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _uploadDocument(int index) {
    setState(() {
      _documents[index]['uploaded'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_documents[index]['title']} uploaded successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _replaceDocument(int index) {
    setState(() {
      _documents[index]['uploaded'] = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${_documents[index]['title']} removed. Please upload again.'),
      ),
    );
  }
}
