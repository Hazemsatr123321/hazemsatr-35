import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/message_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final ChatRepository chatRepository;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.chatRepository,
    this.initialMessage,
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
    if (widget.initialMessage != null) {
      _sendInitialMessage();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _sendInitialMessage() async {
    if (widget.initialMessage == null || widget.initialMessage!.trim().isEmpty) {
      return;
    }
    try {
      await widget.chatRepository.sendMessage(widget.roomId, widget.initialMessage!);
    } catch (error) {
      // Handle error silently for initial message
      debugPrint('Error sending initial message: $error');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    try {
      await widget.chatRepository.sendMessage(widget.roomId, _messageController.text.trim());
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        _showErrorDialog('خطأ في إرسال الرسالة.');
      }
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
        _showErrorDialog('حدث خطأ أثناء جلب الاقتراح.');
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('المحادثة'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
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
                        child: Container(
                          decoration: BoxDecoration(
                             color: isMine ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: isMine ? CupertinoColors.white : CupertinoColors.black,
                            ),
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
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          _isGeneratingSuggestion
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CupertinoActivityIndicator(),
                  ),
                )
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.sparkles),
                  onPressed: _getAiSuggestion,
                ),
          Expanded(
            child: CupertinoTextField(
              controller: _messageController,
              placeholder: 'اكتب رسالتك...',
               decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.arrow_up_circle_fill),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
