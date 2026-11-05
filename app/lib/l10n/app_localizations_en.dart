// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AZ Budget';

  @override
  String get tabEntries => 'Entries';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabSettings => 'Settings';

  @override
  String get newEntry => 'New entry';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get importScreenshot => 'Import screenshot';

  @override
  String get importStatement => 'Import statement (PDF)';

  @override
  String get syncNoFolder => 'No folder chosen';

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String syncIdle(int year) {
    return 'Budget $year.xlsx is up to date';
  }

  @override
  String syncOffline(int count) {
    return 'Offline: $count entries waiting';
  }

  @override
  String get syncError => 'Sync error';

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get entryIncomplete => 'Please choose a category and enter an amount.';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get amount => 'Amount';

  @override
  String get amountIncomeHint =>
      'Income is stored as a negative amount automatically.';

  @override
  String get note => 'Note';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmEntry => 'Confirm entry';

  @override
  String entrySaved(String amount) {
    return 'Saved: $amount';
  }

  @override
  String get editInFile =>
      'Entries already in the file are edited in the spreadsheet.';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get chooseFolderHint =>
      'Choose the folder that holds your Budget <year>.xlsx files (Google Drive, Dropbox, iCloud or local).';

  @override
  String get chooseFolder => 'Choose folder';

  @override
  String get quickEntries => 'Quick entries';

  @override
  String get recentEntries => 'Recent';

  @override
  String get showLess => 'Show less';

  @override
  String showAll(int count) {
    return 'All $count';
  }

  @override
  String get noEntries => 'No entries yet.';

  @override
  String get noFileLoaded => 'No budget file loaded.';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String limitHint(String limit1, String limit2) {
    return 'Limits $limit1 / $limit2';
  }

  @override
  String get saldo => 'Saldo (income − expenses)';

  @override
  String get byCategory => 'By category (actual / plan)';

  @override
  String get total => 'Total';

  @override
  String get accountInputs => 'Account inputs (start of month)';

  @override
  String get settingsFolder => 'Budget folder';

  @override
  String get folderNone => 'No folder';

  @override
  String folderFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budget files',
      one: '1 budget file',
      zero: 'no Budget <year>.xlsx found',
    );
    return '$_temp0';
  }

  @override
  String get changeFolder => 'Change';

  @override
  String get forgetFolder => 'Disconnect folder';

  @override
  String get yearFile => 'Year file';

  @override
  String categoriesCount(int count) {
    return '$count categories';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String lastSync(String time) {
    return 'Last sync $time';
  }

  @override
  String get settingsOpenAi => 'OpenAI (statement import)';

  @override
  String get openAiKey => 'API key';

  @override
  String get openAiKeySet => 'Stored on this device';

  @override
  String get openAiKeyNotSet => 'Not set';

  @override
  String get openAiModel => 'Model';

  @override
  String get settingsEngine => 'OCR engine (docling.rs)';

  @override
  String get engineReady => 'Ready';

  @override
  String get engineNotReady => 'Not loaded';

  @override
  String engineError(String message) {
    return 'Engine error: $message';
  }

  @override
  String get scanning => 'Reading…';

  @override
  String get scanningHint =>
      'Text recognition runs on this device. This takes a few seconds.';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutText =>
      'Entries go straight into your yearly Budget spreadsheet. Only statement import talks to OpenAI, with your own key.';

  @override
  String get importTitle => 'Review import';

  @override
  String get importSelectAll => 'All / none';

  @override
  String get importNoText =>
      'No bookings found. For scanned PDFs take a photo of the page instead.';

  @override
  String importFromSource(String source) {
    return 'From: $source';
  }

  @override
  String get importDuplicate => 'already booked';

  @override
  String importSkipped(String reason) {
    return 'skipped: $reason';
  }

  @override
  String get importNeedsReview => 'please check the category';

  @override
  String importApply(int count) {
    return 'Add $count';
  }

  @override
  String get importNothingSelected => 'Nothing selected.';

  @override
  String importDone(int count) {
    return '$count entries added';
  }

  @override
  String get chooseCategory => 'Choose category';

  @override
  String get importRunning => 'Importing…';

  @override
  String get importReadingPdf => 'Reading the PDF text layer.';

  @override
  String importLlmHint(String model) {
    return 'Asking $model to turn the text into entries.';
  }

  @override
  String importFailed(String message) {
    return 'Import failed: $message';
  }

  @override
  String get openAiKeyMissing => 'Set your OpenAI API key in Settings first.';

  @override
  String get sourceScreenshot => 'Screenshot';

  @override
  String get receiptConfirm => 'Receipt';

  @override
  String get entryExistsTitle => 'Already booked?';

  @override
  String entryExistsBody(String entry, String amount) {
    return '$entry with $amount is already in the file. Add the receipt details to its note?';
  }

  @override
  String get addAnyway => 'Add anyway';

  @override
  String get mergeNote => 'Add to note';

  @override
  String get noteMerged => 'Note updated';

  @override
  String get entryUpdated => 'Entry updated';

  @override
  String addToEntry(String entry, String amount) {
    return 'Add to $entry ($amount)';
  }

  @override
  String get addToEntryShort => 'Add amount';

  @override
  String get addAmount => 'Amount';

  @override
  String get addDetail => 'What (goes into the note)';

  @override
  String searchHint(int count) {
    return 'Search $count entries';
  }

  @override
  String strandedPending(int count, int year) {
    return '$count queued entries dated $year have no file for that year.';
  }

  @override
  String get fixDate => 'Fix date';

  @override
  String yearFileMissing(int year) {
    return 'No file for $year yet.';
  }

  @override
  String createYearFile(int year) {
    return 'Create Budget $year.xlsx';
  }

  @override
  String yearFileCreated(int year) {
    return 'Budget $year.xlsx created from the previous year';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get formulaHint => 'Sums are fine: 5+6,50 or =500+232,23';

  @override
  String importPart(int done, int total) {
    return 'Part $done of $total';
  }

  @override
  String get limitsTitle => 'Month limits';

  @override
  String get monthLimit1 => 'Monatslimit 1';

  @override
  String get monthLimit2 => 'Monatslimit 2';

  @override
  String get monthLimit1Hint => 'Expenses from here: amber + notification';

  @override
  String get monthLimit2Hint => 'Expenses from here: red + notification';

  @override
  String get limitsTap => 'Tap to set the limits';

  @override
  String get limitsSaved => 'Limits saved to the file';

  @override
  String get limitsInvalid => 'Enter two amounts, limit 2 not below limit 1.';

  @override
  String planTitle(String category, String month) {
    return 'Plan $category, $month';
  }

  @override
  String get planSaved => 'Plan saved to the file';
}
