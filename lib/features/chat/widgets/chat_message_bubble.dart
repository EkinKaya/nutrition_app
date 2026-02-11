import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/recipe_service.dart';

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
  final VoidCallback? onRecipeSaved;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isTyping = false,
    this.onRecipeSaved,
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

  /// Mesajin tarif icerip icermedigini kontrol eder
  /// AI "Tarif:" iceren mesajlar gonderir
  bool _isRecipeMessage() {
    final text = widget.message.text.toLowerCase();
    return text.contains('tarif:');
  }

  Widget _buildMessageBubble() {
    final showRecipeOption = !widget.message.isUser && _isRecipeMessage();

    return GestureDetector(
      onLongPress: showRecipeOption ? () => _showSaveRecipeDialog() : null,
      child: Container(
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
      ),
    );
  }

  void _showSaveRecipeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Tarif Kaydet',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bu mesaji tarif kitabina eklemek ister misiniz?',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hayir',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await RecipeService.saveRecipe(widget.message.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Tarif kaydedildi!' : 'Tarif kaydedilemedi',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
              if (success) {
                widget.onRecipeSaved?.call();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Evet',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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