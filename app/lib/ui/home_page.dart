import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/app_localizations.dart';
import 'entries_page.dart';
import 'entry_sheet.dart';
import 'overview_page.dart';
import 'scan_flow.dart';
import 'settings_page.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  Future<void> _newEntry() async {
    final l = AppLocalizations.of(context);
    final budget = AppScope.of(context).budget;
    final entry = await showEntrySheet(context, budget: budget);
    if (entry == null) return;
    await budget.addEntry(entry);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.entrySaved(euro(entry.amount)))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final pages = [
      EntriesPage(budget: scope.budget, onOpenSettings: () => setState(() => _index = 2)),
      OverviewPage(budget: scope.budget),
      const SettingsPage(),
    ];
    return Scaffold(
      appBar: _index == 0
          ? AppBar(
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 20,
                    decoration: BoxDecoration(color: const Color(0xFF15151A), borderRadius: BorderRadius.circular(5)),
                    alignment: Alignment.center,
                    child: const Text('AZ', style: TextStyle(color: Color(0xFFFF2E7E), fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Text(l.appTitle),
                ],
              ),
              actions: [
                IconButton(tooltip: l.scanReceipt, icon: const Icon(Icons.photo_camera_outlined), onPressed: () => scanReceipt(context)),
                IconButton(tooltip: l.importScreenshot, icon: const Icon(Icons.image_outlined), onPressed: () => importScreenshot(context)),
                IconButton(tooltip: l.importStatement, icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: () => importStatement(context)),
              ],
            )
          : null,
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(onPressed: _newEntry, icon: const Icon(Icons.add), label: Text(l.newEntry))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.list_alt_outlined), selectedIcon: const Icon(Icons.list_alt), label: l.tabEntries),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: l.tabOverview),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l.tabSettings),
        ],
      ),
    );
  }
}
