import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/chat_room_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  final ChatRepository chatRepository;
  const ChatRoomsScreen({super.key, required this.chatRepository});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  late Future<List<ChatRoom>> _chatRoomsFuture;
  final _userId = supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    if (_userId != null) {
      _chatRoomsFuture = widget.chatRepository.getChatRooms();
    }
  }

  Future<Profile?> _getOtherParticipantProfile(String otherId) async {
    try {
      final data = await supabase.from('profiles').select().eq('id', otherId).maybeSingle();
      return data != null ? Profile.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error fetching profile for $otherId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المحادثات')),
        body: const Center(child: Text('الرجاء تسجيل الدخول لعرض المحادثات.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('محادثاتي'),
      ),
      body: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد لديك محادثات بعد.', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          final rooms = snapshot.data!;
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final otherParticipantId = _userId == room.participant1Id
                  ? room.participant2Id
                  : room.participant1Id;

              return FutureBuilder<Profile?>(
                future: _getOtherParticipantProfile(otherParticipantId),
                builder: (context, profileSnapshot) {
                  final otherProfile = profileSnapshot.data;
                  final title = otherProfile?.username ?? 'مستخدم';
                  final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      child: Text(initial),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('اضغط لعرض المحادثة...'), // Placeholder for last message
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            roomId: room.id,
                            chatRepository: widget.chatRepository,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
