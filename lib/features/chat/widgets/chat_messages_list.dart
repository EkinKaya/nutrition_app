import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat_provider.dart';
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt,
              size: 40,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'How can I help you?',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ask me anything about nutrition and healthy eating',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
