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
        return Stack(
          alignment: Alignment.center,
          children: [
            // Positioned glow effect for the fire
            Positioned(
              top: 10, // Adjust this to position over the fire
              left: 45, // Adjust this to center over the fire
              child: Container(
                width: 60, // Adjust width to match fire width
                height: 60, // Adjust height to match fire height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(30, 40),
                  ), // Fire-like shape
                  boxShadow: [
                    // Inner bright glow
                    BoxShadow(
                      color: Colors.orange.withValues(
                        alpha: _animation.value * 0.2,
                      ),
                      blurRadius: 20 * _animation.value,
                      spreadRadius: 2 * _animation.value,
                    ),
                    // Outer warm glow
                    BoxShadow(
                      color: Color.fromRGBO(
                        97,
                        56,
                        14,
                        1,
                      ).withValues(alpha: _animation.value * 0.1),
                      blurRadius: 35 * _animation.value,
                      spreadRadius: 5 * _animation.value,
                    ),
                    // Subtle red glow
                    BoxShadow(
                      color: Colors.red.withValues(
                        alpha: _animation.value * 0.2,
                      ),
                      blurRadius: 15 * _animation.value,
                      spreadRadius: 1 * _animation.value,
                    ),
                  ],
                ),
              ),
            ),
            // Placed here to appear on top of the glow
            Image.asset('assets/sf_logo_nobg.png', width: 150, height: 150),
          ],
        );
      },
    );
  }
}
