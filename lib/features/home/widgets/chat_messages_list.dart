import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import 'chat_message_bubble.dart';

class ChatMessagesList extends StatelessWidget {
  final ChatProvider provider;

  const ChatMessagesList({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, child) {
        if (provider.messages.isEmpty) {
          return _buildEmptyState();
        }
        
        return ListView.builder(
          controller: provider.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: provider.messages.length + (provider.isAiTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.messages.length && provider.isAiTyping) {
              return ChatMessageBubble(
                message: ChatMessage(
                  text: '',
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
                isTyping: true,
              );
            }
            
            return ChatMessageBubble(
              message: provider.messages[index],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            'Merhaba! 👋',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sağlıklı beslenme yolculuğuna başla',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
