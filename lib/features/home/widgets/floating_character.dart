import 'package:flutter/material.dart';
import '../../../shared/widgets/fruit_character.dart';

class FloatingCharacter extends StatelessWidget {
  final bool isAiTyping;

  const FloatingCharacter({
    super.key,
    required this.isAiTyping,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: FruitCharacter(
        size: FruitSize.small,
        action: isAiTyping ? FruitAction.walking : FruitAction.idle,
        showPlatform: false,
      ),
    );
  }
}