import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

// ChatMessage modelini de buraya ekleyelim
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? recipeTitle;
  final String? recipeImage;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.recipeTitle,
    this.recipeImage,
  });
}

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isTyping;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isTyping = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            widget.message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar (sol tarafta)
          if (!widget.message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: _buildMessageBubble(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: widget.message.isUser
            ? AppColors.secondaryGradient
            : null,
        color: widget.message.isUser ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.isTyping
          ? _buildTypingIndicator()
          : Text(
              widget.message.text,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: widget.message.isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.eco_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _typingController,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_typingController.value - delay).clamp(0.0, 1.0);
              final opacity = value < 0.5 ? value * 2 : 2 - (value * 2);
              
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3 + (opacity * 0.7)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}