import 'package:flutter/material.dart';

/// A number that counts up to its value the first time it appears, and
/// animates between values after that.
///
/// A figure that simply blinks into place reads as data. One that climbs reads
/// as something you earned — which is the whole difference on a screen meant to
/// feel like it is on your side.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // Counting up is motion for its own sake; someone who has switched
    // animations off just wants the number.
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text('$value$suffix', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      // Decelerating hard means the last few digits settle rather than race,
      // which is what makes it feel deliberate instead of like a slot machine.
      curve: Curves.easeOutQuart,
      builder: (context, v, _) => Text(
        '${v.round()}$suffix',
        style: style,
        // The glyphs must not reflow as the digits change.
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
        ),
      ),
    );
  }
}
