import 'package:flutter/material.dart';

class BottomCardAnimator extends StatefulWidget {
  final Widget? child;
  const BottomCardAnimator({super.key, this.child});

  @override
  State<BottomCardAnimator> createState() => _BottomCardAnimatorState();
}

class _BottomCardAnimatorState extends State<BottomCardAnimator> {
  @override
  Widget build(BuildContext context) {
    return drawAnimationBottomCard();
  }

  Widget drawAnimationBottomCard() {
    var end = Tween(begin: Offset(0, 1), end: Offset(0, 0));
    return AnimatedSize(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (child, animation) =>
            SlideTransition(position: end.animate(animation), child: child),
        child: widget.child,
      ),
    );
  }
}
