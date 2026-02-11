import 'package:flutter/material.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/user_service.dart';
import 'widgets/chat_message_bubble.dart';

/// Chat business logic - State management
class ChatProvider extends ChangeNotifier {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  bool _isInitialized = false;

  List<ChatMessage> get messages => _messages;
  bool get isAiTyping => _isAiTyping;

  ChatProvider() {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      await GeminiService.startNewChat();
      _isInitialized = true;

      // Kullanici adini al
      String greeting = 'Merhaba!';
      final userData = await UserService.getFullUserContext();
      if (userData != null) {
        final email = userData['email'] as String?;
        if (email != null && email.contains('@')) {
          // Email'den ismi cikar (ece@gmail.com -> Ece)
          final namePart = email.split('@').first;
          // Ilk harfi buyuk yap
          final name = namePart[0].toUpperCase() + namePart.substring(1).toLowerCase();
          greeting = 'Merhaba $name!';
        }
      }

      _messages.add(
        ChatMessage(
          text: '$greeting Ben Beslenme Arkadasi. Beslenme, saglik ve yemek tarifleri konusunda sana yardimci olabilirim. Nasil yardimci olabilirim?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'Baglanti kurulamadi: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Kullanici mesajini ekle
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

    // Gemini'den yanit al
    try {
      final response = await GeminiService.sendMessage(text);

      _messages.add(
        ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'Bir hata olustu. Lutfen tekrar deneyin.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    _isAiTyping = false;
    notifyListeners();
    _scrollToBottom();
  }

  /// Sohbeti sifirlar ve kullanici bilgilerini yeniden yukler
  Future<void> resetChat() async {
    _messages.clear();
    GeminiService.resetChat();
    _isInitialized = false;
    notifyListeners();
    await _initializeChat();
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

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
