import 'package:flutter/cupertino.dart';

class CustomLoadingIndicator extends StatefulWidget {
  const CustomLoadingIndicator({super.key});

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            return ScaleTransition(
              scale: DelayTween(begin: 0.0, end: 1.0, delay: index * 0.2)
                  .animate(_controller),
              child: SizedBox.fromSize(
                size: const Size.square(15.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  final double delay;

  DelayTween({required double begin, required double end, required this.delay})
      : super(begin: begin, end: end);

  @override
  double lerp(double t) {
    return super.lerp((t - delay).clamp(0.0, 1.0));
  }
}
