import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/recipe_service.dart';
import '../../calendar/widgets/portion_dialog.dart';

// ChatMessage model
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


/// "Tarif:" satırından itibaren sadece tarif kısmını alır
String _extractRecipeContent(String text) {
  final lines = text.split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].toLowerCase().contains('tarif')) {
      return lines.sublist(i).join('\n').trim();
    }
  }
  return text;
}

String _extractTitle(String text) {
  final lines = text.split('\n');
  for (final line in lines) {
    if (line.toLowerCase().contains('tarif:')) {
      final title = line
          .replaceAll('**', '')
          .replaceAll('*', '')
          .replaceFirst(RegExp(r'[Tt]arif:\s*'), '')
          .trim();
      if (title.isNotEmpty) return title;
    }
  }
  for (final line in lines) {
    final t = line.replaceAll('**', '').replaceAll('*', '').trim();
    if (t.isNotEmpty) return t.length > 50 ? '${t.substring(0, 47)}...' : t;
  }
  return 'Tarif';
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
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

  // Tarif kitabına kaydetme için: "Tarif:" içeren mesajlar
  bool _isRecipeMessage() =>
      widget.message.text.toLowerCase().contains('tarif');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(child: _buildMessageBubble()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble() {
    // Tüm AI mesajlarında uzun basış aktif (tarif olanlar kitaba da kaydedilebilir)
    final isAiMessage = !widget.message.isUser && !widget.isTyping;

    return GestureDetector(
      onLongPress: isAiMessage ? _showRecipeActionSheet : null,
      behavior: HitTestBehavior.opaque,
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
                  color:
                      widget.message.isUser ? AppColors.dark : Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }

  void _showRecipeActionSheet() {
    final isRecipe = _isRecipeMessage();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecipeActionSheet(
        showBookOption: isRecipe,
        onSaveToBook: isRecipe
            ? () async {
                Navigator.pop(ctx);
                final recipeOnly = _extractRecipeContent(widget.message.text);
                final success = await RecipeService.saveRecipe(recipeOnly);
                messenger.showSnackBar(SnackBar(
                  content: Text(
                    success ? 'Tarif kitabına eklendi!' : 'Tarif kaydedilemedi',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                if (success) widget.onRecipeSaved?.call();
              }
            : null,
        onSaveToCalendar: () {
          Navigator.pop(ctx);
          final content = isRecipe
              ? _extractRecipeContent(widget.message.text)
              : widget.message.text;
          final name = _extractTitle(widget.message.text);
          showDialog(
            context: context,
            builder: (_) => PortionDialog(
              mealName: name,
              foodDescription: content,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.bolt, color: AppColors.dark, size: 20),
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
              final value =
                  (_typingController.value - delay).clamp(0.0, 1.0);
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

// ---------------------------------------------------------------------------
// Bottom sheet
// ---------------------------------------------------------------------------
class _RecipeActionSheet extends StatelessWidget {
  final bool showBookOption;
  final VoidCallback? onSaveToBook;
  final VoidCallback onSaveToCalendar;

  const _RecipeActionSheet({
    required this.showBookOption,
    required this.onSaveToBook,
    required this.onSaveToCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          if (showBookOption) ...[
            _ActionTile(
              icon: Icons.menu_book_rounded,
              iconColor: AppColors.primary,
              title: 'Tarif Kitabına Kaydet',
              subtitle: 'Tarifler bölümüne ekle',
              onTap: onSaveToBook!,
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withOpacity(0.06),
                indent: 20,
                endIndent: 20),
          ],
          _ActionTile(
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF7B9CFF),
            title: 'Öğün Olarak Takvime Ekle',
            subtitle: 'Besin değerlerini hesapla ve kaydet',
            onTap: onSaveToCalendar,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.2), size: 20),
          ],
        ),
      ),
    );
  }
}
