import 'package:flutter/material.dart';

class GlowingLogo extends StatefulWidget {
  @override
  _GlowingLogoState createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<GlowingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(
                  97,
                  56,
                  14,
                  1,
                ).withValues(alpha: _animation.value * 0.3),
                blurRadius: 40 * _animation.value,
                spreadRadius: 5 * _animation.value,
              ),
              BoxShadow(
                color: Colors.orange.withValues(alpha: _animation.value * 0.1),
                blurRadius: 30 * _animation.value,
                spreadRadius: 10 * _animation.value,
              ),
            ],
          ),
          child: Image.asset(
            'assets/sf_logo_nobg.png',
            width: 150,
            height: 150,
          ),
        );
      },
    );
  }
}
