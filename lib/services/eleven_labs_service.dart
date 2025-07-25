import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// ElevenLabs Text-to-Speech Service
/// Integrates with ElevenLabs API for high-quality voice synthesis
class ElevenLabsService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';

  // User provided credentials
  static const String _apiKey =
      'sk_6778b4b6007f78033d08dc0a314855aa90e2a444aa0603c7';
  static const String _defaultVoiceId = 'bIHbv24MWmeRgasZH58o';

  // Voice settings for optimal quality
  static const Map<String, dynamic> _voiceSettings = {
    'stability': 0.5,
    'similarity_boost': 0.8,
    'style': 0.2,
    'use_speaker_boost': true,
  };

  /// Synthesize speech from text using ElevenLabs API
  static Future<Uint8List?> synthesizeSpeech({
    required String text,
    String? voiceId,
    Map<String, dynamic>? customVoiceSettings,
  }) async {
    try {
      print(
          '🎤 Synthesizing speech with ElevenLabs: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      if (text.trim().isEmpty) {
        print('⚠️ Empty text provided for speech synthesis');
        return null;
      }

      final String effectiveVoiceId = voiceId ?? _defaultVoiceId;
      final Map<String, dynamic> effectiveSettings =
          customVoiceSettings ?? _voiceSettings;

      final url = Uri.parse('$_baseUrl/text-to-speech/$effectiveVoiceId');

      final requestBody = {
        'text': text,
        'model_id': 'eleven_monolingual_v1',
        'voice_settings': effectiveSettings,
      };

      print('🔗 Making request to ElevenLabs API: $url');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': _apiKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print(
            '✅ Speech synthesis successful, audio length: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('❌ ElevenLabs API error: ${response.statusCode}');
        print('📝 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error synthesizing speech: $e');
      return null;
    }
  }

  /// Get available voices from ElevenLabs
  static Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      print('🔍 Fetching available voices from ElevenLabs');

      final url = Uri.parse('$_baseUrl/voices');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'xi-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final voices = List<Map<String, dynamic>>.from(data['voices'] ?? []);
        print('✅ Found ${voices.length} available voices');
        return voices;
      } else {
        print('❌ Error fetching voices: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching voices: $e');
      return [];
    }
  }

  /// Get voice information by ID
  static Future<Map<String, dynamic>?> getVoiceInfo(String voiceId) async {
    try {
      print('🔍 Getting voice info for: $voiceId');

      final url = Uri.parse('$_baseUrl/voices/$voiceId');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'xi-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final voiceInfo = jsonDecode(response.body);
        print('✅ Voice info retrieved: ${voiceInfo['name']}');
        return voiceInfo;
      } else {
        print('❌ Error fetching voice info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching voice info: $e');
      return null;
    }
  }

  /// Test the API connection and voice
  static Future<bool> testConnection() async {
    try {
      print('🧪 Testing ElevenLabs connection...');

      final testAudio = await synthesizeSpeech(
        text: 'Hello! This is a test message from Helping Hands AI Assistant.',
      );

      if (testAudio != null) {
        print('✅ ElevenLabs connection test successful');
        return true;
      } else {
        print('❌ ElevenLabs connection test failed');
        return false;
      }
    } catch (e) {
      print('❌ ElevenLabs connection test error: $e');
      return false;
    }
  }

  /// Get current API usage statistics
  static Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      print('📊 Fetching ElevenLabs usage statistics');

      final url = Uri.parse('$_baseUrl/user');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'xi-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('✅ Usage stats retrieved');
        return {
          'character_count': userData['subscription']['character_count'],
          'character_limit': userData['subscription']['character_limit'],
          'usage_percentage': (userData['subscription']['character_count'] /
                  userData['subscription']['character_limit'] *
                  100)
              .toStringAsFixed(1),
        };
      } else {
        print('❌ Error fetching usage stats: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching usage stats: $e');
      return null;
    }
  }

  /// Validate if the provided API key and voice ID are working
  static Future<Map<String, dynamic>> validateCredentials() async {
    try {
      print('🔐 Validating ElevenLabs credentials...');

      // Test API key by fetching user info
      final userUrl = Uri.parse('$_baseUrl/user');
      final userResponse = await http.get(
        userUrl,
        headers: {
          'Accept': 'application/json',
          'xi-api-key': _apiKey,
        },
      );

      if (userResponse.statusCode != 200) {
        return {
          'valid': false,
          'error': 'Invalid API key',
          'details': 'API key authentication failed'
        };
      }

      // Test voice ID
      final voiceInfo = await getVoiceInfo(_defaultVoiceId);
      if (voiceInfo == null) {
        return {
          'valid': false,
          'error': 'Invalid voice ID',
          'details': 'Voice ID not found or inaccessible'
        };
      }

      // Test synthesis
      final testSynthesis = await synthesizeSpeech(
        text: 'Connection test successful.',
      );

      if (testSynthesis == null) {
        return {
          'valid': false,
          'error': 'Synthesis failed',
          'details': 'Could not generate speech audio'
        };
      }

      print('✅ ElevenLabs credentials validated successfully');
      return {
        'valid': true,
        'voice_name': voiceInfo['name'],
        'user_info': jsonDecode(userResponse.body),
      };
    } catch (e) {
      return {
        'valid': false,
        'error': 'Validation error',
        'details': e.toString()
      };
    }
  }
}
