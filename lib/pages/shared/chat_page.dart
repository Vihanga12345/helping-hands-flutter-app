import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../services/messaging_service.dart';
import '../../services/webrtc_calling_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../../services/realtime_notification_service.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String? jobId;
  final String? otherUserId;
  final String? otherUserName;
  final String? jobTitle;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.jobId,
    this.otherUserId,
    this.otherUserName,
    this.jobTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MessagingService _messagingService = MessagingService();
  final WebRTCService _webrtcService = WebRTCService();
  final CustomAuthService _authService = CustomAuthService();
  final RealTimeNotificationService _notificationService =
      RealTimeNotificationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) context.pop();
        return;
      }

      _currentUserId = currentUser['user_id'];

      // Initialize WebRTC service
      await _webrtcService.initialize();

      // Initialize chat with real-time messaging
      await _messagingService.initializeChat(widget.conversationId);

      // Subscribe to real-time messages stream
      _messagesSubscription = _messagingService
          .getMessagesStream(widget.conversationId)
          .listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _scrollToBottom();
        }
      });

      // Mark messages as read
      await _messagingService.markMessagesAsRead(
        conversationId: widget.conversationId,
        userId: _currentUserId!,
      );

      print('✅ Chat initialized for conversation: ${widget.conversationId}');
    } catch (e) {
      print('❌ Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final success = await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        senderId: _currentUserId!,
        messageText: messageText,
      );

      if (success) {
        _messageController.clear();
        _scrollToBottom();
        print('✅ Message sent successfully');
      } else {
        _showErrorSnackBar('Failed to send message'.tr());
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      _showErrorSnackBar('Error sending message'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // Debug method to test message notifications
  void _testMessageNotification() {
    print('🧪 Testing message notification from chat page...');
    _notificationService.triggerTestMessageNotification();

    // Also show a snackbar to confirm button was pressed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Test notification triggered! Check for popup...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _makeCall(CallType callType) async {
    if (widget.otherUserId == null) {
      _showErrorSnackBar('Cannot make call: other user not found'.tr());
      return;
    }

    try {
      final success = await _webrtcService.makeCall(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId!,
        callType: callType,
      );

      if (success) {
        // Navigate to call screen
        if (mounted) {
          context.push('/call', extra: {
            'callType': callType.name,
            'isIncoming': false,
            'otherUserName': widget.otherUserName,
          });
        }
      } else {
        _showErrorSnackBar('Failed to initiate call'.tr());
      }
    } catch (e) {
      print('❌ Error making call: $e');
      _showErrorSnackBar('Error making call'.tr());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: widget.otherUserName ?? 'Chat',
        showBackButton: true,
        showMenuButton: false,
        showNotificationButton: false,
        rightWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Audio call button
            GestureDetector(
              onTap: () => _makeCall(CallType.audio),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call,
                  color: Color(0xFF8FD89F),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Video call button
            GestureDetector(
              onTap: () => _makeCall(CallType.video),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.video_call,
                  color: Color(0xFF8FD89F),
                  size: 18,
                ),
              ),
            ),
          ],
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
        child: Column(
          children: [
            // Job title info (if available)
            if (widget.jobTitle != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.primaryGreen.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.work,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Job: ${widget.jobTitle}',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Debug test notification button (only in debug mode)
                    IconButton(
                      onPressed: _testMessageNotification,
                      icon: Icon(
                        Icons.bug_report,
                        color: Colors.orange,
                        size: 20,
                      ),
                      tooltip: 'Test Notification',
                    ),
                  ],
                ),
              ),

            // Messages
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildMessagesList(),
            ),

            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet'.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!'.tr(),
              style: const TextStyle(
                fontSize: 14,
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
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final senderId = message['sender_id'] as String;
    final isCurrentUser = senderId == _currentUserId;
    final messageText = message['message_text'] as String? ?? '';
    final messageType = message['message_type'] as String? ?? 'text';
    final createdAt = DateTime.parse(message['created_at']);
    final sender = message['sender'] as Map<String, dynamic>?;
    final senderName = sender != null
        ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim()
        : 'Unknown'.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name (for group chats or system messages)
          if (!isCurrentUser && messageType != 'system')
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                senderName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Message bubble
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isCurrentUser) ...[
                // Other user's avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Message content
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getMessageBubbleColor(messageType, isCurrentUser),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      if (messageText.isNotEmpty)
                        Text(
                          messageText,
                          style: TextStyle(
                            color: _getMessageTextColor(
                                messageType, isCurrentUser),
                            fontSize: 16,
                          ),
                        ),

                      // Timestamp
                      const SizedBox(height: 4),
                      Text(
                        MessagingService.formatMessageTime(
                            createdAt.toIso8601String()),
                        style: TextStyle(
                          color:
                              _getMessageTextColor(messageType, isCurrentUser)
                                  .withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                // Current user's avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getMessageBubbleColor(String messageType, bool isCurrentUser) {
    if (messageType == 'system') {
      return AppColors.lightGrey.withOpacity(0.5);
    } else if (isCurrentUser) {
      return AppColors.primaryGreen;
    } else {
      return AppColors.white;
    }
  }

  Color _getMessageTextColor(String messageType, bool isCurrentUser) {
    if (messageType == 'system') {
      return AppColors.textSecondary;
    } else if (isCurrentUser) {
      return AppColors.white;
    } else {
      return AppColors.textPrimary;
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightGrey, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...'.tr(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Send button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
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
}
