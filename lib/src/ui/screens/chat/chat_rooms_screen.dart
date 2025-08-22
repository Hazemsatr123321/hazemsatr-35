import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/chat_room_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  final ChatRepository chatRepository;
  const ChatRoomsScreen({super.key, required this.chatRepository});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  late final Future<List<ChatRoom>> _chatRoomsFuture;
  final _userId = supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    if (_userId != null) {
      _chatRoomsFuture = widget.chatRepository.getChatRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('الرجاء تسجيل الدخول لعرض المحادثات.')),
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
            return const Center(child: Text('لا توجد لديك محادثات بعد.'));
          }

          final rooms = snapshot.data!;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final otherParticipantId = _userId == room.participant1Id
                  ? room.participant2Id
                  : room.participant1Id;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text('محادثة مع المستخدم'),
                subtitle: Text(otherParticipantId),
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
      ),
    );
  }
}
