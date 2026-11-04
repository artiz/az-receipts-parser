import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../categorize/categories.dart';
import '../categorize/categorizer.dart';
import '../data/database.dart';
import '../data/receipt_repository.dart';
import '../l10n/app_localizations.dart';
import '../ocr/engine_controller.dart';
import 'widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final repo = scope.repository;
    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: ListView(
        children: [
          ListenableBuilder(
            listenable: scope.engine,
            builder: (context, _) {
              final e = scope.engine;
              final (icon, text) = switch (e.state) {
                EngineState.ready => (Icons.check_circle_outline, '${l.engineReady} · ${e.version ?? ''}'),
                EngineState.loading => (Icons.hourglass_top, l.scanning),
                EngineState.error => (Icons.error_outline, l.engineError(e.error ?? '')),
                EngineState.idle => (Icons.circle_outlined, l.engineNotReady),
              };
              return ListTile(
                leading: Icon(icon),
                title: Text(l.settingsEngine),
                subtitle: Text(text),
                onTap: e.state == EngineState.error ? () => e.start() : null,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l.settingsCategories),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CategoriesPage())),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(l.settingsMerchantRules),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RulesPage(merchant: true))),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l.settingsKeywordRules),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RulesPage(merchant: false))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l.settingsExportCsv),
            onTap: () => _share(context, 'receipts.csv', repo.exportCsv),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: Text(l.settingsExportJson),
            onTap: () => _share(context, 'receipts.json', repo.exportJson),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l.settingsBackup),
            onTap: () => _backup(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l.settingsAbout),
            subtitle: Text(l.privacyNote),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, String name, Future<String> Function() build) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final content = await build();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: name));
    messenger.showSnackBar(SnackBar(content: Text(l.exportDone)));
  }

  Future<void> _backup(BuildContext context) async {
    final support = await getApplicationSupportDirectory();
    final db = File(p.join(support.path, 'az_receipts.sqlite'));
    if (!db.existsSync()) return;
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final copy = await db.copy(p.join(dir.path, 'az_receipts_$stamp.sqlite'));
    await SharePlus.instance.share(ShareParams(files: [XFile(copy.path)], subject: 'az_receipts backup'));
  }
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = AppScope.of(context).repository;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsCategories)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, repo),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Category>>(
        stream: repo.watchCategories(),
        builder: (context, snap) {
          final cats = snap.data ?? const <Category>[];
          return ListView(
            children: [
              for (final c in cats)
                ListTile(
                  leading: CategoryAvatar(categoryKey: c.key, radius: 16),
                  title: Text(localizedCategoryName(l, c.key, categories: cats)),
                  subtitle: Text(c.builtin ? l.seedRule : c.key),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, ReceiptRepository repo) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addCategory),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: l.categoryName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l.save)),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final key = 'custom_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${DateTime.now().millisecondsSinceEpoch % 100000}';
    await repo.addCustomCategory(key, name);
  }
}

class RulesPage extends StatelessWidget {
  const RulesPage({super.key, required this.merchant});
  final bool merchant;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = AppScope.of(context).repository;
    return Scaffold(
      appBar: AppBar(title: Text(merchant ? l.settingsMerchantRules : l.settingsKeywordRules)),
      body: StreamBuilder<List<Category>>(
        stream: repo.watchCategories(),
        builder: (context, catSnap) {
          final cats = catSnap.data ?? const <Category>[];
          return StreamBuilder<List<_RuleRow>>(
            stream: merchant
                ? repo.watchMerchantRules().map((rs) => [for (final r in rs) _RuleRow(r.pattern, r.categoryKey, r.source)])
                : repo.watchKeywordRules().map((rs) => [for (final r in rs) _RuleRow(r.keyword, r.categoryKey, r.source)]),
            builder: (context, snap) {
              final rules = [...(snap.data ?? const <_RuleRow>[])]
                ..sort((a, b) {
                  if (a.source != b.source) return a.source == RuleSource.learned ? -1 : 1;
                  return a.text.compareTo(b.text);
                });
              if (rules.isEmpty) return Center(child: Text(l.noRules));
              return ListView.builder(
                itemCount: rules.length,
                itemBuilder: (context, i) {
                  final r = rules[i];
                  return Dismissible(
                    key: ValueKey('${merchant ? 'm' : 'k'}:${r.text}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) async {
                      if (merchant) {
                        await repo.deleteMerchantRule(r.text);
                      } else {
                        await repo.deleteKeywordRule(r.text);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.ruleDeleted)));
                      }
                    },
                    child: ListTile(
                      leading: Icon(categoryDef(r.categoryKey).icon, color: categoryDef(r.categoryKey).color),
                      title: Text(r.text),
                      subtitle: Text('${localizedCategoryName(l, r.categoryKey, categories: cats)} · ${r.source == RuleSource.learned ? l.learnedRule : l.seedRule}'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RuleRow {
  _RuleRow(this.text, this.categoryKey, this.source);
  final String text;
  final String categoryKey;
  final RuleSource source;
}
