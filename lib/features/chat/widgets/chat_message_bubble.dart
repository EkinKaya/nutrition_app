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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? AppColors.primary
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: widget.isTyping
          ? _buildTypingIndicator()
          : Text(
              widget.message.text,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: widget.message.isUser ? AppColors.dark : Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.bolt,
        color: AppColors.dark,
        size: 20,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
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
                  color: Colors.white.withOpacity(0.4 + (opacity * 0.4)),
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