import 'package:flutter/material.dart';

/// A fixed-size black frame that a video of any shape letterboxes into.
///
/// Lesson clips are whatever the admin uploaded — a phone recording of a sign is
/// usually portrait, a screen capture usually landscape. Sizing the frame to the
/// clip makes the page jump between lessons, and worse, a bare [AspectRatio] in
/// a [Column] gets unbounded height: a 9:16 clip then asks for `width * 1.78`
/// and overflows the bottom of the screen.
///
/// So the height is pinned first and the ratio applied inside it. A portrait
/// clip becomes a tall narrow strip centred on black; a landscape one fills the
/// width. Either way the frame is the same size.
class VideoFrame extends StatelessWidget {
  const VideoFrame({
    super.key,
    required this.height,
    required this.aspectRatio,
    required this.child,
    this.borderRadius = 22,
  });

  /// The frame's fixed height. The width is whatever the parent allows.
  final double height;

  /// The clip's own ratio, or a sensible default before it has loaded.
  final double aspectRatio;

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: Colors.black,
          // Center loosens the constraints so AspectRatio may come out smaller
          // than the frame instead of being forced to fill it.
          child: Center(
            child: AspectRatio(aspectRatio: aspectRatio, child: child),
          ),
        ),
      ),
    );
  }
}
