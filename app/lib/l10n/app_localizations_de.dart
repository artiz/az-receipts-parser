// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Kassenbons';

  @override
  String get tabReceipts => 'Bons';

  @override
  String get tabStats => 'Statistik';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get scan => 'Bon scannen';

  @override
  String get scanning => 'Bon wird gelesen…';

  @override
  String get scanningHint =>
      'Die Texterkennung läuft auf diesem Gerät. Das dauert ein paar Sekunden.';

  @override
  String get noReceipts =>
      'Noch keine Bons. Tippe auf die Kamera, um einen zu scannen.';

  @override
  String get searchHint => 'Händler oder Adresse suchen';

  @override
  String get merchant => 'Händler';

  @override
  String get address => 'Adresse';

  @override
  String get date => 'Datum';

  @override
  String get time => 'Uhrzeit';

  @override
  String get total => 'Summe';

  @override
  String get payment => 'Zahlung';

  @override
  String get paymentCash => 'Bar';

  @override
  String get paymentCard => 'Karte';

  @override
  String get paymentUnknown => 'Unbekannt';

  @override
  String get category => 'Kategorie';

  @override
  String get items => 'Positionen';

  @override
  String get item => 'Artikel';

  @override
  String get quantity => 'Menge';

  @override
  String get price => 'Preis';

  @override
  String get addItem => 'Position hinzufügen';

  @override
  String get noItems => 'Keine Positionen erkannt.';

  @override
  String get itemsSum => 'Summe der Positionen';

  @override
  String get vat => 'MwSt';

  @override
  String get rawText => 'Erkannter Text';

  @override
  String get qrCode => 'Beleg-QR (RKSV)';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteReceiptQuestion => 'Diesen Bon löschen?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get receiptSaved => 'Bon gespeichert';

  @override
  String get confidence => 'Zuverlässigkeit';

  @override
  String get warnings => 'Bitte prüfen';

  @override
  String get warningTotalMissing => 'Summe nicht gefunden';

  @override
  String get warningTotalGuessed => 'Summe wurde geschätzt';

  @override
  String get warningDateMissing => 'Datum nicht gefunden';

  @override
  String get warningItemsMismatch => 'Positionen ergeben nicht die Summe';

  @override
  String get warningTotalMismatch => 'OCR-Summe weicht von der QR-Summe ab';

  @override
  String get month => 'Monat';

  @override
  String get byCategory => 'Nach Kategorie';

  @override
  String get byMerchant => 'Nach Händler';

  @override
  String get noDataForMonth => 'Keine Bons in diesem Monat.';

  @override
  String receiptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bons',
      one: '1 Bon',
    );
    return '$_temp0';
  }

  @override
  String get settingsCategories => 'Kategorien';

  @override
  String get settingsRules => 'Regeln zur Kategorisierung';

  @override
  String get settingsMerchantRules => 'Händler-Regeln';

  @override
  String get settingsKeywordRules => 'Stichwort-Regeln';

  @override
  String get settingsExportCsv => 'CSV exportieren';

  @override
  String get settingsExportJson => 'JSON exportieren';

  @override
  String get settingsBackup => 'Datenbank sichern';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsEngine => 'OCR-Engine';

  @override
  String get engineReady => 'Bereit';

  @override
  String get engineNotReady => 'Nicht geladen';

  @override
  String engineError(String message) {
    return 'Engine-Fehler: $message';
  }

  @override
  String get addCategory => 'Kategorie hinzufügen';

  @override
  String get categoryName => 'Name der Kategorie';

  @override
  String get learnedRule => 'gelernt';

  @override
  String get seedRule => 'vorgegeben';

  @override
  String get ruleDeleted => 'Regel gelöscht';

  @override
  String get noRules => 'Keine Regeln';

  @override
  String get privacyNote =>
      'Alle Daten bleiben auf diesem Gerät. Kein Netzwerkzugriff.';

  @override
  String ocrFailed(String message) {
    return 'Bon konnte nicht gelesen werden: $message';
  }

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get retake => 'Neu aufnehmen';

  @override
  String get newReceipt => 'Neuer Bon';

  @override
  String get photo => 'Foto';

  @override
  String get unknownMerchant => 'Unbekannter Händler';

  @override
  String get exportDone => 'Export fertig';

  @override
  String get categoryGroceries => 'Lebensmittel';

  @override
  String get categoryBakery => 'Bäckerei';

  @override
  String get categoryDrugstore => 'Drogerie & Kosmetik';

  @override
  String get categoryPharmacy => 'Apotheke';

  @override
  String get categoryHousehold => 'Haushalt';

  @override
  String get categoryClothing => 'Kleidung & Schuhe';

  @override
  String get categoryToys => 'Spielzeug & Kinder';

  @override
  String get categoryElectronics => 'Elektronik';

  @override
  String get categoryBooks => 'Bücher & Büro';

  @override
  String get categorySports => 'Sport';

  @override
  String get categoryDiy => 'Baumarkt & Garten';

  @override
  String get categoryRestaurant => 'Gastronomie';

  @override
  String get categoryFuel => 'Tanken';

  @override
  String get categoryTransport => 'Verkehr';

  @override
  String get categoryPets => 'Haustiere';

  @override
  String get categoryHealth => 'Gesundheit';

  @override
  String get categoryEntertainment => 'Freizeit';

  @override
  String get categoryOther => 'Sonstiges';
}
