import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/voice_ai_call_service.dart';
import '../../services/localization_service.dart';

/// Widget that provides call control buttons (start, pause, end)
class CallControls extends StatelessWidget {
  final VoiceCallState callState;
  final bool isInitialized;
  final VoidCallback onStartCall;
  final VoidCallback onEndCall;
  final VoidCallback onPauseCall;
  final VoidCallback onResumeCall;

  const CallControls({
    super.key,
    required this.callState,
    required this.isInitialized,
    required this.onStartCall,
    required this.onEndCall,
    required this.onPauseCall,
    required this.onResumeCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // Primary action row
          Row(
            children: [
              // Start/End call button
              Expanded(
                flex: 2,
                child: _buildPrimaryButton(context),
              ),

              // Secondary controls (if call is active)
              if (_shouldShowSecondaryControls()) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryButton(context),
                ),
              ],
            ],
          ),

          // Call duration (if active)
          if (_shouldShowCallDuration()) ...[
            const SizedBox(height: 12),
            _buildCallDuration(),
          ],

          // Quick tips
          if (!_isCallActive()) ...[
            const SizedBox(height: 12),
            _buildQuickTips(),
          ],
        ],
      ),
    );
  }

  /// Build the primary action button (Start/End Call)
  Widget _buildPrimaryButton(BuildContext context) {
    final buttonData = _getPrimaryButtonData();

    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: buttonData['enabled'] ? buttonData['action'] : null,
        icon: Icon(
          buttonData['icon'],
          size: 20,
        ),
        label: Text(
          buttonData['text'].tr(),
          style: AppTextStyles.buttonMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonData['color'],
          foregroundColor: buttonData['textColor'],
          disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
          disabledForegroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: buttonData['enabled'] ? 3 : 0,
        ),
      ),
    );
  }

  /// Build secondary action button (Pause/Resume)
  Widget _buildSecondaryButton(BuildContext context) {
    final buttonData = _getSecondaryButtonData();

    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: buttonData['enabled'] ? buttonData['action'] : null,
        icon: Icon(
          buttonData['icon'],
          size: 18,
        ),
        label: Text(
          buttonData['text'],
          style: AppTextStyles.buttonMedium.copyWith(
            color: buttonData['color'],
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: buttonData['enabled']
                ? buttonData['color']
                : AppColors.textSecondary.withOpacity(0.3),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  /// Build call duration display
  Widget _buildCallDuration() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            _getCallDurationText(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick tips for users
  Widget _buildQuickTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getQuickTip(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get primary button configuration
  Map<String, dynamic> _getPrimaryButtonData() {
    switch (callState) {
      case VoiceCallState.uninitialized:
        return {
          'text': 'Initializing...',
          'icon': Icons.hourglass_empty,
          'color': AppColors.textSecondary,
          'textColor': AppColors.white,
          'action': null,
          'enabled': false,
        };

      case VoiceCallState.initialized:
      case VoiceCallState.callEnded:
        return {
          'text': 'Start Voice Call',
          'icon': Icons.phone,
          'color': AppColors.primaryGreen,
          'textColor': AppColors.white,
          'action': onStartCall,
          'enabled': isInitialized,
        };

      case VoiceCallState.callStarted:
      case VoiceCallState.listeningForUser:
      case VoiceCallState.processingUserInput:
      case VoiceCallState.processingWithAI:
      case VoiceCallState.generatingSpeech:
      case VoiceCallState.aiSpeaking:
      case VoiceCallState.waitingForUser:
        return {
          'text': 'End Call',
          'icon': Icons.call_end,
          'color': AppColors.error,
          'textColor': AppColors.white,
          'action': onEndCall,
          'enabled': true,
        };

      case VoiceCallState.paused:
        return {
          'text': 'Resume Call',
          'icon': Icons.play_arrow,
          'color': AppColors.success,
          'textColor': AppColors.white,
          'action': onResumeCall,
          'enabled': true,
        };

      case VoiceCallState.error:
        return {
          'text': 'Retry',
          'icon': Icons.refresh,
          'color': AppColors.warning,
          'textColor': AppColors.white,
          'action': onStartCall,
          'enabled': true,
        };

      default:
        return {
          'text': 'Unknown State',
          'icon': Icons.help,
          'color': AppColors.textSecondary,
          'textColor': AppColors.white,
          'action': null,
          'enabled': false,
        };
    }
  }

  /// Get secondary button configuration
  Map<String, dynamic> _getSecondaryButtonData() {
    switch (callState) {
      case VoiceCallState.callStarted:
      case VoiceCallState.listeningForUser:
      case VoiceCallState.waitingForUser:
      case VoiceCallState.aiSpeaking:
        return {
          'text': 'Pause',
          'icon': Icons.pause,
          'color': AppColors.warning,
          'action': onPauseCall,
          'enabled': true,
        };

      case VoiceCallState.paused:
        return {
          'text': 'Resume',
          'icon': Icons.play_arrow,
          'color': AppColors.success,
          'action': onResumeCall,
          'enabled': true,
        };

      case VoiceCallState.processingUserInput:
      case VoiceCallState.processingWithAI:
      case VoiceCallState.generatingSpeech:
        return {
          'text': 'Processing...',
          'icon': Icons.hourglass_empty,
          'color': AppColors.textSecondary,
          'action': null,
          'enabled': false,
        };

      default:
        return {
          'text': 'Options',
          'icon': Icons.more_horiz,
          'color': AppColors.textSecondary,
          'action': null,
          'enabled': false,
        };
    }
  }

  /// Should show secondary controls
  bool _shouldShowSecondaryControls() {
    return _isCallActive() || callState == VoiceCallState.paused;
  }

  /// Should show call duration
  bool _shouldShowCallDuration() {
    return _isCallActive();
  }

  /// Check if call is currently active
  bool _isCallActive() {
    return [
      VoiceCallState.callStarted,
      VoiceCallState.listeningForUser,
      VoiceCallState.processingUserInput,
      VoiceCallState.processingWithAI,
      VoiceCallState.generatingSpeech,
      VoiceCallState.aiSpeaking,
      VoiceCallState.waitingForUser,
      VoiceCallState.paused,
    ].contains(callState);
  }

  /// Get call duration text (placeholder - would need actual timing)
  String _getCallDurationText() {
    // In a real implementation, this would track actual call duration
    switch (callState) {
      case VoiceCallState.callStarted:
        return '00:05';
      case VoiceCallState.listeningForUser:
      case VoiceCallState.waitingForUser:
        return '00:15';
      case VoiceCallState.aiSpeaking:
        return '00:23';
      case VoiceCallState.paused:
        return 'Paused';
      default:
        return '00:30';
    }
  }

  /// Get quick tip based on current state
  String _getQuickTip() {
    switch (callState) {
      case VoiceCallState.initialized:
        return 'Tip: Speak clearly and describe what help you need. The AI will ask follow-up questions to understand your requirements.';

      case VoiceCallState.callEnded:
        return 'Great! If the AI collected job information, you can now fill out the job request form with the pre-populated data.';

      case VoiceCallState.error:
        return 'Make sure your microphone is connected and you\'ve granted permission to use it.';

      default:
        return 'The AI assistant will help you describe your needs and may collect information for a job request.';
    }
  }
}
