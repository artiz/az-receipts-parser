/// Categories as the file has them: name, hint, icon and colour, edited in
/// the app and stored in the settings sheet of the year file.
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../l10n/app_localizations.dart';
import 'widgets.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final budget = AppScope.of(context).budget;
    return Scaffold(
      appBar: AppBar(title: Text(l.categories)),
      body: ListenableBuilder(
        listenable: budget,
        builder: (context, _) {
          final file = budget.file;
          if (file == null) return EmptyHint(icon: Icons.category_outlined, text: l.noFileLoaded);
          final brightness = Theme.of(context).brightness;
          return ListView.builder(
            itemCount: file.categories.length,
            itemBuilder: (context, i) {
              final c = file.categories[i];
              final color = categoryColor(c.name, brightness, hex: c.color);
              final type = switch (c.type) {
                CategoryType.expense => null,
                CategoryType.income => l.typeIncome,
                CategoryType.transfer => l.typeTransfer,
              };
              return ListTile(
                leading: _IconBadge(icon: categoryIcon(c), color: color),
                title: Text(c.name),
                subtitle: c.hint.isEmpty && type == null ? null : Text([?type, if (c.hint.isNotEmpty) c.hint].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => CategoryEditPage(category: c))),
              );
            },
          );
        },
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({super.key, required this.category});
  final BudgetCategory category;

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  late final _name = TextEditingController(text: widget.category.name);
  late final _hint = TextEditingController(text: widget.category.hint);
  late String _icon = widget.category.icon;
  late String _color = widget.category.color;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _hint.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final budget = AppScope.of(context).budget;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (name != widget.category.name && budget.categories.any((c) => c.name == name)) {
      messenger.showSnackBar(SnackBar(content: Text(l.categoryNameTaken)));
      return;
    }
    setState(() => _saving = true);
    try {
      await budget.updateCategory(widget.category, widget.category.copyWith(name: name, hint: _hint.text.trim(), icon: _icon, color: _color), year: budget.year);
      messenger.showSnackBar(SnackBar(content: Text(l.categorySaved)));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final preview = widget.category.copyWith(name: _name.text, icon: _icon, color: _color);
    final color = categoryColor(preview.name, brightness, hex: _color);
    final renamed = _name.text.trim() != widget.category.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.editCategory),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l.save)),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              _IconBadge(icon: categoryIcon(preview, _name.text), color: color),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l.categoryName),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (renamed) Padding(padding: const EdgeInsets.only(top: 6), child: Text(l.renameNote, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
          const SizedBox(height: 12),
          TextField(
            controller: _hint,
            decoration: InputDecoration(labelText: l.categoryHintLabel),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SectionTitle(l.categoryIconLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(selected: _icon.isEmpty, onTap: () => setState(() => _icon = ''), child: Text(l.autoChoice)),
              for (final e in categoryIcons.entries)
                _Choice(selected: _icon == e.key, onTap: () => setState(() => _icon = e.key), child: Icon(e.value, size: 22)),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(l.categoryColorLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(selected: _color.isEmpty, onTap: () => setState(() => _color = ''), child: Text(l.autoChoice)),
              for (final c in categoryPalette)
                _Choice(
                  selected: _color == hexOfColor(c),
                  onTap: () => setState(() => _color = hexOfColor(c)),
                  child: Container(width: 22, height: 22, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.selected, required this.onTap, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 2),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Confirm and translate the loaded year file into the app language.
Future<void> translateFileDialog(BuildContext context, BudgetService budget) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final language = budget.templateLanguageCode;
  final year = budget.year ?? budget.currentYear;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.translateFileConfirm(year, languageDisplayName(language))),
      content: Text(l.translateFileHint(languageDisplayName(budget.file?.language ?? 'de'), languageDisplayName(language))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.translate)),
      ],
    ),
  );
  if (ok != true) return;
  try {
    final n = await budget.translateFile(language, year: year);
    messenger.showSnackBar(SnackBar(content: Text(l.translateFileDone(n))));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
  }
}
