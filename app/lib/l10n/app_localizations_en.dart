// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Receipts';

  @override
  String get tabReceipts => 'Receipts';

  @override
  String get tabStats => 'Statistics';

  @override
  String get tabSettings => 'Settings';

  @override
  String get scan => 'Scan receipt';

  @override
  String get scanning => 'Reading receipt…';

  @override
  String get scanningHint =>
      'Text recognition runs on this device. This takes a few seconds.';

  @override
  String get noReceipts =>
      'No receipts yet. Tap the camera button to scan one.';

  @override
  String get searchHint => 'Search merchant or address';

  @override
  String get merchant => 'Merchant';

  @override
  String get address => 'Address';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get total => 'Total';

  @override
  String get payment => 'Payment';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentUnknown => 'Unknown';

  @override
  String get category => 'Category';

  @override
  String get items => 'Items';

  @override
  String get item => 'Item';

  @override
  String get quantity => 'Qty';

  @override
  String get price => 'Price';

  @override
  String get addItem => 'Add item';

  @override
  String get noItems => 'No line items were recognised.';

  @override
  String get itemsSum => 'Sum of items';

  @override
  String get vat => 'VAT';

  @override
  String get rawText => 'Recognised text';

  @override
  String get qrCode => 'Receipt QR (RKSV)';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get deleteReceiptQuestion => 'Delete this receipt?';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get receiptSaved => 'Receipt saved';

  @override
  String get confidence => 'Confidence';

  @override
  String get warnings => 'Check these fields';

  @override
  String get warningTotalMissing => 'Total not found';

  @override
  String get warningTotalGuessed => 'Total was guessed';

  @override
  String get warningDateMissing => 'Date not found';

  @override
  String get warningItemsMismatch => 'Items do not add up to the total';

  @override
  String get warningTotalMismatch => 'OCR total differs from the QR total';

  @override
  String get month => 'Month';

  @override
  String get byCategory => 'By category';

  @override
  String get byMerchant => 'By merchant';

  @override
  String get noDataForMonth => 'No receipts in this month.';

  @override
  String receiptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receipts',
      one: '1 receipt',
    );
    return '$_temp0';
  }

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsRules => 'Categorisation rules';

  @override
  String get settingsMerchantRules => 'Merchant rules';

  @override
  String get settingsKeywordRules => 'Keyword rules';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get settingsExportJson => 'Export JSON';

  @override
  String get settingsBackup => 'Backup database';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsEngine => 'OCR engine';

  @override
  String get engineReady => 'Ready';

  @override
  String get engineNotReady => 'Not loaded';

  @override
  String engineError(String message) {
    return 'Engine error: $message';
  }

  @override
  String get addCategory => 'Add category';

  @override
  String get categoryName => 'Category name';

  @override
  String get learnedRule => 'learned';

  @override
  String get seedRule => 'built-in';

  @override
  String get ruleDeleted => 'Rule deleted';

  @override
  String get noRules => 'No rules';

  @override
  String get privacyNote => 'All data stays on this device. No network access.';

  @override
  String ocrFailed(String message) {
    return 'Could not read the receipt: $message';
  }

  @override
  String get takePhoto => 'Take photo';

  @override
  String get retake => 'Retake';

  @override
  String get newReceipt => 'New receipt';

  @override
  String get photo => 'Photo';

  @override
  String get unknownMerchant => 'Unknown merchant';

  @override
  String get exportDone => 'Export ready';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryBakery => 'Bakery';

  @override
  String get categoryDrugstore => 'Drugstore & cosmetics';

  @override
  String get categoryPharmacy => 'Pharmacy';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryClothing => 'Clothing & shoes';

  @override
  String get categoryToys => 'Toys & kids';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryBooks => 'Books & office';

  @override
  String get categorySports => 'Sports';

  @override
  String get categoryDiy => 'DIY & garden';

  @override
  String get categoryRestaurant => 'Restaurants & cafés';

  @override
  String get categoryFuel => 'Fuel';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryPets => 'Pets';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryOther => 'Other';
}
