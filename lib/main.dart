import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/sound/sound_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'providers/settings_providers.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Both of these are loaded up front and injected as overrides so the rest
    // of the app can read them synchronously.
    final prefs = await SharedPreferences.getInstance();
    final sound = SoundService();
    // Audio is a nicety; a browser that refuses to preload it must not be the
    // reason the whole app fails to start.
    try {
      await sound.init();
    } catch (e, st) {
      debugPrint('SoundService.init failed, continuing without audio: $e\n$st');
    }

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          soundServiceProvider.overrideWithValue(sound),
        ],
        child: const SignalsApp(),
      ),
    );
  } catch (error, stack) {
    // Anything thrown before runApp() leaves a blank white page with no clue
    // as to why, so put the reason on screen instead of into the void.
    debugPrint('Startup failed: $error\n$stack');
    runApp(_StartupFailure(error: '$error', stack: '$stack'));
  }
}

/// Last-resort screen shown when the app cannot finish starting up.
class _StartupFailure extends StatelessWidget {
  const _StartupFailure({required this.error, required this.stack});

  final String error;
  final String stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Signals could not start',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SelectableText(error,
                    style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 20),
                SelectableText(stack,
                    style: const TextStyle(fontSize: 11, height: 1.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignalsApp extends ConsumerWidget {
  const SignalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Reading this once at the root applies the stored mute state to the
    // SoundService before any screen tries to play a cue.
    ref.watch(soundEnabledProvider);

    return MaterialApp.router(
      title: 'Signals',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }
}
