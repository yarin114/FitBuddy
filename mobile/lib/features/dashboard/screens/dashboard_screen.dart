import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../pantry/screens/pantry_screen.dart';
import 'macro_tab.dart';

/// DashboardScreen — root shell with bottom NavigationBar.
///
/// Tab 0: MacroTab (calorie ring + macro pills + meal log)
/// Tab 1: Smart Pantry (fully implemented)
/// Tab 2: SOS / CBT   (stub — WebSocket screen coming soon)
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
    MacroTab(),
    PantryScreen(),
    _SosTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon:        const Icon(Icons.donut_large_outlined),
            selectedIcon: const Icon(Icons.donut_large_rounded),
            label:       AppLocalizations.of(context).tabDashboard,
          ),
          NavigationDestination(
            icon:        const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen_rounded),
            label:       AppLocalizations.of(context).tabPantry,
          ),
          NavigationDestination(
            icon:        const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label:       AppLocalizations.of(context).tabSOS,
          ),
        ],
      ),
    );
  }
}

// ── Stub screen (replaced in next sprint) ────────────────────────────────────

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
              AppLocalizations.of(context).sosComing,
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
