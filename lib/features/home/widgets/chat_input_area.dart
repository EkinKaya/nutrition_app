import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';

class ChatInputArea extends StatelessWidget {
  final ChatProvider provider;

  const ChatInputArea({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dark,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildVoiceButton(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(),
              ),
              const SizedBox(width: 12),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: provider.messageController,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Type a message...',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white.withOpacity(0.4),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: provider.sendMessage,
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: GestureDetector(
        onTap: () => provider.sendMessage(provider.messageController.text),
        child: Icon(
          Icons.arrow_upward,
          color: AppColors.dark,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.mic_none,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}