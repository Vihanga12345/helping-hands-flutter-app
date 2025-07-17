import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/messaging_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../../models/user_type.dart';
import 'dart:async';

class ConversationsPage extends StatefulWidget {
  final UserType userType;

  const ConversationsPage({
    super.key,
    required this.userType,
  });

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final MessagingService _messagingService = MessagingService();
  final CustomAuthService _authService = CustomAuthService();

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  StreamSubscription? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeConversations();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeConversations() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) context.go('/');
        return;
      }

      _currentUserId = currentUser['user_id'];

      // Initialize messaging service
      await _messagingService.initialize(_currentUserId!);

      // Subscribe to conversations
      _conversationsSubscription =
          _messagingService.conversationsStream.listen((conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
            _isLoading = false;
          });
        }
      });

      print('✅ Conversations initialized');
    } catch (e) {
      print('❌ Error initializing conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshConversations() async {
    if (_currentUserId != null) {
      setState(() {
        _isLoading = true;
      });

      final conversations =
          await _messagingService.getConversations(_currentUserId!);
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    }
  }

  void _openConversation(Map<String, dynamic> conversation) {
    final conversationId = conversation['id'] as String;
    final job = conversation['jobs'] as Map<String, dynamic>?;
    final otherParticipant =
        MessagingService.getOtherParticipant(conversation, _currentUserId!);

    final otherUserName = otherParticipant != null
        ? '${otherParticipant['first_name'] ?? ''} ${otherParticipant['last_name'] ?? ''}'
            .trim()
        : 'Unknown User'.tr();

    context.push('/chat', extra: {
      'conversationId': conversationId,
      'jobId': job?['id'],
      'otherUserId': otherParticipant?['id'],
      'otherUserName': otherUserName,
      'jobTitle': job?['title'],
    });
  }

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
                title: 'Messages'.tr(),
                showMenuButton: true,
                showNotificationButton: true,
                onMenuPressed: () {
                  final menuRoute = widget.userType == UserType.helper
                      ? '/helper/menu'
                      : '/helpee/menu';
                  context.push(menuRoute);
                },
                onNotificationPressed: () {
                  final notificationRoute = widget.userType == UserType.helper
                      ? '/helper/notifications'
                      : '/helpee/notifications';
                  context.push(notificationRoute);
                },
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildConversationsList(),
              ),

              // Navigation Bar
              AppNavigationBar(
                currentTab:
                    NavigationTab.activity, // Assuming messages are in activity
                userType: widget.userType,
              ),
            ],
          ),
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

  Widget _buildConversationsList() {
    if (_conversations.isEmpty) {
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
              'No conversations yet'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start messaging when you have active jobs'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshConversations,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final job = conversation['jobs'] as Map<String, dynamic>?;
    final otherParticipant =
        MessagingService.getOtherParticipant(conversation, _currentUserId!);
    final lastMessageAt = DateTime.parse(conversation['last_message_at']);

    // Get unread count based on user type
    final currentUser = _authService.currentUser;
    final userType = currentUser?['user_type'] as String?;
    final unreadCount = userType == 'helper'
        ? (conversation['helper_unread_count'] as int? ?? 0)
        : (conversation['helpee_unread_count'] as int? ?? 0);

    final title =
        MessagingService.getConversationTitle(conversation, _currentUserId!);
    final otherUserName = otherParticipant != null
        ? '${otherParticipant['first_name'] ?? ''} ${otherParticipant['last_name'] ?? ''}'
            .trim()
        : 'Unknown User'.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipOval(
                child: otherParticipant?['profile_image_url'] != null
                    ? Image.network(
                        otherParticipant!['profile_image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 30,
                        color: AppColors.primaryGreen,
                      ),
              ),
            ),

            // Unread badge
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (job != null) ...[
              Text(
                'Job: ${job['title'] ?? 'Unknown Job'.tr()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],
            Text(
              'Last message: ${MessagingService.formatMessageTime(lastMessageAt.toIso8601String())}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Job status
            if (job != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getJobStatusColor(job['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (job['status'] ?? 'Unknown'.tr()).toUpperCase(),
                  style: TextStyle(
                    color: _getJobStatusColor(job['status']),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Arrow icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }

  Color _getJobStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
      case 'started':
      case 'ongoing':
        return AppColors.primaryGreen;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
