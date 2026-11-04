import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'receipt_list_page.dart';
import 'scan_flow.dart';
import 'settings_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = const [ReceiptListPage(), StatsPage(), SettingsPage()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => startScanFlow(context),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l.scan),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: l.tabReceipts),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), label: l.tabStats),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l.tabSettings),
        ],
      ),
    );
  }
}
