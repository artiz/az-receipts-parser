import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AZ Budget'**
  String get appTitle;

  /// No description provided for @tabEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get tabEntries;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceipt;

  /// No description provided for @importScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Import screenshot'**
  String get importScreenshot;

  /// No description provided for @importStatement.
  ///
  /// In en, this message translates to:
  /// **'Import statement (PDF)'**
  String get importStatement;

  /// No description provided for @syncNoFolder.
  ///
  /// In en, this message translates to:
  /// **'No folder chosen'**
  String get syncNoFolder;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncSyncing;

  /// No description provided for @syncIdle.
  ///
  /// In en, this message translates to:
  /// **'Budget {year}.xlsx is up to date'**
  String syncIdle(int year);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: {count} entries waiting'**
  String syncOffline(int count);

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncError;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCount(int count);

  /// No description provided for @entryIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please choose a category and enter an amount.'**
  String get entryIncomplete;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountIncomeHint.
  ///
  /// In en, this message translates to:
  /// **'Income is stored as a negative amount automatically.'**
  String get amountIncomeHint;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmEntry.
  ///
  /// In en, this message translates to:
  /// **'Confirm entry'**
  String get confirmEntry;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {amount}'**
  String entrySaved(String amount);

  /// No description provided for @editInFile.
  ///
  /// In en, this message translates to:
  /// **'Entries already in the file are edited in the spreadsheet.'**
  String get editInFile;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @chooseFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the folder that holds your Budget <year>.xlsx files (Google Drive, Dropbox, iCloud or local).'**
  String get chooseFolderHint;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get chooseFolder;

  /// No description provided for @quickEntries.
  ///
  /// In en, this message translates to:
  /// **'Quick entries'**
  String get quickEntries;

  /// No description provided for @recentEntries.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentEntries;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String showAll(int count);

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get noEntries;

  /// No description provided for @noFileLoaded.
  ///
  /// In en, this message translates to:
  /// **'No budget file loaded.'**
  String get noFileLoaded;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @limitHint.
  ///
  /// In en, this message translates to:
  /// **'Limits {limit1} / {limit2}'**
  String limitHint(String limit1, String limit2);

  /// No description provided for @saldo.
  ///
  /// In en, this message translates to:
  /// **'Saldo (income − expenses)'**
  String get saldo;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category (actual / plan)'**
  String get byCategory;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @accountInputs.
  ///
  /// In en, this message translates to:
  /// **'Account inputs (start of month)'**
  String get accountInputs;

  /// No description provided for @settingsFolder.
  ///
  /// In en, this message translates to:
  /// **'Budget folder'**
  String get settingsFolder;

  /// No description provided for @folderNone.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get folderNone;

  /// No description provided for @folderFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no Budget <year>.xlsx found} =1{1 budget file} other{{count} budget files}}'**
  String folderFiles(int count);

  /// No description provided for @changeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeFolder;

  /// No description provided for @forgetFolder.
  ///
  /// In en, this message translates to:
  /// **'Disconnect folder'**
  String get forgetFolder;

  /// No description provided for @yearFile.
  ///
  /// In en, this message translates to:
  /// **'Year file'**
  String get yearFile;

  /// No description provided for @categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String categoriesCount(int count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync {time}'**
  String lastSync(String time);

  /// No description provided for @settingsOpenAi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI (statement import)'**
  String get settingsOpenAi;

  /// No description provided for @openAiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get openAiKey;

  /// No description provided for @openAiKeySet.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get openAiKeySet;

  /// No description provided for @openAiKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get openAiKeyNotSet;

  /// No description provided for @openAiModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get openAiModel;

  /// No description provided for @settingsEngine.
  ///
  /// In en, this message translates to:
  /// **'OCR engine (docling.rs)'**
  String get settingsEngine;

  /// No description provided for @engineReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get engineReady;

  /// No description provided for @engineNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get engineNotReady;

  /// No description provided for @engineError.
  ///
  /// In en, this message translates to:
  /// **'Engine error: {message}'**
  String engineError(String message);

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get scanning;

  /// No description provided for @scanningHint.
  ///
  /// In en, this message translates to:
  /// **'Text recognition runs on this device. This takes a few seconds.'**
  String get scanningHint;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Entries go straight into your yearly Budget spreadsheet. Only statement import talks to OpenAI, with your own key.'**
  String get aboutText;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Review import'**
  String get importTitle;

  /// No description provided for @importSelectAll.
  ///
  /// In en, this message translates to:
  /// **'All / none'**
  String get importSelectAll;

  /// No description provided for @importNoText.
  ///
  /// In en, this message translates to:
  /// **'No bookings found. For scanned PDFs take a photo of the page instead.'**
  String get importNoText;

  /// No description provided for @importFromSource.
  ///
  /// In en, this message translates to:
  /// **'From: {source}'**
  String importFromSource(String source);

  /// No description provided for @importDuplicate.
  ///
  /// In en, this message translates to:
  /// **'already booked'**
  String get importDuplicate;

  /// No description provided for @importSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped: {reason}'**
  String importSkipped(String reason);

  /// No description provided for @importNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'please check the category'**
  String get importNeedsReview;

  /// No description provided for @importApply.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String importApply(int count);

  /// No description provided for @importNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Nothing selected.'**
  String get importNothingSelected;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count} entries added'**
  String importDone(int count);

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get chooseCategory;

  /// No description provided for @importRunning.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importRunning;

  /// No description provided for @importReadingPdf.
  ///
  /// In en, this message translates to:
  /// **'Reading the PDF text layer.'**
  String get importReadingPdf;

  /// No description provided for @importLlmHint.
  ///
  /// In en, this message translates to:
  /// **'Asking {model} to turn the text into entries.'**
  String importLlmHint(String model);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {message}'**
  String importFailed(String message);

  /// No description provided for @openAiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Set your OpenAI API key in Settings first.'**
  String get openAiKeyMissing;

  /// No description provided for @sourceScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get sourceScreenshot;

  /// No description provided for @receiptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptConfirm;

  /// No description provided for @entryExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Already booked?'**
  String get entryExistsTitle;

  /// No description provided for @entryExistsBody.
  ///
  /// In en, this message translates to:
  /// **'{entry} with {amount} is already in the file. Add the receipt details to its note?'**
  String entryExistsBody(String entry, String amount);

  /// No description provided for @addAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get addAnyway;

  /// No description provided for @mergeNote.
  ///
  /// In en, this message translates to:
  /// **'Add to note'**
  String get mergeNote;

  /// No description provided for @noteMerged.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get noteMerged;

  /// No description provided for @entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get entryUpdated;

  /// No description provided for @addToEntry.
  ///
  /// In en, this message translates to:
  /// **'Add to {entry} ({amount})'**
  String addToEntry(String entry, String amount);

  /// No description provided for @addToEntryShort.
  ///
  /// In en, this message translates to:
  /// **'Add amount'**
  String get addToEntryShort;

  /// No description provided for @addAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get addAmount;

  /// No description provided for @addDetail.
  ///
  /// In en, this message translates to:
  /// **'What (goes into the note)'**
  String get addDetail;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {count} entries'**
  String searchHint(int count);

  /// No description provided for @strandedPending.
  ///
  /// In en, this message translates to:
  /// **'{count} queued entries dated {year} have no file for that year.'**
  String strandedPending(int count, int year);

  /// No description provided for @fixDate.
  ///
  /// In en, this message translates to:
  /// **'Fix date'**
  String get fixDate;

  /// No description provided for @yearFileMissing.
  ///
  /// In en, this message translates to:
  /// **'No file for {year} yet.'**
  String yearFileMissing(int year);

  /// No description provided for @createYearFile.
  ///
  /// In en, this message translates to:
  /// **'Create Budget {year}.xlsx'**
  String createYearFile(int year);

  /// No description provided for @yearFileCreated.
  ///
  /// In en, this message translates to:
  /// **'Budget {year}.xlsx created from the previous year'**
  String yearFileCreated(int year);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
