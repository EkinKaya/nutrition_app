import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';

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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(),
              ),
              const SizedBox(width: 8),
              _buildSendButton(),
              const SizedBox(width: 8),
              _buildVoiceButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1ED),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: provider.messageController,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Mesajını yaz...',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        onSubmitted: provider.sendMessage,
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => provider.sendMessage(provider.messageController.text),
        icon: const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F1ED),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.mic_outlined, color: Color(0xFF64748B)),
      ),
    );
  }
}