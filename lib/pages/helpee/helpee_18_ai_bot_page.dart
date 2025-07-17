import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/localization_service.dart';

class Helpee18AIBotPage extends StatefulWidget {
  const Helpee18AIBotPage({super.key});

  @override
  State<Helpee18AIBotPage> createState() => _Helpee18AIBotPageState();
}

class _Helpee18AIBotPageState extends State<Helpee18AIBotPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _conversationId;
  Map<String, dynamic>? _extractedJobData;
  int _completionPercentage = 0;

  // Gemini configuration - Using your actual Supabase URL
  final String _geminiChatUrl =
      'https://awdhnscowyibbbvoysfa.supabase.co/functions/v1/gemini-chat';

  @override
  void initState() {
    super.initState();
    // Clear any previous data and start fresh
    _clearChatAndJobData();
    _initializeGeminiChat();
  }

  @override
  void dispose() {
    // Clear chat and job data when exiting
    _clearChatAndJobData();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Clear all chat messages and job data - called when user exits
  void _clearChatAndJobData() {
    _messages.clear();
    _extractedJobData = null;
    _conversationId = null;
    _completionPercentage = 0;
    _isLoading = false;
    print('🧹 Chat and job data cleared - user exited screen');
  }

  Future<void> _initializeGeminiChat() async {
    try {
      print('🤖 Initializing Gemini Chat...');

      // Generate unique conversation ID
      _conversationId =
          'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

      // Add welcome message
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            message:
                "Hello! I'm your AI assistant for Helping Hands. I can help you create job requests through natural conversation. Just tell me what kind of help you need!"
                    .tr(),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isInitialized = true;
        });
      }

      print('✅ Gemini Chat initialized successfully');
    } catch (e) {
      print('❌ Error initializing Gemini Chat: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            message:
                "Sorry, I'm having trouble connecting to the AI service. Please try again later."
                    .tr(),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'AI Bot Assist'.tr(),
            showBackButton: true,
            showMenuButton: true,
            showNotificationButton: true,
            onBackPressed: () =>
                context.go('/helpee/home'), // Navigate to home page
          ),

          // Chat Body
          Expanded(
            child: Container(
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
                top: false,
                child: Column(
                  children: [
                    // Chat Messages
                    Expanded(
                      child: _buildChatList(),
                    ),
                    
                    // Message Input
                    _buildMessageInput(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
                                  BoxShadow(
            color: AppColors.shadowColor,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Job Request Progress'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$_completionPercentage%',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _completionPercentage / 100,
            backgroundColor: AppColors.lightGrey,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_messages.isEmpty && !_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'Connecting to AI assistant...'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primaryGreen
                    : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                        color: AppColors.shadowColor,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                      color: message.isUser
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                      color: message.isUser
                              ? AppColors.white.withOpacity(0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
                ),
                // Add buttons if this is an AI message with buttons
                if (!message.isUser && message.buttons != null)
                  _buildMessageButtons(message.buttons!),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageButtons(List<ChatButton> buttons) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: buttons
            .map((button) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => _handleButtonPress(button),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: button.action == 'navigate_to_form'
                          ? AppColors.primaryGreen
                          : AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          button.action == 'navigate_to_form'
                              ? Icons.work_outline
                              : Icons.report_problem,
                          color: AppColors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          button.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildJobPreview() {
    if (_extractedJobData == null || _extractedJobData!.isEmpty)
      return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.preview,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Job Request Preview'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_extractedJobData!['jobCategoryName'] != null)
            _buildPreviewRow('Service', _extractedJobData!['jobCategoryName']),
          if (_extractedJobData!['title'] != null)
            _buildPreviewRow('Title', _extractedJobData!['title']),
          if (_extractedJobData!['preferredDate'] != null ||
              _extractedJobData!['preferredTime'] != null)
            _buildPreviewRow('Date & Time',
                '${_extractedJobData!['preferredDate'] ?? 'Not set'} ${_extractedJobData!['preferredTime'] ?? ''}'),
          if (_extractedJobData!['location'] != null)
            _buildPreviewRow('Location', _extractedJobData!['location']),
          if (_extractedJobData!['hourlyRate'] != null)
            _buildPreviewRow(
                'Rate', 'LKR ${_extractedJobData!['hourlyRate']}/hour'),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                enabled: _isInitialized && !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Type your message...'.tr(),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isInitialized && !_isLoading ? _sendMessage : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: AppColors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading || _conversationId == null) return;

    // Add user message
    if (mounted) {
    setState(() {
        _messages.add(ChatMessage(
          message: messageText,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = true;
      });
    }

    _messageController.clear();
    _scrollToBottom();

    try {
      // Send message to Gemini
      final response = await _sendToGemini(messageText);

      // Handle response
      if (mounted) {
        setState(() {
          // Add AI response message
          final aiMessage = ChatMessage(
            message: response['message'] ?? 'Sorry, I didn\'t understand that.',
            isUser: false,
            timestamp: DateTime.now(),
          );

          // Add buttons if present
          if (response['buttons'] != null) {
            aiMessage.buttons = (response['buttons'] as List)
                .map((button) => ChatButton(
                      text: button['text'],
                      action: button['action'],
                      data: button['data'],
                    ))
                .toList();
          }

          _messages.add(aiMessage);

          // Update extracted job data
          if (response['extractedData'] != null) {
            _extractedJobData = response['extractedData'];
            _completionPercentage =
                (response['extractedData']['confidence'] * 100).round();
          }

          _isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      print('❌ Error sending message to Gemini: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            message:
                'Sorry, I\'m having trouble processing your request. Please try again.'
                    .tr(),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<Map<String, dynamic>> _sendToGemini(String message) async {
    try {
      // Generate a simple user ID for now - this can be replaced with actual auth later
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.post(
        Uri.parse(_geminiChatUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3ZGhuc2Nvd3lpYmJidm95c2ZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NjQ3ODUsImV4cCI6MjA2NjM0MDc4NX0.2gsbjyjj82Fb6bT89XpJdlxzRwHTfu0Lw_rXwpB565g',
        },
        body: json.encode({
          'message': message,
          'conversationId': _conversationId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      rethrow;
    }
  }

  void _handleButtonPress(ChatButton button) {
    switch (button.action) {
      case 'navigate_to_form':
        _navigateToJobRequest();
        break;
      case 'navigate_to_report':
        _navigateToJobReport(button.data?['jobType']);
        break;
      default:
        print('Unknown button action: ${button.action}');
    }
  }

  void _navigateToJobRequest() {
    if (_extractedJobData != null && _conversationId != null) {
      // Navigate to job request form with extracted data
      context.go('/helpee/job-request', extra: {
        'sessionId': _conversationId,
        'extractedData': _extractedJobData,
      });
    } else {
      context.go('/helpee/job-request');
    }
  }

  void _navigateToJobReport(String? jobType) {
    // Navigate to unknown job report page
    context.go('/helpee/job-report', extra: {
      'jobType': jobType,
      'conversationId': _conversationId,
    });
  }

  void _scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now'.tr();
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  List<ChatButton>? buttons;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.buttons,
  });
}

class ChatButton {
  final String text;
  final String action;
  final Map<String, dynamic>? data;

  ChatButton({
    required this.text,
    required this.action,
    this.data,
  });
} 
