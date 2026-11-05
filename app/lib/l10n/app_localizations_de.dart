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
  String get newEntry => 'Neue Buchung';

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
}
