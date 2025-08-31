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
    if (_messageController.text.trim().isEmpty) return;
    try {
      await widget.chatRepository.sendMessage(widget.roomId, _messageController.text);
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الرسالة: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _getAiSuggestion() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _isGeneratingSuggestion = true);
    try {
      final response = await supabase.functions.invoke('generate-chat-suggestion', body: {'prompt': _messageController.text.trim()});
      if (response.data != null && response.data['suggestion'] != null) {
        _messageController.text = response.data['suggestion'];
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('حدث خطأ أثناء جلب الاقتراح.'), backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingSuggestion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثة')),
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
                // We reverse the list to use it in a normal ListView, which is better
                // for performance with dynamic item heights than a reversed ListView.
                final reversedMessages = messages.reversed.toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    return _ChatMessageBubble(message: reversedMessages[index]);
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
    return Material(
      elevation: 5,
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    suffixIcon: _isGeneratingSuggestion
                        ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                            onPressed: _getAiSuggestion,
                            tooltip: 'اقتراح رد (AI)',
                          ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final Message message;
  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isMine = message.senderId == currentUserId;
    final theme = Theme.of(context);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMine ? theme.colorScheme.primary : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMine ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMine ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMine ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
