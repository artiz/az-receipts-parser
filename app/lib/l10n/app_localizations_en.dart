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
  String get newEntry => 'Entry';

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

  @override
  String allBookings(int count) {
    return 'All $count bookings';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteEntryTitle => 'Delete entry?';

  @override
  String deleteEntryBody(String entry) {
    return '$entry will be removed from the file.';
  }

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get onboardingTitle => 'Welcome to AZ Budget';

  @override
  String get onboardingIntro =>
      'Your budget is one spreadsheet per year in a folder you choose. The app writes into it, and you can open it in Excel or Google Sheets at any time.';

  @override
  String get onboardingStep1Title => 'Choose a folder';

  @override
  String get onboardingStep1Text =>
      'Google Drive, Dropbox, iCloud or a local folder. This is where Budget <year>.xlsx lives and syncs.';

  @override
  String get onboardingStep2Title => 'The year file';

  @override
  String onboardingStep2Text(int year, String language) {
    return 'An empty folder gets a Budget $year.xlsx in $language, with categories, plan and limits you can change. Existing files are used as they are.';
  }

  @override
  String get onboardingStep3Title => 'Add entries';

  @override
  String get onboardingStep3Text =>
      'Tap + for an entry. Quick entries repeat frequent ones, the camera scans a receipt, the PDF button imports a bank statement.';

  @override
  String get onboardingStep4Title => 'Overview and limits';

  @override
  String get onboardingStep4Text =>
      'Income, expenses and plan per category per month, plus your account inputs. Month limits give a traffic light and a notification.';

  @override
  String get onboardingStep5Title => 'Optional: OpenAI key';

  @override
  String get onboardingStep5Text =>
      'Only used for merchants the file has never seen and for screenshots. Everything else works offline.';

  @override
  String get onboardingLater => 'Later';

  @override
  String get howToUse => 'How to use the app';

  @override
  String fileCreatedNotice(int year, String language) {
    return 'Budget $year.xlsx was created in your folder ($language). Categories, plan and limits can be changed in Overview or in the file.';
  }

  @override
  String get gotIt => 'Got it';

  @override
  String get templateLanguage => 'Language of the new file';

  @override
  String get categories => 'Categories';

  @override
  String get editCategories => 'Edit categories';

  @override
  String get editCategoriesHint =>
      'Name, icon, colour and hint, stored in the file';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryHintLabel => 'Hint';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryColorLabel => 'Colour';

  @override
  String get autoChoice => 'Automatic';

  @override
  String get renameNote =>
      'Renaming also renames the bookings and the overview rows of this year\'s file.';

  @override
  String get categorySaved => 'Category saved';

  @override
  String get categoryNameTaken => 'A category with this name exists already.';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String translateFile(String language) {
    return 'Translate file to $language';
  }

  @override
  String translateFileHint(String fileLanguage, String appLanguage) {
    return 'File: $fileLanguage · App: $appLanguage. Categories, hints and labels are translated, bookings renamed; sheet names stay.';
  }

  @override
  String translateFileConfirm(int year, String language) {
    return 'Translate Budget $year.xlsx to $language?';
  }

  @override
  String translateFileDone(int count) {
    return '$count cells translated';
  }

  @override
  String get translate => 'Translate';

  @override
  String fileLanguage(String language) {
    return 'File language: $language';
  }

  @override
  String get chartHint =>
      'Plan in grey, actual in the category colour. Tap a bar.';

  @override
  String get actual => 'Actual';

  @override
  String get planLabel => 'Plan';

  @override
  String get addCategory => 'Add category';

  @override
  String get categoryType => 'Type';

  @override
  String get typeChangeNote =>
      'Changing the type rebuilds the income and expense rows of the overview sheet.';

  @override
  String get newExpenseNote =>
      'A new expense category gets no row of its own in the overview sheet\'s actual/plan blocks; the app counts it anyway.';

  @override
  String get categoryAdded => 'Category added';

  @override
  String get sourceShared => 'Shared';

  @override
  String get shareNoFolder =>
      'Choose the budget folder first, then share the receipt again.';

  @override
  String shareUnsupported(String name) {
    return 'Cannot use \"$name\": share a PDF, an image or text.';
  }

  @override
  String splitReceipt(int count) {
    return 'Split by category ($count items)';
  }

  @override
  String get splitTitle => 'Split receipt';

  @override
  String splitSave(int count) {
    return 'Save $count bookings';
  }

  @override
  String forecastHint(String amount, int day) {
    return 'Pace: about $amount this month, limit 1 on day $day.';
  }

  @override
  String forecastHintOk(String amount) {
    return 'Pace: about $amount this month.';
  }

  @override
  String get saveAsRule => 'Save as rule';

  @override
  String ruleSaved(String pattern, String category) {
    return 'Rule saved: \"$pattern\" → $category';
  }

  @override
  String get settingsData => 'Data';

  @override
  String get backupsTitle => 'Backups before each write';

  @override
  String get backupsHint => '.backup/ in the budget folder, newest five kept';

  @override
  String get savePhotosTitle => 'Keep receipt files';

  @override
  String get savePhotosHint =>
      'Belege/<year>/ in the budget folder, linked from the note';

  @override
  String get currencyTitle => 'Currency symbol';

  @override
  String get exportCsv => 'Export bookings as CSV';

  @override
  String csvExported(String name) {
    return '$name written to the folder';
  }

  @override
  String get shareMonth => 'Share month';

  @override
  String summaryTitle(String month) {
    return 'AZ Budget · $month';
  }

  @override
  String get summaryIncome => 'Income';

  @override
  String get summaryExpenses => 'Expenses';

  @override
  String get summaryTop => 'Largest categories';

  @override
  String receiptLink(String path) {
    return 'Receipt: $path';
  }
}
