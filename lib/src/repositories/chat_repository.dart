import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/chat_room_model.dart';
import 'package:smart_iraq/src/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatRepository {
  Future<List<ChatRoom>> getChatRooms();
  Stream<List<Message>> getMessagesStream(String roomId);
  Future<void> sendMessage(String roomId, String content);
  Future<String> findOrCreateChatRoom(String otherUserId);
}

class SupabaseChatRepository implements ChatRepository {
  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw AuthException('User not logged in');

    final data = await supabase
        .from('chat_rooms')
        .select()
        .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
        .order('created_at', ascending: false);

    return (data as List).map((json) => ChatRoom.fromJson(json)).toList();
  }

  @override
  Stream<List<Message>> getMessagesStream(String roomId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((maps) => maps.map((map) => Message.fromJson(map)).toList());
  }

  @override
  Future<void> sendMessage(String roomId, String content) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw AuthException('User not logged in');
    if (content.isEmpty) return;

    await supabase.from('messages').insert({
      'room_id': roomId,
      'sender_id': userId,
      'content': content.trim(),
    });
  }

  @override
  Future<String> findOrCreateChatRoom(String otherUserId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) throw AuthException('User not logged in');
    if (currentUserId == otherUserId) throw ArgumentError('Cannot create chat room with oneself.');

    // To avoid duplicates, we sort the IDs and store them in a consistent order.
    final p1 = currentUserId.compareTo(otherUserId) < 0 ? currentUserId : otherUserId;
    final p2 = currentUserId.compareTo(otherUserId) < 0 ? otherUserId : currentUserId;

    final rooms = await supabase
        .from('chat_rooms')
        .select('id')
        .eq('participant1_id', p1)
        .eq('participant2_id', p2);

    if (rooms.isNotEmpty) {
      return rooms.first['id'] as String;
    } else {
      final newRoom = await supabase.from('chat_rooms').insert({
        'participant1_id': p1,
        'participant2_id': p2,
      }).select().single();
      return newRoom['id'] as String;
    }
  }
}
