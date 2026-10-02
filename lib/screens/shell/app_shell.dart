import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sound/sound_service.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/common.dart';

/// Holds the four main tabs. Bottom bar on phones, a rail once there's room —
/// the web build at desktop width gets the rail, phones never do.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _Dest(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _Dest(Icons.school_outlined, Icons.school_rounded, 'Lessons'),
    _Dest(Icons.insights_outlined, Icons.insights_rounded, 'Progress'),
    _Dest(Icons.forum_outlined, Icons.forum_rounded, 'Community'),
  ];

  void _go(WidgetRef ref, int index) {
    ref.playSfx(Sfx.tap);
    // Tapping the tab you're already on pops that branch back to its root.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => _go(ref, i),
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.6,
              leading: Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 12),
                child: Icon(Icons.sign_language_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 30),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => _go(ref, i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Dest {
  const _Dest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
