import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class AudioRecorderService {
  bool _isInitialized = false;
  html.AudioElement? _audioPlayer;

  /// Play audio from Uint8List and wait for completion
  Future<bool> playAudio(Uint8List audioData) async {
    try {
      if (!_isInitialized || _audioPlayer == null) {
        print('❌ Audio player not initialized');
        return false;
      }

      print('▶️ Playing audio: ${audioData.length} bytes');

      // Create blob from audio data
      final blob = html.Blob([audioData], 'audio/mpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create completer to wait for audio completion
      final completer = Completer<bool>();

      // Set up one-time listeners for this specific playback
      late StreamSubscription endedSubscription;
      late StreamSubscription errorSubscription;

      endedSubscription = _audioPlayer!.onEnded.listen((event) {
        print('✅ Audio playback completed');
        html.Url.revokeObjectUrl(url);
        endedSubscription.cancel();
        errorSubscription.cancel();
        completer.complete(true);
      });

      errorSubscription = _audioPlayer!.onError.listen((event) {
        print('❌ Audio playback error during play');
        html.Url.revokeObjectUrl(url);
        endedSubscription.cancel();
        errorSubscription.cancel();
        completer.complete(false);
      });

      // Set audio source and play
      _audioPlayer!.src = url;
      _audioPlayer!.play();

      // Wait for audio to complete or error
      return await completer.future;
    } catch (e) {
      print('❌ Error playing audio: $e');
      return false;
    }
  }
}
