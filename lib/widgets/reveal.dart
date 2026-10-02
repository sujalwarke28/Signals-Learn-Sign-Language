import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Scroll-triggered entrances for long marketing-style pages.
///
/// `flutter_animate` fires on build, which is wrong for a page taller than the
/// viewport: everything below the fold would finish animating before it was
/// ever seen, and the reader would scroll into already-settled content.
///
/// Wrap the scroll view in a [RevealScope] and each section in a [Reveal].
/// The scope turns scroll notifications into a tick; the children re-check
/// their own geometry against the viewport and play once, the first time they
/// come into range.
class RevealScope extends StatefulWidget {
  const RevealScope({super.key, required this.child});

  final Widget child;

  @override
  State<RevealScope> createState() => _RevealScopeState();
}

class _RevealScopeState extends State<RevealScope> {
  final _tick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _tick.value++;
        // False: the page may still want the notification for anything else.
        return false;
      },
      child: _RevealTick(tick: _tick, child: widget.child),
    );
  }
}

/// An [InheritedNotifier] calls `didChangeDependencies` on its dependents every
/// time the notifier fires, which is exactly the hook [Reveal] needs to re-test
/// where it has ended up.
class _RevealTick extends InheritedNotifier<ValueNotifier<int>> {
  const _RevealTick({required ValueNotifier<int> tick, required super.child})
    : super(notifier: tick);

  static void watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealTick>();
}

/// Fades and lifts its child into place the first time it nears the viewport.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 20,
  });

  final Widget child;

  /// Stagger within a group. Keep these small — 40–60ms reads as one movement,
  /// anything longer reads as a queue.
  final Duration delay;

  /// How far the child travels on the way in. Small on purpose: a long slide
  /// draws attention to the animation instead of to the words.
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _RevealTick.watch(context);
    _test();
  }

  void _test() {
    if (_shown) return;
    // Geometry isn't settled during build, so the check waits for the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _shown) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final top = box.localToGlobal(Offset.zero).dy;
      // Trigger a little before the true edge, so the movement has finished by
      // the time the section is properly in view.
      if (top < MediaQuery.sizeOf(context).height * 0.90) {
        setState(() => _shown = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return widget.child
        .animate(target: _shown ? 1 : 0)
        .fadeIn(
          duration: 520.ms,
          delay: widget.delay,
          curve: Curves.easeOutCubic,
        )
        .moveY(
          begin: widget.offset,
          end: 0,
          duration: 620.ms,
          delay: widget.delay,
          // easeOutQuart decelerates harder than easeOut — it arrives rather
          // than drifts, which is what keeps this feeling sleek and not floaty.
          curve: Curves.easeOutQuart,
        );
  }
}
