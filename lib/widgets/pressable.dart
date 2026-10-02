import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sound/sound_service.dart';
import '../providers/settings_providers.dart';

/// A tappable surface that dips slightly under the finger and plays the tap cue.
///
/// Used instead of bare `InkWell` on cards and tiles so every touch target in
/// the app reacts the same way.
class Pressable extends ConsumerStatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 24,
    this.scale = 0.965,
    this.sfx = Sfx.tap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final double scale;

  /// Set to null for a silent tap (e.g. when the action itself plays a cue).
  final Sfx? sfx;
  final String? semanticLabel;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return Semantics(
      label: widget.semanticLabel,
      button: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapUp: enabled ? (_) => _setDown(false) : null,
        onTapCancel: enabled ? () => _setDown(false) : null,
        onTap: enabled
            ? () {
                if (widget.sfx != null) ref.playSfx(widget.sfx!);
                widget.onTap?.call();
              }
            : null,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A [FilledButton] that plays the tap cue.
class SoundFilledButton extends ConsumerWidget {
  const SoundFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.sfx = Sfx.tap,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Sfx? sfx;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void handle() {
      if (sfx != null) ref.playSfx(sfx!);
      onPressed?.call();
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed == null ? null : handle,
        icon: icon!,
        label: child,
        style: style,
      );
    }
    return FilledButton(
      onPressed: onPressed == null ? null : handle,
      style: style,
      child: child,
    );
  }
}

/// An [OutlinedButton] that plays the tap cue.
class SoundOutlinedButton extends ConsumerWidget {
  const SoundOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void handle() {
      ref.playSfx(Sfx.tap);
      onPressed?.call();
    }

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed == null ? null : handle,
        icon: icon!,
        label: child,
        style: style,
      );
    }
    return OutlinedButton(
      onPressed: onPressed == null ? null : handle,
      style: style,
      child: child,
    );
  }
}
