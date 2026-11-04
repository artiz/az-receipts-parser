// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Чеки';

  @override
  String get tabReceipts => 'Чеки';

  @override
  String get tabStats => 'Статистика';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get scan => 'Сканировать чек';

  @override
  String get scanning => 'Читаем чек…';

  @override
  String get scanningHint =>
      'Распознавание текста выполняется на устройстве. Это займёт несколько секунд.';

  @override
  String get noReceipts =>
      'Чеков пока нет. Нажмите на камеру, чтобы отсканировать.';

  @override
  String get searchHint => 'Поиск по магазину или адресу';

  @override
  String get merchant => 'Магазин';

  @override
  String get address => 'Адрес';

  @override
  String get date => 'Дата';

  @override
  String get time => 'Время';

  @override
  String get total => 'Итого';

  @override
  String get payment => 'Оплата';

  @override
  String get paymentCash => 'Наличные';

  @override
  String get paymentCard => 'Карта';

  @override
  String get paymentUnknown => 'Неизвестно';

  @override
  String get category => 'Категория';

  @override
  String get items => 'Позиции';

  @override
  String get item => 'Товар';

  @override
  String get quantity => 'Кол-во';

  @override
  String get price => 'Цена';

  @override
  String get addItem => 'Добавить позицию';

  @override
  String get noItems => 'Позиции не распознаны.';

  @override
  String get itemsSum => 'Сумма позиций';

  @override
  String get vat => 'НДС';

  @override
  String get rawText => 'Распознанный текст';

  @override
  String get qrCode => 'QR чека (RKSV)';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteReceiptQuestion => 'Удалить этот чек?';

  @override
  String get cancel => 'Отмена';

  @override
  String get edit => 'Изменить';

  @override
  String get receiptSaved => 'Чек сохранён';

  @override
  String get confidence => 'Уверенность';

  @override
  String get warnings => 'Проверьте поля';

  @override
  String get warningTotalMissing => 'Итог не найден';

  @override
  String get warningTotalGuessed => 'Итог определён приблизительно';

  @override
  String get warningDateMissing => 'Дата не найдена';

  @override
  String get warningItemsMismatch => 'Сумма позиций не совпадает с итогом';

  @override
  String get warningTotalMismatch => 'Итог по OCR отличается от итога в QR';

  @override
  String get month => 'Месяц';

  @override
  String get byCategory => 'По категориям';

  @override
  String get byMerchant => 'По магазинам';

  @override
  String get noDataForMonth => 'В этом месяце чеков нет.';

  @override
  String receiptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чеков',
      few: '$count чека',
      one: '1 чек',
    );
    return '$_temp0';
  }

  @override
  String get settingsCategories => 'Категории';

  @override
  String get settingsRules => 'Правила категоризации';

  @override
  String get settingsMerchantRules => 'Правила по магазинам';

  @override
  String get settingsKeywordRules => 'Правила по ключевым словам';

  @override
  String get settingsExportCsv => 'Экспорт CSV';

  @override
  String get settingsExportJson => 'Экспорт JSON';

  @override
  String get settingsBackup => 'Резервная копия базы';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsEngine => 'OCR-движок';

  @override
  String get engineReady => 'Готов';

  @override
  String get engineNotReady => 'Не загружен';

  @override
  String engineError(String message) {
    return 'Ошибка движка: $message';
  }

  @override
  String get addCategory => 'Добавить категорию';

  @override
  String get categoryName => 'Название категории';

  @override
  String get learnedRule => 'выучено';

  @override
  String get seedRule => 'встроено';

  @override
  String get ruleDeleted => 'Правило удалено';

  @override
  String get noRules => 'Правил нет';

  @override
  String get privacyNote =>
      'Все данные остаются на устройстве. Без доступа к сети.';

  @override
  String ocrFailed(String message) {
    return 'Не удалось прочитать чек: $message';
  }

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get retake => 'Переснять';

  @override
  String get newReceipt => 'Новый чек';

  @override
  String get photo => 'Фото';

  @override
  String get unknownMerchant => 'Неизвестный магазин';

  @override
  String get exportDone => 'Экспорт готов';

  @override
  String get categoryGroceries => 'Продукты';

  @override
  String get categoryBakery => 'Выпечка';

  @override
  String get categoryDrugstore => 'Бытовая химия и косметика';

  @override
  String get categoryPharmacy => 'Аптека';

  @override
  String get categoryHousehold => 'Дом и хозяйство';

  @override
  String get categoryClothing => 'Одежда и обувь';

  @override
  String get categoryToys => 'Игрушки и дети';

  @override
  String get categoryElectronics => 'Электроника';

  @override
  String get categoryBooks => 'Книги и канцелярия';

  @override
  String get categorySports => 'Спорт';

  @override
  String get categoryDiy => 'Ремонт и сад';

  @override
  String get categoryRestaurant => 'Кафе и рестораны';

  @override
  String get categoryFuel => 'Топливо';

  @override
  String get categoryTransport => 'Транспорт';

  @override
  String get categoryPets => 'Питомцы';

  @override
  String get categoryHealth => 'Здоровье';

  @override
  String get categoryEntertainment => 'Развлечения';

  @override
  String get categoryOther => 'Прочее';
}
