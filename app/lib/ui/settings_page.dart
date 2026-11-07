import 'package:flutter/material.dart';

import '../app.dart';
import '../budget/budget_labels.dart';
import '../budget/budget_service.dart';
import '../l10n/app_localizations.dart';
import '../ocr/engine_controller.dart';
import 'categories_page.dart';
import 'entry_actions.dart';
import 'onboarding_page.dart';
import 'widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final budget = scope.budget;
    final settings = scope.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: ListenableBuilder(
        listenable: Listenable.merge([budget, settings, scope.engine]),
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            children: [
              SectionTitle(l.settingsFolder),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(settings.folderName?.isNotEmpty == true ? settings.folderName! : (settings.hasFolder ? l.settingsFolder : l.folderNone)),
                subtitle: Text(settings.hasFolder ? l.folderFiles(budget.yearFiles.length) : l.chooseFolderHint),
                trailing: FilledButton.tonal(onPressed: budget.chooseFolder, child: Text(settings.hasFolder ? l.changeFolder : l.chooseFolder)),
              ),
              if (settings.hasFolder) ...[
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l.yearFile),
                  subtitle: Text(budget.year == null ? (budget.lastError ?? l.noFileLoaded) : 'Budget ${budget.year}.xlsx · ${l.categoriesCount(budget.categories.length)}'),
                  trailing: budget.currentYearMissing
                      ? FilledButton.tonal(onPressed: () => createYearFile(context, budget), child: Text(l.createYearFile(budget.currentYear)))
                      : null,
                ),
                ListTile(
                  leading: Icon(budget.state == SyncState.syncing ? Icons.sync : Icons.cloud_sync_outlined),
                  title: Text(l.syncNow),
                  subtitle: Text(settings.lastSync == null ? '–' : l.lastSync('${dateDmy(settings.lastSync!)} ${TimeOfDay.fromDateTime(settings.lastSync!).format(context)}')),
                  trailing: budget.pending.isEmpty ? null : Text(l.pendingCount(budget.pending.length)),
                  onTap: budget.sync,
                ),
                ListTile(
                  leading: Icon(Icons.link_off, color: scheme.onSurfaceVariant),
                  title: Text(l.forgetFolder),
                  onTap: budget.forgetFolder,
                ),
              ],
              if (budget.file != null) ...[
                SectionTitle(l.categories),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l.editCategories),
                  subtitle: Text('${l.categoriesCount(budget.categories.length)} · ${l.editCategoriesHint}'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CategoriesPage())),
                ),
                if (budget.fileLanguageMismatch)
                  ListTile(
                    leading: const Icon(Icons.translate_outlined),
                    title: Text(l.translateFile(languageDisplayName(budget.templateLanguageCode))),
                    subtitle: Text(l.translateFileHint(languageDisplayName(budget.file!.language), languageDisplayName(budget.templateLanguageCode))),
                    onTap: () => translateFileDialog(context, budget),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.translate_outlined),
                    title: Text(l.fileLanguage(languageDisplayName(budget.file!.language))),
                  ),
              ],
              SectionTitle(l.settingsData),
              SwitchListTile(
                secondary: const Icon(Icons.history_outlined),
                title: Text(l.backupsTitle),
                subtitle: Text(l.backupsHint),
                value: settings.backups,
                onChanged: settings.setBackups,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.photo_library_outlined),
                title: Text(l.savePhotosTitle),
                subtitle: Text(l.savePhotosHint),
                value: settings.savePhotos,
                onChanged: settings.setSavePhotos,
              ),
              ListTile(
                leading: const Icon(Icons.euro_outlined),
                title: Text(l.currencyTitle),
                subtitle: Text(settings.currencySymbol),
                onTap: () => _editText(context, title: l.currencyTitle, initial: settings.currencySymbol, onSave: settings.setCurrencySymbol),
              ),
              if (budget.file != null)
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text(l.exportCsv),
                  subtitle: Text('Budget ${budget.year}.csv'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final name = await budget.exportCsv();
                      messenger.showSnackBar(SnackBar(content: Text(l.csvExported(name))));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
                    }
                  },
                ),
              SectionTitle(l.language),
              ListTile(
                leading: const Icon(Icons.translate_outlined),
                title: Text(l.language),
                trailing: DropdownButton<String>(
                  value: settings.localeCode,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l.languageSystem)),
                    const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(value: 'ru', child: Text('Русский')),
                  ],
                  onChanged: (v) => v == null ? null : settings.setLocaleCode(v),
                ),
              ),
              SectionTitle(l.settingsOpenAi),
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text(l.openAiKey),
                subtitle: Text(settings.hasOpenAiKey ? l.openAiKeySet : l.openAiKeyNotSet),
                onTap: () => _editText(context, title: l.openAiKey, initial: '', obscure: true, onSave: settings.setOpenAiApiKey),
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: Text(l.openAiModel),
                subtitle: Text(settings.openAiModel),
                onTap: () => _editText(context, title: l.openAiModel, initial: settings.openAiModel, onSave: settings.setOpenAiModel),
              ),
              SectionTitle(l.settingsEngine),
              Builder(builder: (context) {
                final e = scope.engine;
                final (icon, text) = switch (e.state) {
                  EngineState.ready => (Icons.check_circle_outline, '${l.engineReady} · ${e.version ?? ''}'),
                  EngineState.loading => (Icons.hourglass_top, l.scanning),
                  EngineState.error => (Icons.error_outline, l.engineError(e.error ?? '')),
                  EngineState.idle => (Icons.circle_outlined, l.engineNotReady),
                };
                return ListTile(leading: Icon(icon), title: Text(l.settingsEngine), subtitle: Text(text), onTap: e.state == EngineState.error ? e.start : null);
              }),
              SectionTitle(l.settingsAbout),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l.howToUse),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OnboardingPage(fromSettings: true))),
              ),
              ListTile(leading: const Icon(Icons.info_outline), title: Text(l.appTitle), subtitle: Text(l.aboutText)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editText(BuildContext context, {required String title, required String initial, bool obscure = false, required Future<void> Function(String) onSave}) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: DialogTitle(child: Text(title)),
        content: TextField(controller: controller, autofocus: true, obscureText: obscure, autocorrect: false, enableSuggestions: false),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(l.save)),
        ],
      ),
    );
    if (value != null) await onSave(value);
  }
}
