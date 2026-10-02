import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sound/sound_service.dart';
import 'app_providers.dart';

const _kThemeModeKey = 'settings.themeMode';
const _kSoundKey = 'settings.soundEnabled';

/// Light / dark / follow-system, persisted locally.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_kThemeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_kThemeModeKey, mode.name);
  }

  /// What the toggle button does: cycles system -> light -> dark -> system.
  Future<void> cycle() => set(switch (state) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      });
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Master switch for the interaction sounds.
class SoundEnabledController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = prefs.getBool(_kSoundKey) ?? true;
    ref.read(soundServiceProvider).enabled = enabled;
    return enabled;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    ref.read(soundServiceProvider).enabled = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_kSoundKey, enabled);
    // Confirm the change audibly when switching on.
    if (enabled) ref.read(soundServiceProvider).play(Sfx.tap);
  }

  Future<void> toggle() => set(!state);
}

final soundEnabledProvider =
    NotifierProvider<SoundEnabledController, bool>(SoundEnabledController.new);

/// Convenience for widgets: plays a cue, honouring the master switch.
extension SfxRef on Ref {
  void playSfx(Sfx sfx) => read(soundServiceProvider).play(sfx);
}

extension SfxWidgetRef on WidgetRef {
  void playSfx(Sfx sfx) {
    if (!read(soundEnabledProvider)) return;
    read(soundServiceProvider).play(sfx);
  }
}
