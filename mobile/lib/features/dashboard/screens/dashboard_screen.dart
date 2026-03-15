import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pantry/screens/pantry_screen.dart';

/// DashboardScreen — root shell with bottom NavigationBar.
///
/// Tab 0: Dashboard / Macro Ring  (stub — full implementation is next)
/// Tab 1: Smart Pantry            (fully implemented)
/// Tab 2: SOS / CBT               (stub — WebSocket screen coming soon)
///
/// Uses IndexedStack so each tab preserves its scroll state.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    _MacroTab(),
    PantryScreen(),
    _SosTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon:       Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large_rounded),
            label:      'Dashboard',
          ),
          NavigationDestination(
            icon:       Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen_rounded),
            label:      'Pantry',
          ),
          NavigationDestination(
            icon:       Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label:      'SOS',
          ),
        ],
      ),
    );
  }
}

// ── Stub screens (replaced in next sprint) ────────────────────────────────────

class _MacroTab extends StatelessWidget {
  const _MacroTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.donut_large_rounded,
              size:  80,
              color: cs.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Dashboard',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Macro ring widget — coming next sprint',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosTab extends StatelessWidget {
  const _SosTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              size:  80,
              color: cs.error,
            ),
            const SizedBox(height: 24),
            Text('SOS / CBT', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Real-time coaching — coming soon',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
