/// Saving, editing and topping up entries, shared by the home screen, the
/// quick tiles and the receipt scan.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../l10n/app_localizations.dart';
import 'entry_sheet.dart';
import 'widgets.dart';

/// Save a new entry. When an existing booking has the same amount within a
/// few days (typed by hand, now scanned), ask: merge the note into it, add
/// anyway, or cancel.
Future<bool> saveNewEntry(BuildContext context, BudgetService budget, BudgetEntry entry) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  // The booking may have been typed on the laptop since the last sync:
  // re-read the file before looking for it (a no-op when offline).
  try {
    await budget.sync();
  } catch (_) {}
  if (!context.mounted) return false;
  final similar = budget.findSimilar(entry);
  if (similar != null) {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.entryExistsTitle),
        content: Text(l.entryExistsBody('${dateDm(similar.date)} ${similar.description.isEmpty ? similar.category : similar.description}', euro(similar.amount))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, 'add'), child: Text(l.addAnyway)),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: Text(l.mergeNote)),
        ],
      ),
    );
    if (choice == null) return false;
    if (choice == 'merge') {
      final extra = [if (entry.note.isNotEmpty) entry.note, if (entry.description.isNotEmpty && entry.description != similar.description) entry.description].join('; ');
      await budget.appendNote(similar, extra);
      messenger.showSnackBar(SnackBar(content: Text(l.noteMerged)));
      return true;
    }
  }
  await budget.addEntry(entry);
  messenger.showSnackBar(SnackBar(content: Text(l.entrySaved(euro(entry.amount)))));
  return true;
}

/// Open the form for an existing entry (queued or in the file) and write
/// the change through.
Future<void> editEntry(BuildContext context, BudgetService budget, BudgetEntry e) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final updated = await showEntrySheet(
    context,
    budget: budget,
    title: l.editEntry,
    draft: EntryDraft(date: e.date, category: e.category, description: e.description, amount: e.amount.abs(), note: e.note),
  );
  if (updated == null) return;
  try {
    await budget.updateEntry(e, updated);
    messenger.showSnackBar(SnackBar(content: Text(l.entryUpdated)));
  } catch (err) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(err.toString()))));
  }
}

/// "+ 6 Glühwein": a small dialog that raises the amount and appends the
/// detail to the note.
Future<void> addToEntryDialog(BuildContext context, BudgetService budget, BudgetEntry e) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final amount = TextEditingController();
  final detail = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.addToEntry(e.description.isEmpty ? e.category : e.description, euro(e.amount))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(labelText: l.addAmount, suffixText: '€'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: detail,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.addDetail),
            onSubmitted: (_) => Navigator.pop(ctx, true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
      ],
    ),
  );
  if (ok != true) return;
  final v = parseAmount(amount.text);
  if (v == null || v == 0) return;
  try {
    await budget.addToEntry(e, v, detail.text);
    messenger.showSnackBar(SnackBar(content: Text(l.entryUpdated)));
  } catch (err) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(err.toString()))));
  }
}
