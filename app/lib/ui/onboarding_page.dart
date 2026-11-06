/// Start screen for a new user: what the app does, in five steps, with the
/// language choice and the folder button. Reachable again from Settings.
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../budget/budget_labels.dart';
import '../l10n/app_localizations.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, this.fromSettings = false});

  /// Opened from Settings: a close button instead of "Later".
  final bool fromSettings;

  Future<void> _chooseFolder(BuildContext context) async {
    final scope = AppScope.of(context);
    final navigator = Navigator.of(context);
    final ok = await scope.budget.chooseFolder();
    if (!ok) return;
    await scope.settings.setOnboardingSeen(true);
    if (fromSettings && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, scope.budget]),
      builder: (context, _) {
        final year = scope.budget.currentYear;
        final language = languageDisplayName(scope.budget.templateLanguageCode);
        final steps = <(IconData, String, String)>[
          (Icons.folder_outlined, l.onboardingStep1Title, l.onboardingStep1Text),
          (Icons.table_chart_outlined, l.onboardingStep2Title, l.onboardingStep2Text(year, language)),
          (Icons.add_circle_outline, l.onboardingStep3Title, l.onboardingStep3Text),
          (Icons.insights_outlined, l.onboardingStep4Title, l.onboardingStep4Text),
          (Icons.key_outlined, l.onboardingStep5Title, l.onboardingStep5Text),
        ];
        return Scaffold(
          appBar: AppBar(
            leading: fromSettings ? const CloseButton() : null,
            automaticallyImplyLeading: fromSettings,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DropdownButton<String>(
                  value: settings.localeCode,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.translate_outlined),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l.languageSystem)),
                    for (final code in BudgetLabels.languages) DropdownMenuItem(value: code, child: Text(languageDisplayName(code))),
                  ],
                  onChanged: (v) => v == null ? null : settings.setLocaleCode(v),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 32,
                            decoration: BoxDecoration(color: const Color(0xFF15151A), borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: const Text(
                              'AZ',
                              style: TextStyle(color: Color(0xFFFF2E7E), fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(l.onboardingTitle, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(l.onboardingIntro, style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 20),
                      for (final (i, (icon, title, body)) in steps.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border(top: BorderSide(color: scheme.primary, width: 3)),
                                ),
                                alignment: Alignment.center,
                                child: Icon(icon, color: scheme.onPrimaryContainer, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${i + 1}. $title', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(body, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      if (!fromSettings) TextButton(onPressed: () => settings.setOnboardingSeen(true), child: Text(l.onboardingLater)),
                      const Spacer(),
                      FilledButton.icon(onPressed: () => _chooseFolder(context), icon: const Icon(Icons.folder_outlined), label: Text(settings.hasFolder ? l.changeFolder : l.chooseFolder)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
