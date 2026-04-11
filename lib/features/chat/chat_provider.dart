import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/user_service.dart';
import 'widgets/chat_message_bubble.dart';

/// Chat business logic - State management
class ChatProvider extends ChangeNotifier {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isAiTyping => _isAiTyping;

  static const _kLastChatDate = 'last_chat_date';

  ChatProvider() {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Günlük sıfırlama: önceki gün farklıysa sohbet geçmişini temizle
      try {
        final prefs = await SharedPreferences.getInstance();
        final today = _todayStr();
        final stored = prefs.getString(_kLastChatDate);
        if (stored != today) {
          GeminiService.resetChat();
          await prefs.setString(_kLastChatDate, today);
        }
      } catch (_) {
        // SharedPreferences erişilemezse sohbeti sıfırlamadan devam et
      }

      await GeminiService.startNewChat();

      // Kullanici adini al — once Firebase displayName, yoksa email prefix
      String greeting = 'Merhaba!';
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final fbDisplayName = firebaseUser?.displayName;
      if (fbDisplayName != null && fbDisplayName.isNotEmpty) {
        final name = fbDisplayName[0].toUpperCase() + fbDisplayName.substring(1);
        greeting = 'Merhaba $name!';
      } else {
        final userData = await UserService.getFullUserContext();
        if (userData != null) {
          final storedName = userData['displayName'] as String?;
          final email = userData['email'] as String?;
          if (storedName != null && storedName.isNotEmpty) {
            final name = storedName[0].toUpperCase() + storedName.substring(1);
            greeting = 'Merhaba $name!';
          } else if (email != null && email.contains('@')) {
            final namePart = email.split('@').first;
            final name = namePart[0].toUpperCase() + namePart.substring(1).toLowerCase();
            greeting = 'Merhaba $name!';
          }
        }
      }

      _messages.add(
        ChatMessage(
          text: '$greeting Ben Beslenme Arkadaşı. Beslenme, sağlık ve yemek tarifleri konusunda sana yardımcı olabilirim. Nasıl yardımcı olabilirim?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'Bağlantı kurulamadı: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

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
          text: 'Bir hata oluştu. Lütfen tekrar deneyin.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    _isAiTyping = false;
    notifyListeners();
    _scrollToBottom();
  }

  /// Sohbeti sıfırlar ve kullanıcı bilgilerini yeniden yükler
  Future<void> resetChat() async {
    _messages.clear();
    GeminiService.resetChat();
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

  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
