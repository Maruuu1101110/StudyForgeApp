import 'package:flutter/material.dart';

class AnimatedPopIcon extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedPopIcon({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<AnimatedPopIcon> createState() => _AnimatedPopIconState();
}

class _AnimatedPopIconState extends State<AnimatedPopIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}
