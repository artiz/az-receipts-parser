// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'AZ Budget';

  @override
  String get tabEntries => 'Buchungen';

  @override
  String get tabOverview => 'Übersicht';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get newEntry => 'Buchung';

  @override
  String get scanReceipt => 'Beleg scannen';

  @override
  String get importScreenshot => 'Screenshot importieren';

  @override
  String get importStatement => 'Kontoauszug (PDF) importieren';

  @override
  String get syncNoFolder => 'Kein Ordner gewählt';

  @override
  String get syncSyncing => 'Synchronisiere…';

  @override
  String syncIdle(int year) {
    return 'Budget $year.xlsx ist aktuell';
  }

  @override
  String syncOffline(int count) {
    return 'Offline: $count Buchungen warten';
  }

  @override
  String get syncError => 'Fehler beim Synchronisieren';

  @override
  String pendingCount(int count) {
    return '$count ausstehend';
  }

  @override
  String get entryIncomplete => 'Bitte Kategorie wählen und Betrag eingeben.';

  @override
  String get category => 'Kategorie';

  @override
  String get description => 'Beschreibung';

  @override
  String get amount => 'Betrag';

  @override
  String get amountIncomeHint =>
      'Einnahmen werden automatisch negativ gespeichert.';

  @override
  String get note => 'Notiz';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirmEntry => 'Buchung bestätigen';

  @override
  String entrySaved(String amount) {
    return 'Gespeichert: $amount';
  }

  @override
  String get editInFile =>
      'Buchungen, die schon in der Datei sind, werden in der Tabelle bearbeitet.';

  @override
  String get editEntry => 'Buchung bearbeiten';

  @override
  String get chooseFolderHint =>
      'Wähle den Ordner mit deinen Budget <Jahr>.xlsx-Dateien (Google Drive, Dropbox, iCloud oder lokal).';

  @override
  String get chooseFolder => 'Ordner wählen';

  @override
  String get quickEntries => 'Schnellbuchungen';

  @override
  String get recentEntries => 'Zuletzt';

  @override
  String get showLess => 'Weniger';

  @override
  String showAll(int count) {
    return 'Alle $count';
  }

  @override
  String get noEntries => 'Noch keine Buchungen.';

  @override
  String get noFileLoaded => 'Keine Budget-Datei geladen.';

  @override
  String get income => 'Einnahmen';

  @override
  String get expenses => 'Ausgaben';

  @override
  String limitHint(String limit1, String limit2) {
    return 'Limits $limit1 / $limit2';
  }

  @override
  String get saldo => 'Saldo (Einnahmen − Ausgaben)';

  @override
  String get byCategory => 'Nach Kategorie (Ist / Plan)';

  @override
  String get total => 'Summe';

  @override
  String get accountInputs => 'Konto-Eingaben (Monatsanfang)';

  @override
  String get settingsFolder => 'Budget-Ordner';

  @override
  String get folderNone => 'Kein Ordner';

  @override
  String folderFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Budget-Dateien',
      one: '1 Budget-Datei',
      zero: 'keine Budget <Jahr>.xlsx gefunden',
    );
    return '$_temp0';
  }

  @override
  String get changeFolder => 'Ändern';

  @override
  String get forgetFolder => 'Ordner trennen';

  @override
  String get yearFile => 'Jahresdatei';

  @override
  String categoriesCount(int count) {
    return '$count Kategorien';
  }

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String lastSync(String time) {
    return 'Zuletzt $time';
  }

  @override
  String get settingsOpenAi => 'OpenAI (Auszug-Import)';

  @override
  String get openAiKey => 'API-Schlüssel';

  @override
  String get openAiKeySet => 'Auf diesem Gerät gespeichert';

  @override
  String get openAiKeyNotSet => 'Nicht gesetzt';

  @override
  String get openAiModel => 'Modell';

  @override
  String get settingsEngine => 'OCR-Engine (docling.rs)';

  @override
  String get engineReady => 'Bereit';

  @override
  String get engineNotReady => 'Nicht geladen';

  @override
  String engineError(String message) {
    return 'Engine-Fehler: $message';
  }

  @override
  String get scanning => 'Wird gelesen…';

  @override
  String get scanningHint =>
      'Die Texterkennung läuft auf diesem Gerät. Das dauert ein paar Sekunden.';

  @override
  String get settingsAbout => 'Über';

  @override
  String get aboutText =>
      'Buchungen landen direkt in der Jahres-Tabelle. Nur der Auszug-Import spricht mit OpenAI, mit deinem eigenen Schlüssel.';

  @override
  String get importTitle => 'Import prüfen';

  @override
  String get importSelectAll => 'Alle / keine';

  @override
  String get importNoText =>
      'Keine Buchungen gefunden. Bei gescannten PDFs stattdessen die Seite fotografieren.';

  @override
  String importFromSource(String source) {
    return 'Quelle: $source';
  }

  @override
  String get importDuplicate => 'schon gebucht';

  @override
  String importSkipped(String reason) {
    return 'übersprungen: $reason';
  }

  @override
  String get importNeedsReview => 'bitte Kategorie prüfen';

  @override
  String importApply(int count) {
    return '$count übernehmen';
  }

  @override
  String get importNothingSelected => 'Nichts ausgewählt.';

  @override
  String importDone(int count) {
    return '$count Buchungen übernommen';
  }

  @override
  String get chooseCategory => 'Kategorie wählen';

  @override
  String get importRunning => 'Importiere…';

  @override
  String get importReadingPdf => 'Textebene des PDFs wird gelesen.';

  @override
  String importLlmHint(String model) {
    return '$model macht aus dem Text Buchungen.';
  }

  @override
  String importFailed(String message) {
    return 'Import fehlgeschlagen: $message';
  }

  @override
  String get openAiKeyMissing =>
      'Zuerst den OpenAI-API-Schlüssel in den Einstellungen eintragen.';

  @override
  String get sourceScreenshot => 'Screenshot';

  @override
  String get receiptConfirm => 'Beleg';

  @override
  String get entryExistsTitle => 'Schon gebucht?';

  @override
  String entryExistsBody(String entry, String amount) {
    return '$entry mit $amount steht schon in der Datei. Die Belegdetails in die Notiz übernehmen?';
  }

  @override
  String get addAnyway => 'Trotzdem anlegen';

  @override
  String get mergeNote => 'In Notiz übernehmen';

  @override
  String get noteMerged => 'Notiz ergänzt';

  @override
  String get entryUpdated => 'Buchung aktualisiert';

  @override
  String addToEntry(String entry, String amount) {
    return 'Zu $entry ($amount) dazu';
  }

  @override
  String get addToEntryShort => 'Betrag dazu';

  @override
  String get addAmount => 'Betrag';

  @override
  String get addDetail => 'Wofür (kommt in die Notiz)';

  @override
  String searchHint(int count) {
    return '$count Buchungen durchsuchen';
  }

  @override
  String strandedPending(int count, int year) {
    return '$count wartende Buchungen mit Datum $year haben keine Datei für dieses Jahr.';
  }

  @override
  String get fixDate => 'Datum korrigieren';

  @override
  String yearFileMissing(int year) {
    return 'Für $year gibt es noch keine Datei.';
  }

  @override
  String createYearFile(int year) {
    return 'Budget $year.xlsx anlegen';
  }

  @override
  String yearFileCreated(int year) {
    return 'Budget $year.xlsx aus dem Vorjahr angelegt';
  }

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get formulaHint => 'Summen gehen auch: 5+6,50 oder =500+232,23';

  @override
  String importPart(int done, int total) {
    return 'Teil $done von $total';
  }

  @override
  String get limitsTitle => 'Monatslimits';

  @override
  String get monthLimit1 => 'Monatslimit 1';

  @override
  String get monthLimit2 => 'Monatslimit 2';

  @override
  String get monthLimit1Hint => 'Ausgaben ab hier: gelb + Benachrichtigung';

  @override
  String get monthLimit2Hint => 'Ausgaben ab hier: rot + Benachrichtigung';

  @override
  String get limitsTap => 'Tippen, um die Limits zu setzen';

  @override
  String get limitsSaved => 'Limits in der Datei gespeichert';

  @override
  String get limitsInvalid =>
      'Zwei Beträge eingeben, Limit 2 nicht unter Limit 1.';

  @override
  String planTitle(String category, String month) {
    return 'Plan $category, $month';
  }

  @override
  String get planSaved => 'Plan in der Datei gespeichert';

  @override
  String allBookings(int count) {
    return 'Alle $count Buchungen';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get deleteEntryTitle => 'Buchung löschen?';

  @override
  String deleteEntryBody(String entry) {
    return '$entry wird aus der Datei entfernt.';
  }

  @override
  String get entryDeleted => 'Buchung gelöscht';

  @override
  String get onboardingTitle => 'Willkommen bei AZ Budget';

  @override
  String get onboardingIntro =>
      'Dein Budget ist eine Tabelle pro Jahr in einem Ordner deiner Wahl. Die App schreibt hinein, und du kannst sie jederzeit in Excel oder Google Sheets öffnen.';

  @override
  String get onboardingStep1Title => 'Ordner wählen';

  @override
  String get onboardingStep1Text =>
      'Google Drive, Dropbox, iCloud oder lokal. Dort liegt Budget <Jahr>.xlsx und wird synchronisiert.';

  @override
  String get onboardingStep2Title => 'Die Jahresdatei';

  @override
  String onboardingStep2Text(int year, String language) {
    return 'In einem leeren Ordner wird Budget $year.xlsx auf $language angelegt, mit Kategorien, Plan und Limits, die du ändern kannst. Vorhandene Dateien werden so genutzt, wie sie sind.';
  }

  @override
  String get onboardingStep3Title => 'Buchungen erfassen';

  @override
  String get onboardingStep3Text =>
      'Tippe auf + für eine Buchung. Schnellbuchungen wiederholen häufige, die Kamera scannt einen Beleg, der PDF-Knopf importiert einen Kontoauszug.';

  @override
  String get onboardingStep4Title => 'Übersicht und Limits';

  @override
  String get onboardingStep4Text =>
      'Einnahmen, Ausgaben und Plan je Kategorie und Monat, dazu deine Kontostände. Monatslimits geben eine Ampel und eine Benachrichtigung.';

  @override
  String get onboardingStep5Title => 'Optional: OpenAI-Schlüssel';

  @override
  String get onboardingStep5Text =>
      'Nur für Händler, die die Datei noch nie gesehen hat, und für Screenshots. Alles andere funktioniert offline.';

  @override
  String get onboardingLater => 'Später';

  @override
  String get howToUse => 'So funktioniert die App';

  @override
  String fileCreatedNotice(int year, String language) {
    return 'Budget $year.xlsx wurde in deinem Ordner angelegt ($language). Kategorien, Plan und Limits änderst du in der Übersicht oder in der Datei.';
  }

  @override
  String get gotIt => 'Verstanden';

  @override
  String get templateLanguage => 'Sprache der neuen Datei';

  @override
  String get categories => 'Kategorien';

  @override
  String get editCategories => 'Kategorien bearbeiten';

  @override
  String get editCategoriesHint =>
      'Name, Symbol, Farbe und Hinweis, gespeichert in der Datei';

  @override
  String get editCategory => 'Kategorie bearbeiten';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryHintLabel => 'Hinweis';

  @override
  String get categoryIconLabel => 'Symbol';

  @override
  String get categoryColorLabel => 'Farbe';

  @override
  String get autoChoice => 'Automatisch';

  @override
  String get renameNote =>
      'Beim Umbenennen werden auch die Buchungen und die Übersichtszeilen der Jahresdatei umbenannt.';

  @override
  String get categorySaved => 'Kategorie gespeichert';

  @override
  String get categoryNameTaken =>
      'Eine Kategorie mit diesem Namen gibt es schon.';

  @override
  String get typeExpense => 'Ausgabe';

  @override
  String get typeIncome => 'Einnahme';

  @override
  String get typeTransfer => 'Umbuchung';

  @override
  String translateFile(String language) {
    return 'Datei auf $language übersetzen';
  }

  @override
  String translateFileHint(String fileLanguage, String appLanguage) {
    return 'Datei: $fileLanguage · App: $appLanguage. Kategorien, Hinweise und Beschriftungen werden übersetzt, Buchungen umbenannt; Blattnamen bleiben.';
  }

  @override
  String translateFileConfirm(int year, String language) {
    return 'Budget $year.xlsx auf $language übersetzen?';
  }

  @override
  String translateFileDone(int count) {
    return '$count Zellen übersetzt';
  }

  @override
  String get translate => 'Übersetzen';

  @override
  String fileLanguage(String language) {
    return 'Sprache der Datei: $language';
  }

  @override
  String get chartHint =>
      'Plan grau, Ist in der Farbe der Kategorie. Tippe auf einen Balken.';

  @override
  String get actual => 'Ist';

  @override
  String get planLabel => 'Plan';

  @override
  String get addCategory => 'Kategorie hinzufügen';

  @override
  String get categoryType => 'Typ';

  @override
  String get typeChangeNote =>
      'Ein geänderter Typ baut die Einnahmen- und Ausgaben-Zeilen der Übersicht neu auf.';

  @override
  String get newExpenseNote =>
      'Eine neue Ausgabenkategorie bekommt in der Übersicht der Tabelle keine eigene Ist/Plan-Zeile; die App zählt sie trotzdem.';

  @override
  String get categoryAdded => 'Kategorie hinzugefügt';

  @override
  String get sourceShared => 'Geteilt';

  @override
  String get shareNoFolder =>
      'Wähle zuerst den Budget-Ordner, dann teile den Beleg noch einmal.';

  @override
  String shareUnsupported(String name) {
    return '„$name“ kann nicht verwendet werden: teile ein PDF, ein Bild oder Text.';
  }

  @override
  String splitReceipt(int count) {
    return 'Nach Kategorie aufteilen ($count Positionen)';
  }

  @override
  String get splitTitle => 'Beleg aufteilen';

  @override
  String splitSave(int count) {
    return '$count Buchungen speichern';
  }

  @override
  String forecastHint(String amount, int day) {
    return 'Tempo: etwa $amount im Monat, Limit 1 am $day.';
  }

  @override
  String forecastHintOk(String amount) {
    return 'Tempo: etwa $amount im Monat.';
  }

  @override
  String get saveAsRule => 'Als Regel merken';

  @override
  String ruleSaved(String pattern, String category) {
    return 'Regel gespeichert: „$pattern“ → $category';
  }

  @override
  String get settingsData => 'Daten';

  @override
  String get backupsTitle => 'Sicherungskopie vor jedem Schreiben';

  @override
  String get backupsHint =>
      '.backup/ im Budget-Ordner, die neuesten fünf bleiben';

  @override
  String get savePhotosTitle => 'Belegdateien aufbewahren';

  @override
  String get savePhotosHint =>
      'Belege/<Jahr>/ im Budget-Ordner, aus der Notiz verlinkt';

  @override
  String get currencyTitle => 'Währungssymbol';

  @override
  String get exportCsv => 'Buchungen als CSV exportieren';

  @override
  String csvExported(String name) {
    return '$name im Ordner gespeichert';
  }

  @override
  String get shareMonth => 'Monat teilen';

  @override
  String summaryTitle(String month) {
    return 'AZ Budget · $month';
  }

  @override
  String get summaryIncome => 'Einnahmen';

  @override
  String get summaryExpenses => 'Ausgaben';

  @override
  String get summaryTop => 'Größte Kategorien';

  @override
  String receiptLink(String path) {
    return 'Beleg: $path';
  }

  @override
  String get yearLabel => 'Jahr';

  @override
  String get yearChartHint =>
      'Ausgaben je Monat (Farbe = Limit), Plan grau, Linie = kumuliertes Saldo. Tippe auf einen Monat.';

  @override
  String get previousYear => 'Vorjahr';

  @override
  String get yearByCategory => 'Nach Kategorie: Ist / Plan / Vorjahr';
}
