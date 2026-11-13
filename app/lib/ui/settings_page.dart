import 'package:flutter/material.dart';

import '../app.dart';
import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../l10n/app_localizations.dart';
import '../ocr/engine_controller.dart';
import '../storage/app_settings.dart';
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
                if (budget.file != null)
                  ListTile(
                    leading: Icon(budget.fileOutdated ? Icons.upgrade : Icons.verified_outlined),
                    title: Text(l.fileVersion(budget.file!.version.toString())),
                    subtitle: Text(budget.fileOutdated ? l.fileUpdateHint(BudgetFile.currentVersion.toString(), _stepsText(l, budget.file!.migrationSteps)) : l.fileVersionCurrent),
                    trailing: budget.fileOutdated ? FilledButton.tonal(onPressed: () => _migrateFile(context, budget), child: Text(l.fileUpdate)) : null,
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
                subtitle: Text(l.backupsHint(settings.backupsKept)),
                value: settings.backups,
                onChanged: settings.setBackups,
              ),
              ListTile(
                enabled: settings.backups,
                leading: const Icon(Icons.layers_outlined),
                title: Text(l.backupsKeptTitle),
                trailing: DropdownButton<int>(
                  value: AppSettings.backupsKeptChoices.contains(settings.backupsKept) ? settings.backupsKept : null,
                  hint: Text('${settings.backupsKept}'),
                  underline: const SizedBox.shrink(),
                  items: [for (final n in AppSettings.backupsKeptChoices) DropdownMenuItem(value: n, child: Text('$n'))],
                  onChanged: settings.backups
                      ? (v) async {
                          if (v == null) return;
                          await settings.setBackupsKept(v);
                          await budget.pruneBackups(); // fewer kept: the older copies go right away
                        }
                      : null,
                ),
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
              SectionTitle(l.settingsCamera),
              SwitchListTile(
                secondary: const Icon(Icons.document_scanner_outlined),
                title: Text(l.inAppCameraTitle),
                subtitle: Text(l.inAppCameraHint),
                value: settings.inAppCamera,
                onChanged: settings.setInAppCamera,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.motion_photos_auto_outlined),
                title: Text(l.autoCaptureTitle),
                subtitle: Text(l.autoCaptureHint),
                value: settings.autoCapture,
                onChanged: settings.inAppCamera ? settings.setAutoCapture : null,
              ),
              SectionTitle(l.settingsNotifications),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(l.approachTitle),
                subtitle: Text(l.approachHint),
                value: settings.approachEnabled,
                onChanged: settings.setApproachEnabled,
              ),
              ListTile(
                enabled: settings.approachEnabled,
                leading: const Icon(Icons.speed_outlined),
                title: Text(l.approachMarginTitle),
                subtitle: Text(_marginText(l, settings.approachMargin)),
                onTap: () => _editApproachMargin(context, settings),
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

  String _stepsText(AppLocalizations l, List<MigrationStep> steps) => steps
      .map((s) => switch (s) {
            MigrationStep.rulesSheet => l.migrationRules,
            MigrationStep.styleColumn => l.migrationStyle,
            MigrationStep.limits => l.migrationLimits,
            MigrationStep.version => l.migrationVersion,
          })
      .join(', ');

  Future<void> _migrateFile(BuildContext context, BudgetService budget) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final year = budget.year;
    if (year == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: DialogTitle(child: Text(l.fileUpdateHint(BudgetFile.currentVersion.toString(), _stepsText(l, budget.file!.migrationSteps)))),
        content: Text(l.fileUpdateConfirm(year.toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.fileUpdate)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await budget.migrateFile(year: year);
      messenger.showSnackBar(SnackBar(content: Text(l.fileUpdated(BudgetFile.currentVersion.toString()))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
    }
  }

  String _marginText(AppLocalizations l, ApproachMargin m) =>
      m.byAmount ? l.approachMarginAmount(euroShort(m.amount)) : l.approachMarginPercent(euroShortPlain(m.percent));

  /// Margin dialog: percent of limit 1 or a fixed amount below it, one field.
  Future<void> _editApproachMargin(BuildContext context, AppSettings settings) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var margin = settings.approachMargin;
    final controller = TextEditingController(text: euroShortPlain(margin.byAmount ? margin.amount : margin.percent));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: DialogTitle(child: Text(l.approachMarginTitle)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.approachModePercent), icon: const Icon(Icons.percent)),
                  ButtonSegment(value: true, label: Text(l.approachModeAmount), icon: const Icon(Icons.payments_outlined)),
                ],
                selected: {margin.byAmount},
                onSelectionChanged: (sel) => setState(() {
                  // Keep what was typed for the mode we leave, show the other mode's value.
                  final typed = parseAmount(controller.text);
                  margin = margin.byAmount ? margin.copyWith(amount: typed ?? margin.amount) : margin.copyWith(percent: typed ?? margin.percent);
                  margin = margin.copyWith(byAmount: sel.first);
                  controller.text = euroShortPlain(margin.byAmount ? margin.amount : margin.percent);
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(suffixText: margin.byAmount ? moneySymbol : '%', helperText: margin.byAmount ? l.approachMarginAmount(moneySymbol) : l.approachMarginPercent('')),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final v = parseAmount(controller.text);
    final valid = v != null && (margin.byAmount ? v > 0 : v >= 1 && v <= 99);
    if (!valid) {
      messenger.showSnackBar(SnackBar(content: Text(l.approachMarginInvalid)));
      return;
    }
    await settings.setApproachMargin(margin.byAmount ? margin.copyWith(amount: v) : margin.copyWith(percent: v));
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
