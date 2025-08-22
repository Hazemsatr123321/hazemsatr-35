import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/message_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final ChatRepository chatRepository;
  const ChatScreen({
    super.key,
    required this.roomId,
    required this.chatRepository,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Stream<List<Message>> _messagesStream;
  final _messageController = TextEditingController();
  bool _isGeneratingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = widget.chatRepository.getMessagesStream(widget.roomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    try {
      await widget.chatRepository.sendMessage(widget.roomId, _messageController.text);
      _messageController.clear();
    } catch (error) {
      // In a real app, show an error message
    }
  }

  Future<void> _getAiSuggestion() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _isGeneratingSuggestion = true;
    });
    try {
      final response = await supabase.functions.invoke(
        'generate-chat-suggestion',
        body: {'prompt': _messageController.text.trim()},
      );
      if (response.data != null && response.data['suggestion'] != null) {
        _messageController.text = response.data['suggestion'];
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء جلب الاقتراح.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSuggestion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('لا توجد رسائل بعد. ابدأ المحادثة!'));
                }

                return ListView.builder(
                  reverse: true, // To show latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == currentUserId;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color: isMine ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[300],
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(message.content),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            _isGeneratingSuggestion
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: _getAiSuggestion,
                    tooltip: 'اقتراح رسالة (AI)',
                  ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
