/// The entry form: category, description (autocomplete learned from the
/// file), amount, note, date. Used for manual entries, quick tiles and the
/// confirmation of a scanned receipt.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../budget/receipt_split.dart';
import '../l10n/app_localizations.dart';
import 'split_receipt_page.dart';
import 'widgets.dart';

class EntryDraft {
  EntryDraft({this.date, this.category, this.description = '', this.amount, this.note = '', this.items = const []});
  DateTime? date;
  String? category;
  String description;
  double? amount;
  String note;

  /// The receipt's items (a scan); lets the form offer a split by category.
  List<ReceiptItemDraft> items;
}

/// Shows the form; returns the entry when saved, null when dismissed.
/// [onSplit] (receipt scans) enables "split": the entries, one per
/// category, are handed to it and the sheet closes with null.
Future<BudgetEntry?> showEntrySheet(BuildContext context, {required BudgetService budget, EntryDraft? draft, String? title, Future<void> Function()? onDelete, Future<void> Function(List<BudgetEntry>)? onSplit}) {
  // Refresh in the background while the user fills the form, so the
  // duplicate check on save sees what was added on the laptop meanwhile.
  unawaited(budget.sync());
  // The sheet's own MediaQuery has no bottom padding; take the system
  // navigation bar height from the page that opened it.
  final navBar = MediaQuery.of(context).viewPadding.bottom;
  return showModalBottomSheet<BudgetEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The keyboard inset must come from the sheet's own context: the opener's
    // MediaQuery does not drive a rebuild of the sheet when the keyboard opens.
    builder: (ctx) => AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: EntryForm(budget: budget, draft: draft ?? EntryDraft(), title: title, bottomPadding: navBar, onDelete: onDelete, onSplit: onSplit),
    ),
  );
}

class EntryForm extends StatefulWidget {
  const EntryForm({super.key, required this.budget, required this.draft, this.title, this.bottomPadding = 0, this.onDelete, this.onSplit});

  /// Receives one entry per category when the user splits a receipt.
  final Future<void> Function(List<BudgetEntry>)? onSplit;

  /// When set (editing an existing entry) a delete button is shown; the
  /// callback runs after the user confirmed.
  final Future<void> Function()? onDelete;
  final BudgetService budget;
  final EntryDraft draft;
  final String? title;

  /// Extra space under the save button (system navigation bar).
  final double bottomPadding;

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  String? _category;
  final _amountFocus = FocusNode();
  final _descFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _date = d.date ?? DateTime.now();
    _date = DateTime(_date.year, _date.month, _date.day);
    _category = d.category;
    _description = TextEditingController(text: d.description);
    _amount = TextEditingController(text: d.amount == null ? '' : _fmt(d.amount!));
    _note = TextEditingController(text: d.note);
    if (_category == null) {
      final cats = widget.budget.categories;
      final byUse = widget.budget.suggestions.categoriesByUse(cats.map((c) => c.name));
      _category = byUse.isEmpty ? null : byUse.first;
    }
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _note.dispose();
    _amountFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  static String _fmt(double v) {
    final abs = v.abs();
    final s = abs == abs.roundToDouble() ? abs.toInt().toString() : abs.toStringAsFixed(2).replaceAll('.', ',');
    return s;
  }

  BudgetCategory? get _cat => _category == null ? null : widget.budget.file?.category(_category!);

  void _pickSuggestion(String description, double? amount) {
    _description.text = description;
    if (amount != null && _amount.text.trim().isEmpty) _amount.text = _fmt(amount);
    _amountFocus.requestFocus();
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEntryTitle),
        content: Text(l.deleteEntryBody('${_description.text.trim()} · ${_amount.text.trim()} €')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).pop();
    await widget.onDelete!();
  }

  Future<void> _split() async {
    final cat = _cat;
    final amount = parseAmount(_amount.text);
    if (cat == null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).entryIncomplete)));
      return;
    }
    final entries = await Navigator.of(context).push<List<BudgetEntry>>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => SplitReceiptPage(date: _date, description: _description.text.trim(), total: amount.abs(), items: widget.draft.items, main: cat.name),
    ));
    if (entries == null || !mounted) return;
    Navigator.of(context).pop();
    await widget.onSplit!(entries);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final amount = parseAmount(_amount.text);
    final cat = _cat;
    if (cat == null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.entryIncomplete)));
      return;
    }
    // The file stores income negative; the user types a plain number.
    var signed = amount.abs();
    if (cat.isIncome) signed = -signed;
    if (amount < 0 && !cat.isIncome) signed = -amount.abs(); // explicit refund on an expense category
    Navigator.of(context).pop(BudgetEntry(
      date: _date,
      category: cat.name,
      description: _description.text.trim(),
      amount: signed,
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final budget = widget.budget;
    final cats = budget.categoriesByName;
    final suggestions = _category == null
        ? const []
        : budget.suggestions.descriptions(_category!, prefix: _description.text.trim(), limit: 8);
    final top = _category == null ? const [] : budget.suggestions.descriptions(_category!, limit: 3);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + widget.bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title ?? l.newEntry, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
              TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.event_outlined, size: 18), label: Text(dateDmy(_date))),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: cats.any((c) => c.name == _category) ? _category : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.category),
            items: [
              for (final c in cats)
                DropdownMenuItem(
                  value: c.name,
                  child: Row(children: [CategoryDot(name: c.name), const SizedBox(width: 10), Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis))]),
                ),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 8),
          if (top.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in top)
                  ActionChip(
                    label: Text('${s.description} · ${euroShort(s.lastAmount)}'),
                    onPressed: () => _pickSuggestion(s.description, s.lastAmount),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            focusNode: _descFocus,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.description, suffixIcon: _description.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => _description.clear())),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _amountFocus.requestFocus(),
          ),
          if (_descFocus.hasFocus && suggestions.isNotEmpty && _description.text.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: scheme.outline)),
              child: Column(
                children: [
                  for (final s in suggestions.take(5))
                    ListTile(
                      dense: true,
                      title: Text(s.description),
                      trailing: Text(euroShort(s.lastAmount), style: TextStyle(color: scheme.onSurfaceVariant)),
                      onTap: () => _pickSuggestion(s.description, s.lastAmount),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-+*/()= ]'))],
            decoration: InputDecoration(
              labelText: l.amount,
              suffixText: '€',
              helperText: _cat?.isIncome ?? false ? l.amountIncomeHint : l.formulaHint,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.note),
            // A scanned receipt's item list can be long: grow with it.
            maxLines: 8,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: Text(l.save)),
          if (widget.onSplit != null && widget.draft.items.length > 1)
            OutlinedButton.icon(onPressed: _split, icon: const Icon(Icons.call_split), label: Text(l.splitReceipt(widget.draft.items.length))),
          if (widget.onDelete != null)
            TextButton.icon(
              onPressed: _confirmDelete,
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l.delete),
            ),
        ],
      ),
    );
  }
}
