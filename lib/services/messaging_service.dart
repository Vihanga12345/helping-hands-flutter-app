import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream subscriptions for real-time updates
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _conversationsChannel;

  // Stream controllers for real-time updates
  final StreamController<List<Map<String, dynamic>>> _messagesStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>>
      _conversationsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Current conversation and user tracking
  String? _currentConversationId;
  String? _currentUserId;

  // Getters for streams
  Stream<List<Map<String, dynamic>>> get conversationsStream =>
      _conversationsStreamController.stream;

  /// Initialize messaging service for user
  Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;
      print('💬 Initializing messaging service for user: $userId');

      // Clean up any existing subscriptions
      await _cleanup();

      // Subscribe to conversation updates
      _conversationsChannel = _supabase
          .channel('conversations:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (payload) {
              print('💬 Conversation update received');
              _loadConversations();
            },
          )
          .subscribe();

      // Load initial conversations
      await _loadConversations();

      print('✅ Messaging service initialized successfully');
    } catch (e) {
      print('❌ Error initializing messaging service: $e');
    }
  }

  /// Load conversations for current user
  Future<void> _loadConversations() async {
    if (_currentUserId == null) return;

    try {
      final conversations = await getConversations(_currentUserId!);
      _conversationsStreamController.add(conversations);
    } catch (e) {
      print('❌ Error loading conversations: $e');
    }
  }

  /// Get messages stream for a conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    // Set current conversation for real-time updates
    _currentConversationId = conversationId;

    // Load initial messages
    _loadMessages(conversationId);

    // Return the stream
    return _messagesStreamController.stream;
  }

  /// Load messages for a conversation
  Future<void> _loadMessages(String conversationId) async {
    try {
      final messages = await getMessages(conversationId);
      _messagesStreamController.add(messages);
      print(
          '💬 Loaded ${messages.length} messages for conversation: $conversationId');
    } catch (e) {
      print('❌ Error loading messages: $e');
    }
  }

  /// Initialize messaging service for a conversation with real-time updates
  Future<void> initializeChat(String conversationId) async {
    try {
      print('💬 Initializing chat for conversation: $conversationId');

      _currentConversationId = conversationId;

      // Clean up existing message subscription
      await _messageChannel?.unsubscribe();

      // Subscribe to real-time message updates for this conversation
      _messageChannel = _supabase
          .channel('messages:$conversationId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              print('💬 New message received in conversation: $conversationId');
              // Immediately reload messages when a new message is inserted
              _loadMessages(conversationId);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              print('💬 Message updated in conversation: $conversationId');
              // Reload messages when any message is updated (e.g., read status)
              _loadMessages(conversationId);
            },
          )
          .subscribe();

      // Load initial messages
      await _loadMessages(conversationId);

      print('✅ Chat initialized successfully with real-time updates');
    } catch (e) {
      print('❌ Error initializing chat: $e');
    }
  }

  /// Clean up subscriptions
  Future<void> _cleanup() async {
    try {
      await _messageChannel?.unsubscribe();
      await _conversationsChannel?.unsubscribe();
      _messageChannel = null;
      _conversationsChannel = null;
    } catch (e) {
      print('⚠️ Error during messaging service cleanup: $e');
    }
  }

  /// Get or create a conversation between two users for a job
  Future<String> getOrCreateConversation({
    required String jobId,
    required String helperId,
    required String helpeeId,
  }) async {
    try {
      print('💬 Getting/creating conversation for job: $jobId');

      // Check if conversation already exists for this job
      final existingConversation = await _supabase
          .from('conversations')
          .select('id')
          .eq('job_id', jobId)
          .maybeSingle();

      if (existingConversation != null) {
        final conversationId = existingConversation['id'];
        print('✅ Conversation ID: $conversationId');
        return conversationId;
      }

      // Create new conversation
      final response =
          await _supabase.rpc('get_or_create_conversation', params: {
        'p_job_id': jobId,
        'p_helper_id': helperId,
        'p_helpee_id': helpeeId,
      });

      final conversationId = response as String;
      print('✅ Conversation ID: $conversationId');
      return conversationId;
    } catch (e) {
      print('❌ Error getting/creating conversation: $e');
      rethrow;
    }
  }

  /// Send a message to a conversation
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
  }) async {
    try {
      print('💬 Sending message to conversation: $conversationId');

      await _supabase.rpc('send_message', params: {
        'p_conversation_id': conversationId,
        'p_sender_id': senderId,
        'p_message_text': messageText,
        'p_message_type': 'text',
      });

      // Reload messages after sending
      _loadMessages(conversationId);

      print('✅ Message sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      print('💬 Getting messages for conversation: $conversationId');

      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = List<Map<String, dynamic>>.from(response);
      print('✅ Found ${messages.length} messages');
      return messages;
    } catch (e) {
      print('❌ Error getting messages: $e');
      return [];
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      print('💬 Marking messages as read for conversation: $conversationId');

      await _supabase.rpc('mark_messages_as_read', params: {
        'p_conversation_id': conversationId,
        'p_user_id': userId,
      });

      print('✅ Marked messages as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Get conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('''
            id,
            job_id,
            helper_id,
            helpee_id,
            created_at,
            helper_unread_count,
            helpee_unread_count,
            last_message_at
          ''')
          .or('helper_id.eq.$userId,helpee_id.eq.$userId')
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting conversations: $e');
      return [];
    }
  }

  /// Get the other participant in a conversation
  static Map<String, dynamic>? getOtherParticipant(
      Map<String, dynamic> conversation, String currentUserId) {
    try {
      final helperId = conversation['helper_id'];
      final helpeeId = conversation['helpee_id'];

      if (helperId == currentUserId) {
        return {'id': helpeeId, 'role': 'helpee'};
      } else if (helpeeId == currentUserId) {
        return {'id': helperId, 'role': 'helper'};
      }

      return null;
    } catch (e) {
      print('❌ Error getting other participant: $e');
      return null;
    }
  }

  /// Get conversation title based on other participant
  static String getConversationTitle(
      Map<String, dynamic> conversation, String currentUserId) {
    try {
      final otherParticipant = getOtherParticipant(conversation, currentUserId);
      if (otherParticipant == null) return 'Unknown';

      final role = otherParticipant['role'];
      final jobId = conversation['job_id'];

      return '$role - Job #$jobId';
    } catch (e) {
      print('❌ Error getting conversation title: $e');
      return 'Unknown';
    }
  }

  /// Format message timestamp
  static String formatMessageTime(dynamic timestamp) {
    try {
      if (timestamp == null) return '';

      DateTime messageTime;
      if (timestamp is String) {
        messageTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        messageTime = timestamp;
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(messageTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM dd').format(messageTime);
      }
    } catch (e) {
      print('❌ Error formatting message time: $e');
      return '';
    }
  }

  /// Dispose messaging service
  void dispose() {
    _cleanup();
    _messagesStreamController.close();
    _conversationsStreamController.close();
    print('🔄 Messaging service disposed');
  }
}
