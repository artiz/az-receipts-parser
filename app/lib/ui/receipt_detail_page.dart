import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../categorize/categories.dart';
import '../core/money.dart';
import '../data/database.dart';
import '../data/receipt_repository.dart';
import '../l10n/app_localizations.dart';
import '../ocr/ocr_types.dart';
import '../parser/parsed_receipt.dart';
import 'widgets.dart';

/// Create (after a scan) or edit (from the list) a receipt.
class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage.create({super.key, required this.parsed, this.imagePath, this.ocrJson}) : stored = null;

  const ReceiptDetailPage.edit({super.key, required ReceiptWithItems this.stored})
      : parsed = null,
        imagePath = null,
        ocrJson = null;

  final ParsedReceipt? parsed;
  final ReceiptWithItems? stored;
  final String? imagePath;
  final String? ocrJson;

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  late ParsedReceipt _r;
  late final String? _originalReceiptCategory;
  late final List<String?> _originalItemCategories;
  late final TextEditingController _merchant;
  late final TextEditingController _address;
  late final TextEditingController _total;
  final List<_ItemControllers> _items = [];
  bool _saving = false;

  bool get _isNew => widget.stored == null;
  String? get _imagePath => widget.imagePath ?? widget.stored?.receipt.imagePath;
  String? get _ocrJson => widget.ocrJson ?? widget.stored?.receipt.ocrJson;

  @override
  void initState() {
    super.initState();
    _r = widget.parsed ?? ReceiptRepository.toParsed(widget.stored!);
    _originalReceiptCategory = _r.categoryKey;
    _originalItemCategories = _r.items.map((i) => i.categoryKey).toList();
    _merchant = TextEditingController(text: _r.merchant ?? '');
    _address = TextEditingController(text: _r.address ?? '');
    _total = TextEditingController(text: _r.totalCents == null ? '' : formatCents(_r.totalCents!));
    for (final it in _r.items) {
      _items.add(_ItemControllers(it));
    }
  }

  @override
  void dispose() {
    _merchant.dispose();
    _address.dispose();
    _total.dispose();
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final repo = AppScope.of(context).repository;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.newReceipt : (_r.merchant ?? l.unknownMerchant)),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.delete,
              onPressed: () => _delete(context, repo),
            ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: repo.watchCategories(),
        builder: (context, snap) {
          final categories = snap.data ?? const <Category>[];
          if (categories.isEmpty) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              if (_r.warnings.isNotEmpty) _warnings(l),
              if (_imagePath != null) _photo(context),
              const SizedBox(height: 12),
              TextField(
                controller: _merchant,
                decoration: InputDecoration(labelText: l.merchant, border: const OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                decoration: InputDecoration(labelText: l.address, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_r.purchasedAt == null ? l.date : dateShort(_r.purchasedAt!, locale)),
                      onPressed: () => _pickDateTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _total,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.total,
                        suffixText: _r.currency,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<PaymentMethod>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: PaymentMethod.cash, icon: const Icon(Icons.payments_outlined), tooltip: l.paymentCash),
                        ButtonSegment(value: PaymentMethod.card, icon: const Icon(Icons.credit_card), tooltip: l.paymentCard),
                        ButtonSegment(value: PaymentMethod.unknown, icon: const Icon(Icons.help_outline), tooltip: l.paymentUnknown),
                      ],
                      selected: {_r.payment},
                      onSelectionChanged: (s) => setState(() => _r.payment = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CategoryDropdown(
                label: l.category,
                value: _r.categoryKey ?? otherCategory,
                categories: categories,
                onChanged: (v) => setState(() => _r.categoryKey = v),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(l.items, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: Text(l.addItem),
                  ),
                ],
              ),
              if (_items.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(l.noItems)),
              for (var i = 0; i < _items.length; i++) _itemCard(context, l, i, categories),
              if (_items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(l.itemsSum, style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      Text(money(_itemsSum(), _r.currency, locale), style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
              if (_r.vat.isNotEmpty) _vatTable(l, locale),
              if (_r.qrText != null) _qrInfo(l),
              if (_ocrJson != null) _rawText(l),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _save(context, repo),
            icon: const Icon(Icons.save_outlined),
            label: Text(l.save),
          ),
        ),
      ),
    );
  }

  Widget _warnings(AppLocalizations l) {
    String label(String w) {
      if (w == 'total_missing') return l.warningTotalMissing;
      if (w == 'total_guessed') return l.warningTotalGuessed;
      if (w == 'date_missing') return l.warningDateMissing;
      if (w.startsWith('items_sum_mismatch')) return l.warningItemsMismatch;
      if (w.startsWith('total_ocr_mismatch')) return l.warningTotalMismatch;
      return w;
    }

    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.warnings, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [for (final w in _r.warnings) Chip(label: Text(label(w)))]),
          ],
        ),
      ),
    );
  }

  Widget _photo(BuildContext context) {
    final file = File(_imagePath!);
    if (!file.existsSync()) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: InteractiveViewer(maxScale: 6, child: Center(child: Image.file(file))),
        ),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 160, width: double.infinity, child: Image.file(file, fit: BoxFit.cover, alignment: Alignment.topCenter)),
      ),
    );
  }

  Widget _itemCard(BuildContext context, AppLocalizations l, int i, List<Category> categories) {
    final c = _items[i];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c.name,
                    decoration: InputDecoration(labelText: l.item, isDense: true, border: const OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _items.removeAt(i).dispose();
                    _r.items.removeAt(i);
                    _originalItemCategories.length > i ? _originalItemCategories.removeAt(i) : null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: c.quantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.quantity, isDense: true, border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: c.price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(labelText: l.price, isDense: true, border: const OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CategoryDropdown(
                    dense: true,
                    value: _r.items[i].categoryKey ?? otherCategory,
                    categories: categories,
                    onChanged: (v) => setState(() => _r.items[i].categoryKey = v),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vatTable(AppLocalizations l, Locale locale) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.vat, style: Theme.of(context).textTheme.titleMedium),
          for (final v in _r.vat)
            Row(
              children: [
                Text('${v.rate.toStringAsFixed(v.rate == v.rate.roundToDouble() ? 0 : 2)} %'),
                const Spacer(),
                if (v.netCents != null) Text('${l.vat}: ${money(v.vatCents ?? 0, _r.currency, locale)}  '),
                Text(v.grossCents == null ? '' : money(v.grossCents!, _r.currency, locale)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _qrInfo(AppLocalizations l) {
    return ExpansionTile(
      title: Text(l.qrCode),
      subtitle: _r.rksvKassenId != null ? Text('${_r.rksvKassenId} · ${_r.rksvBelegNummer}') : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SelectableText(_r.qrText!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
      ],
    );
  }

  Widget _rawText(AppLocalizations l) {
    String text;
    try {
      final map = jsonDecode(_ocrJson!) as Map<String, dynamic>;
      final result = OcrResult.fromJson(map);
      text = result.lines.map((e) => e.text).join('\n');
    } catch (_) {
      text = '';
    }
    return ExpansionTile(
      title: Text(l.rawText),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
      ],
    );
  }

  void _addItem() {
    final item = ParsedItem(name: '', totalCents: 0, categoryKey: _r.categoryKey ?? otherCategory);
    setState(() {
      _r.items.add(item);
      _items.add(_ItemControllers(item));
      _originalItemCategories.add(null);
    });
  }

  int _itemsSum() {
    var sum = 0;
    for (final c in _items) {
      sum += parseCents(c.price.text) ?? 0;
    }
    return sum;
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = _r.purchasedAt ?? DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d == null || !context.mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    setState(() {
      _r.purchasedAt = DateTime(d.year, d.month, d.day, t?.hour ?? now.hour, t?.minute ?? now.minute);
    });
  }

  void _collect() {
    _r.merchant = _merchant.text.trim().isEmpty ? null : _merchant.text.trim();
    _r.address = _address.text.trim().isEmpty ? null : _address.text.trim();
    _r.totalCents = parseCents(_total.text);
    for (var i = 0; i < _items.length; i++) {
      final c = _items[i];
      final it = _r.items[i];
      it.name = c.name.text.trim();
      it.quantity = double.tryParse(c.quantity.text.replaceAll(',', '.')) ?? 1;
      it.totalCents = parseCents(c.price.text) ?? 0;
    }
    _r.items.removeWhere((it) => it.name.isEmpty && it.totalCents == 0);
    _r.warnings.removeWhere((w) => w.startsWith('items_sum') || w.startsWith('total_'));
  }

  Future<void> _save(BuildContext context, ReceiptRepository repo) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    _collect();
    // Learn from user corrections.
    if (_r.categoryKey != null && _r.categoryKey != _originalReceiptCategory && (_r.merchant ?? '').isNotEmpty) {
      await repo.learnMerchantCategory(_r.merchant!, _r.categoryKey!);
    }
    for (var i = 0; i < _r.items.length; i++) {
      final it = _r.items[i];
      final original = i < _originalItemCategories.length ? _originalItemCategories[i] : null;
      if (it.categoryKey != null && original != null && it.categoryKey != original && it.name.isNotEmpty) {
        await repo.learnItemCategory(it.name, it.categoryKey!);
      }
    }
    if (_isNew) {
      await repo.saveParsed(_r, imagePath: _imagePath, ocrJson: _ocrJson);
    } else {
      await repo.updateFromParsed(widget.stored!.receipt.id, _r);
    }
    messenger.showSnackBar(SnackBar(content: Text(l.receiptSaved)));
    navigator.pop();
  }

  Future<void> _delete(BuildContext context, ReceiptRepository repo) async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteReceiptQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await repo.deleteReceipt(widget.stored!.receipt.id);
    final path = widget.stored!.receipt.imagePath;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    navigator.pop();
  }
}

class _ItemControllers {
  _ItemControllers(ParsedItem it)
      : name = TextEditingController(text: it.name),
        quantity = TextEditingController(text: it.quantity == it.quantity.roundToDouble() ? it.quantity.toInt().toString() : it.quantity.toString()),
        price = TextEditingController(text: formatCents(it.totalCents));
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    quantity.dispose();
    price.dispose();
  }
}
