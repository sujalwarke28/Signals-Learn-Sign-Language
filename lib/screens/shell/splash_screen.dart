import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shown only while we're working out who (if anyone) is signed in.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.sign_language_rounded,
                  size: 48, color: scheme.onPrimary),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.07, 1.07),
                  duration: 1100.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 26),
            Text('Signals', style: Theme.of(context).textTheme.headlineMedium)
                .animate()
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Learn to sign, one lesson at a time',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
