import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum FruitSize { small, medium, large }
enum FruitAction { idle, walking, celebrating }

class FruitCharacter extends StatefulWidget {
  final FruitSize size;
  final FruitAction action;
  final bool showPlatform;

  const FruitCharacter({
    super.key,
    this.size = FruitSize.medium,
    this.action = FruitAction.idle,
    this.showPlatform = true,
  });

  @override
  State<FruitCharacter> createState() => _FruitCharacterState();
}

class _FruitCharacterState extends State<FruitCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _characterSize {
    switch (widget.size) {
      case FruitSize.small:
        return 80;
      case FruitSize.medium:
        return 120;
      case FruitSize.large:
        return 180;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Idle modda hafif zıplama, walking modda daha fazla
        final bounceOffset = widget.action == FruitAction.idle
            ? Offset(0, _bounceAnimation.value * 0.3)  // %30 daha az hareket
            : widget.action == FruitAction.walking
                ? Offset(0, _bounceAnimation.value)
                : Offset(0, _bounceAnimation.value * 1.5); // celebrating: daha fazla

        final rotationAngle = widget.action == FruitAction.idle
            ? _rotationAnimation.value * 0.5  // Hafif sallanma
            : widget.action == FruitAction.walking
                ? _rotationAnimation.value
                : _rotationAnimation.value * 1.5; // celebrating: daha fazla

        return Transform.translate(
          offset: bounceOffset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: rotationAngle,
                child: _buildFruitBody(),
              ),

              if (widget.showPlatform) ...[
                const SizedBox(height: 4),
                _buildPlatform(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFruitBody() {
    return SizedBox(
      width: _characterSize,
      height: _characterSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _characterSize * 0.75,
            height: _characterSize * 0.85,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF8A5E),
                  Color(0xFFFF6B35),
                  Color(0xFFFF5722),
                ],
              ),
              borderRadius: BorderRadius.circular(_characterSize * 0.4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: _characterSize * 0.12,
                  left: _characterSize * 0.15,
                  child: Container(
                    width: _characterSize * 0.25,
                    height: _characterSize * 0.15,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            top: 0,
            child: Container(
              width: _characterSize * 0.35,
              height: _characterSize * 0.25,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          
          Positioned(
            top: _characterSize * 0.3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEye(),
                SizedBox(width: _characterSize * 0.15),
                _buildEye(),
              ],
            ),
          ),
          
          Positioned(
            top: _characterSize * 0.52,
            child: Container(
              width: _characterSize * 0.35,
              height: _characterSize * 0.15,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(_characterSize * 0.2),
                ),
              ),
            ),
          ),
          
          Positioned(
            left: -_characterSize * 0.08,
            top: _characterSize * 0.4,
            child: _buildArm(isLeft: true),
          ),
          Positioned(
            right: -_characterSize * 0.08,
            top: _characterSize * 0.4,
            child: _buildArm(isLeft: false),
          ),
          
          Positioned(
            bottom: -_characterSize * 0.05,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFoot(),
                SizedBox(width: _characterSize * 0.15),
                _buildFoot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: _characterSize * 0.12,
      height: _characterSize * 0.12,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: _characterSize * 0.06,
          height: _characterSize * 0.06,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildArm({required bool isLeft}) {
    return Container(
      width: _characterSize * 0.15,
      height: _characterSize * 0.35,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF8A5E),
            Color(0xFFFF6B35),
          ],
        ),
        borderRadius: BorderRadius.circular(_characterSize * 0.1),
      ),
    );
  }

  Widget _buildFoot() {
    return Container(
      width: _characterSize * 0.18,
      height: _characterSize * 0.12,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF5722),
          ],
        ),
        borderRadius: BorderRadius.circular(_characterSize * 0.08),
      ),
    );
  }

  Widget _buildPlatform() {
    final platformWidth = _characterSize * 0.9;
    
    return SizedBox(
      width: platformWidth,
      height: 16,
      child: CustomPaint(
        painter: _ConcentricCirclesPainter(
          colors: AppColors.rainbowColors,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _ConcentricCirclesPainter extends CustomPainter {
  final List<Color> colors;
  final double progress;

  _ConcentricCirclesPainter({
    required this.colors,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    for (int i = 0; i < colors.length; i++) {
      final radiusRatio = 1 - (i / colors.length);
      final radius = maxRadius * radiusRatio;
      
      final paint = Paint()
        ..color = colors[i].withOpacity(0.5 + (progress * 0.3))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 0.4,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConcentricCirclesPainter oldDelegate) =>
      progress != oldDelegate.progress;
}