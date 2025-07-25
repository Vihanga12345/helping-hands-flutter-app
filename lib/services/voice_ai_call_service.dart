import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:helping_hands_app/models/voice_message.dart';
import 'package:helping_hands_app/services/speech_to_text_service.dart';
import 'package:helping_hands_app/services/text_to_speech_service.dart';
import 'package:helping_hands_app/utils/constants.dart';
import 'package:uuid/uuid.dart';

class VoiceAICallService {
  final SpeechToTextService _speechToTextService;
  final TextToSpeechService _textToSpeechService;
  final ValueNotifier<VoiceCallState> _callStateController;
  final List<VoiceMessage> _conversationHistory;
  bool _isCallActive = false;
  bool _isWaitingForUserResponse = false;
  Timer? _silenceTimer;

  VoiceAICallService(this._speechToTextService, this._textToSpeechService,
      this._callStateController, this._conversationHistory);

  /// Wait for user response and start listening
  Future<void> _waitForUserResponse() async {
    try {
      print('👂 Waiting for user response...');

      _isWaitingForUserResponse = true;
      _callStateController.add(VoiceCallState.waitingForUser);

      // Give extra time for AI audio to completely finish
      await Future.delayed(const Duration(milliseconds: 1500));

      // Start listening for user input
      print('🎙️ Starting speech recognition after audio buffer...');
      final success = await _speechToTextService.startListening();

      if (success) {
        // Set up timeout for repeating question if user doesn't respond
        _setupQuestionRepeatTimer();
      } else {
        print('❌ Failed to start listening for user input');
        _callStateController.add(VoiceCallState.error);
      }
    } catch (e) {
      print('❌ Error waiting for user response: $e');
    }
  }

  /// Setup timer to repeat question if user is silent for too long
  void _setupQuestionRepeatTimer() {
    _cancelSilenceTimer();
    _silenceTimer = Timer(const Duration(seconds: 8), () async {
      if (_isWaitingForUserResponse && _isCallActive) {
        print('🔁 User silent for too long - repeating last question');

        // Get last AI message to repeat
        final lastAiMessage = _conversationHistory.reversed
            .firstWhere((msg) => msg.sender == VoiceMessageSender.ai,
                orElse: () => VoiceMessage(
                      id: _generateMessageId(),
                      text:
                          "I didn't hear your response. Could you please tell me what kind of help you need?",
                      sender: VoiceMessageSender.ai,
                      timestamp: DateTime.now(),
                      audioData: null,
                    ));

        // Stop current listening
        await _speechToTextService.stopListening();
        _isWaitingForUserResponse = false;

        // Repeat the question
        final repeatText = "I didn't catch that. ${lastAiMessage.text}";
        await _speakAIResponse(repeatText);
      }
    });
  }
}
