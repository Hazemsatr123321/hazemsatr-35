import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A simple data model for a chat message.
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({required this.text, required this.isUser, this.isError = false});
}

class SmartAssistantScreen extends StatefulWidget {
  const SmartAssistantScreen({super.key});

  @override
  State<SmartAssistantScreen> createState() => _SmartAssistantScreenState();
}

class _SmartAssistantScreenState extends State<SmartAssistantScreen> {
  final _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add a welcoming message from the assistant
    _messages.add(
      ChatMessage(
        text: 'مرحباً بك في المساعد الذكي! كيف يمكنني مساعدتك في تحليل السوق أو تحسين مبيعاتك اليوم؟',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = text;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
    });

    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      final response = await supabase.functions.invoke(
        'smart-assistant',
        body: {'prompt': userMessage},
      );

      if (response.status != 200) {
        throw 'فشلت الاستجابة من الخادم: ${response.data['error']}';
      }

      final aiResponse = response.data['response'];
      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
      });

    } catch (e) {
      final errorMessage = 'عذرًا، حدث خطأ أثناء التواصل مع المساعد الذكي. يرجى المحاولة مرة أخرى. الخطأ: $e';
      setState(() {
        _messages.add(ChatMessage(text: errorMessage, isUser: false, isError: true));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true, // To show latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index]; // To show reversed
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: message.isError
                          ? Colors.red.shade700
                          : message.isUser
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'اسأل عن أي شيء...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                onSubmitted: _isLoading ? null : (value) => _handleSubmitted(value),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
