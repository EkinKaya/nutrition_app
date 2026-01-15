import 'package:flutter/material.dart';
import '../widgets/chat_message_bubble.dart';

/// Chat business logic - State management
class ChatProvider extends ChangeNotifier {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isAiTyping => _isAiTyping;

  ChatProvider() {
    _initializeChat();
  }

  void _initializeChat() {
    _messages.add(
      ChatMessage(
        text: 'Merhaba! Ben senin beslenme asistanınım. Bugün sana nasıl yardımcı olabilirim?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Kullanıcı mesajını ekle
    _messages.add(
      ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    messageController.clear();
    _isAiTyping = true;
    notifyListeners();

    _scrollToBottom();

    // Simulate AI response (gerçek API burada çağrılacak)
    Future.delayed(const Duration(seconds: 2), () {
      _messages.add(
        ChatMessage(
          text: _generateAiResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isAiTyping = false;
      notifyListeners();
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateAiResponse(String userMessage) {
    final lowerMsg = userMessage.toLowerCase();
    
    if (lowerMsg.contains('tarif') || lowerMsg.contains('yemek')) {
      return 'Harika! Size sağlıklı ve lezzetli tarifler önerebilirim. Hangi tür bir tarif arıyorsunuz?';
    } else if (lowerMsg.contains('kalori')) {
      return 'Günlük kalori ihtiyacınızı hesaplayabilirim. Yaşınız, boyunuz, kilonuz nedir?';
    } else if (lowerMsg.contains('diyet') || lowerMsg.contains('kilo')) {
      return 'Kilo verme hedefleriniz için size özel plan oluşturabilirim.';
    } else {
      return 'Anladım! Size bu konuda yardımcı olabilirim. Daha detaylı bilgi verebilir misiniz?';
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}