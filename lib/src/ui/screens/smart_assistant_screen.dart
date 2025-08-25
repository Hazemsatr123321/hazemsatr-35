import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

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
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = text;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      final response = await supabase.functions.invoke(
        'smart-assistant',
        body: {'prompt': userMessage},
      );

      if (response.status != 200) {
        throw 'فشلت الاستجابة من الخادم: ${response.data?['error'] ?? 'خطأ غير معروف'}';
      }

      final aiResponse = response.data['response'];
      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
      });
    } catch (e) {
      final errorMessage = 'عذرًا، حدث خطأ أثناء التواصل مع المساعد الذكي. يرجى المحاولة مرة أخرى.';
      setState(() {
        _messages.add(ChatMessage(text: errorMessage, isUser: false, isError: true));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('المساعد الذكي'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildChatBubble(message);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CupertinoActivityIndicator(),
              ),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final theme = CupertinoTheme.of(context);
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isError
        ? CupertinoColors.destructiveRed
        : message.isUser
            ? AppTheme.goldAccent
            : AppTheme.darkSurface;
    final textColor = message.isUser ? CupertinoColors.black : AppTheme.lightTextColor;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18.0),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.textStyle.copyWith(color: textColor),
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        border: const Border(top: BorderSide(color: AppTheme.darkSurface)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _textController,
              placeholder: 'اسأل عن أي شيء...',
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AppTheme.charcoalBackground,
                borderRadius: BorderRadius.circular(24.0),
              ),
              onSubmitted: _isLoading ? null : (value) => _handleSubmitted(value),
            ),
          ),
          const SizedBox(width: 8.0),
          CupertinoButton(
            padding: const EdgeInsets.all(8.0),
            borderRadius: BorderRadius.circular(24.0),
            color: AppTheme.goldAccent,
            onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
            child: const Icon(CupertinoIcons.arrow_up, color: CupertinoColors.black),
          ),
        ],
      ),
    );
  }
}
