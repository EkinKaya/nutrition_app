import 'package:flutter/material.dart';
import 'fruit_character.dart';

class AnimatedPageTransition extends PageRouteBuilder {
  final Widget page;
  final bool characterWalksIn;

  AnimatedPageTransition({
    required this.page,
    this.characterWalksIn = true,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
              characterWalksIn,
            );
          },
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    bool characterWalksIn,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    ));

    final characterAnimation = Tween<Offset>(
      begin: characterWalksIn
          ? const Offset(-0.3, 0.0)
          : const Offset(0.0, 0.0),
      end: characterWalksIn
          ? const Offset(0.0, 0.0)
          : const Offset(1.3, 0.0),
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    ));

    return Stack(
      children: [
        SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: characterAnimation,
            child: FruitCharacter(
              size: FruitSize.small,
              action: animation.value < 0.95
                  ? FruitAction.walking
                  : FruitAction.idle,
              showPlatform: true,
            ),
          ),
        ),
      ],
    );
  }
}

class FruitWalkTransition {
  static Route createRoute({
    required Widget destination,
    required Alignment startAlignment,
    required Alignment endAlignment,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionDuration: const Duration(milliseconds: 800),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final pathAnimation = AlignmentTween(
          begin: startAlignment,
          end: endAlignment,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ));

        return Stack(
          children: [
            FadeTransition(
              opacity: animation,
              child: child,
            ),
            
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Align(
                  alignment: pathAnimation.value,
                  child: FruitCharacter(
                    size: FruitSize.medium,
                    action: animation.value < 0.9
                        ? FruitAction.walking
                        : FruitAction.celebrating,
                    showPlatform: true,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class SimpleFadeTransition extends PageRouteBuilder {
  final Widget page;

  SimpleFadeTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}