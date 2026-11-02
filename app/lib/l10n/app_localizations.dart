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
  /// **'Receipts'**
  String get appTitle;

  /// No description provided for @tabReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get tabReceipts;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get tabStats;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scan;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Reading receipt…'**
  String get scanning;

  /// No description provided for @scanningHint.
  ///
  /// In en, this message translates to:
  /// **'Text recognition runs on this device. This takes a few seconds.'**
  String get scanningHint;

  /// No description provided for @noReceipts.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet. Tap the camera button to scan one.'**
  String get noReceipts;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search merchant or address'**
  String get searchHint;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCard;

  /// No description provided for @paymentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get paymentUnknown;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No line items were recognised.'**
  String get noItems;

  /// No description provided for @itemsSum.
  ///
  /// In en, this message translates to:
  /// **'Sum of items'**
  String get itemsSum;

  /// No description provided for @vat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat;

  /// No description provided for @rawText.
  ///
  /// In en, this message translates to:
  /// **'Recognised text'**
  String get rawText;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'Receipt QR (RKSV)'**
  String get qrCode;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteReceiptQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this receipt?'**
  String get deleteReceiptQuestion;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @receiptSaved.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved'**
  String get receiptSaved;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Check these fields'**
  String get warnings;

  /// No description provided for @warningTotalMissing.
  ///
  /// In en, this message translates to:
  /// **'Total not found'**
  String get warningTotalMissing;

  /// No description provided for @warningTotalGuessed.
  ///
  /// In en, this message translates to:
  /// **'Total was guessed'**
  String get warningTotalGuessed;

  /// No description provided for @warningDateMissing.
  ///
  /// In en, this message translates to:
  /// **'Date not found'**
  String get warningDateMissing;

  /// No description provided for @warningItemsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Items do not add up to the total'**
  String get warningItemsMismatch;

  /// No description provided for @warningTotalMismatch.
  ///
  /// In en, this message translates to:
  /// **'OCR total differs from the QR total'**
  String get warningTotalMismatch;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @byMerchant.
  ///
  /// In en, this message translates to:
  /// **'By merchant'**
  String get byMerchant;

  /// No description provided for @noDataForMonth.
  ///
  /// In en, this message translates to:
  /// **'No receipts in this month.'**
  String get noDataForMonth;

  /// No description provided for @receiptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 receipt} other{{count} receipts}}'**
  String receiptsCount(int count);

  /// No description provided for @settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// No description provided for @settingsRules.
  ///
  /// In en, this message translates to:
  /// **'Categorisation rules'**
  String get settingsRules;

  /// No description provided for @settingsMerchantRules.
  ///
  /// In en, this message translates to:
  /// **'Merchant rules'**
  String get settingsMerchantRules;

  /// No description provided for @settingsKeywordRules.
  ///
  /// In en, this message translates to:
  /// **'Keyword rules'**
  String get settingsKeywordRules;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCsv;

  /// No description provided for @settingsExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get settingsExportJson;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup database'**
  String get settingsBackup;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsEngine.
  ///
  /// In en, this message translates to:
  /// **'OCR engine'**
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

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @learnedRule.
  ///
  /// In en, this message translates to:
  /// **'learned'**
  String get learnedRule;

  /// No description provided for @seedRule.
  ///
  /// In en, this message translates to:
  /// **'built-in'**
  String get seedRule;

  /// No description provided for @ruleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Rule deleted'**
  String get ruleDeleted;

  /// No description provided for @noRules.
  ///
  /// In en, this message translates to:
  /// **'No rules'**
  String get noRules;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'All data stays on this device. No network access.'**
  String get privacyNote;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the receipt: {message}'**
  String ocrFailed(String message);

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @newReceipt.
  ///
  /// In en, this message translates to:
  /// **'New receipt'**
  String get newReceipt;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @unknownMerchant.
  ///
  /// In en, this message translates to:
  /// **'Unknown merchant'**
  String get unknownMerchant;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Export ready'**
  String get exportDone;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get categoryBakery;

  /// No description provided for @categoryDrugstore.
  ///
  /// In en, this message translates to:
  /// **'Drugstore & cosmetics'**
  String get categoryDrugstore;

  /// No description provided for @categoryPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get categoryPharmacy;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing & shoes'**
  String get categoryClothing;

  /// No description provided for @categoryToys.
  ///
  /// In en, this message translates to:
  /// **'Toys & kids'**
  String get categoryToys;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryBooks.
  ///
  /// In en, this message translates to:
  /// **'Books & office'**
  String get categoryBooks;

  /// No description provided for @categorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get categorySports;

  /// No description provided for @categoryDiy.
  ///
  /// In en, this message translates to:
  /// **'DIY & garden'**
  String get categoryDiy;

  /// No description provided for @categoryRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurants & cafés'**
  String get categoryRestaurant;

  /// No description provided for @categoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryFuel;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get categoryPets;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;
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
