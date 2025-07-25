import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/voice_ai_call_service.dart';
import '../../services/localization_service.dart';

/// Widget that displays real-time transcription and conversation history
class TranscriptionDisplay extends StatelessWidget {
  final String currentTranscription;
  final List<VoiceMessage> conversationHistory;
  final Map<String, dynamic>? extractedJobData;

  const TranscriptionDisplay({
    super.key,
    required this.currentTranscription,
    required this.conversationHistory,
    this.extractedJobData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversation'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (extractedJobData != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Info Collected'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: conversationHistory.isEmpty
                ? _buildEmptyState()
                : _buildConversationList(),
          ),

          // Current transcription (if any)
          if (currentTranscription.isNotEmpty) _buildCurrentTranscription(),
        ],
      ),
    );
  }

  /// Build empty state when no conversation exists
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Start your voice call to see the conversation here'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build conversation messages list
  Widget _buildConversationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: conversationHistory.length,
      itemBuilder: (context, index) {
        final message = conversationHistory[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Build individual message bubble
  Widget _buildMessageBubble(VoiceMessage message) {
    final isUser = message.sender == VoiceMessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 12,
                  color: isUser
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.primaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? 'You'.tr() : 'AI Assistant'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isUser
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Message text
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
                height: 1.3,
              ),
            ),

            // Timestamp
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 9,
                color: isUser
                    ? Colors.white.withOpacity(0.6)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build current transcription indicator
  Widget _buildCurrentTranscription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Pulsing microphone icon
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0.5, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.mic,
                  color: AppColors.info,
                  size: 16,
                ),
              );
            },
            onEnd: () {
              // This will create a continuous pulse effect
            },
          ),
          const SizedBox(width: 8),

          // Transcription text
          Expanded(
            child: Text(
              currentTranscription.isEmpty
                  ? 'Listening...'.tr()
                  : currentTranscription,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.info,
                fontStyle: currentTranscription.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Format timestamp for display
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now'.tr();
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
