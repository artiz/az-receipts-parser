// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AZ Budget';

  @override
  String get tabEntries => 'Записи';

  @override
  String get tabOverview => 'Обзор';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get newEntry => 'Новая запись';

  @override
  String get scanReceipt => 'Сканировать чек';

  @override
  String get importScreenshot => 'Импорт скриншота';

  @override
  String get importStatement => 'Импорт выписки (PDF)';

  @override
  String get syncNoFolder => 'Папка не выбрана';

  @override
  String get syncSyncing => 'Синхронизация…';

  @override
  String syncIdle(int year) {
    return 'Budget $year.xlsx актуален';
  }

  @override
  String syncOffline(int count) {
    return 'Офлайн: ждут $count записей';
  }

  @override
  String get syncError => 'Ошибка синхронизации';

  @override
  String pendingCount(int count) {
    return '$count в очереди';
  }

  @override
  String get entryIncomplete => 'Выбери категорию и введи сумму.';

  @override
  String get category => 'Категория';

  @override
  String get description => 'Описание';

  @override
  String get amount => 'Сумма';

  @override
  String get amountIncomeHint => 'Доходы сохраняются с минусом автоматически.';

  @override
  String get note => 'Заметка';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirmEntry => 'Подтвердить запись';

  @override
  String entrySaved(String amount) {
    return 'Сохранено: $amount';
  }

  @override
  String get editInFile => 'Записи, которые уже в файле, правятся в таблице.';

  @override
  String get editEntry => 'Изменить запись';

  @override
  String get chooseFolderHint =>
      'Выбери папку с файлами Budget <год>.xlsx (Google Drive, Dropbox, iCloud или локально).';

  @override
  String get chooseFolder => 'Выбрать папку';

  @override
  String get quickEntries => 'Быстрые записи';

  @override
  String get recentEntries => 'Последние';

  @override
  String get showLess => 'Меньше';

  @override
  String showAll(int count) {
    return 'Все $count';
  }

  @override
  String get noEntries => 'Записей пока нет.';

  @override
  String get noFileLoaded => 'Файл бюджета не загружен.';

  @override
  String get income => 'Доходы';

  @override
  String get expenses => 'Расходы';

  @override
  String limitHint(String limit1, String limit2) {
    return 'Лимиты $limit1 / $limit2';
  }

  @override
  String get saldo => 'Сальдо (доходы − расходы)';

  @override
  String get byCategory => 'По категориям (факт / план)';

  @override
  String get total => 'Итого';

  @override
  String get accountInputs => 'Остатки на начало месяца';

  @override
  String get settingsFolder => 'Папка бюджета';

  @override
  String get folderNone => 'Папка не выбрана';

  @override
  String folderFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлов бюджета',
      few: '$count файла бюджета',
      one: '1 файл бюджета',
      zero: 'нет файлов Budget <год>.xlsx',
    );
    return '$_temp0';
  }

  @override
  String get changeFolder => 'Изменить';

  @override
  String get forgetFolder => 'Отключить папку';

  @override
  String get yearFile => 'Файл года';

  @override
  String categoriesCount(int count) {
    return 'категорий: $count';
  }

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String lastSync(String time) {
    return 'Последняя: $time';
  }

  @override
  String get settingsOpenAi => 'OpenAI (импорт выписок)';

  @override
  String get openAiKey => 'API-ключ';

  @override
  String get openAiKeySet => 'Сохранён на устройстве';

  @override
  String get openAiKeyNotSet => 'Не задан';

  @override
  String get openAiModel => 'Модель';

  @override
  String get settingsEngine => 'OCR-движок (docling.rs)';

  @override
  String get engineReady => 'Готов';

  @override
  String get engineNotReady => 'Не загружен';

  @override
  String engineError(String message) {
    return 'Ошибка движка: $message';
  }

  @override
  String get scanning => 'Читаю…';

  @override
  String get scanningHint =>
      'Распознавание идёт на устройстве. Это займёт несколько секунд.';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get aboutText =>
      'Записи попадают прямо в годовую таблицу. С OpenAI общается только импорт выписок, с твоим ключом.';

  @override
  String get importTitle => 'Проверка импорта';

  @override
  String get importSelectAll => 'Все / ничего';

  @override
  String get importNoText =>
      'Записей не найдено. Для сканированных PDF сфотографируй страницу.';

  @override
  String importFromSource(String source) {
    return 'Источник: $source';
  }

  @override
  String get importDuplicate => 'уже записано';

  @override
  String importSkipped(String reason) {
    return 'пропущено: $reason';
  }

  @override
  String get importNeedsReview => 'проверь категорию';

  @override
  String importApply(int count) {
    return 'Добавить $count';
  }

  @override
  String get importNothingSelected => 'Ничего не выбрано.';

  @override
  String importDone(int count) {
    return 'Добавлено записей: $count';
  }

  @override
  String get chooseCategory => 'Выбери категорию';

  @override
  String get importRunning => 'Импорт…';

  @override
  String get importReadingPdf => 'Читаю текстовый слой PDF.';

  @override
  String importLlmHint(String model) {
    return '$model превращает текст в записи.';
  }

  @override
  String importFailed(String message) {
    return 'Импорт не удался: $message';
  }

  @override
  String get openAiKeyMissing => 'Сначала укажи API-ключ OpenAI в настройках.';

  @override
  String get sourceScreenshot => 'Скриншот';

  @override
  String get receiptConfirm => 'Чек';

  @override
  String get entryExistsTitle => 'Уже записано?';

  @override
  String entryExistsBody(String entry, String amount) {
    return '$entry на $amount уже есть в файле. Добавить детали чека в заметку?';
  }

  @override
  String get addAnyway => 'Всё равно добавить';

  @override
  String get mergeNote => 'В заметку';

  @override
  String get noteMerged => 'Заметка дополнена';

  @override
  String get entryUpdated => 'Запись обновлена';

  @override
  String addToEntry(String entry, String amount) {
    return 'Добавить к $entry ($amount)';
  }

  @override
  String get addToEntryShort => 'Добавить сумму';

  @override
  String get addAmount => 'Сумма';

  @override
  String get addDetail => 'За что (попадёт в заметку)';

  @override
  String searchHint(int count) {
    return 'Поиск по $count записям';
  }

  @override
  String strandedPending(int count, int year) {
    return '$count записей в очереди с датой $year: нет файла за этот год.';
  }

  @override
  String get fixDate => 'Исправить дату';

  @override
  String yearFileMissing(int year) {
    return 'Файла за $year ещё нет.';
  }

  @override
  String createYearFile(int year) {
    return 'Создать Budget $year.xlsx';
  }

  @override
  String yearFileCreated(int year) {
    return 'Budget $year.xlsx создан из прошлого года';
  }

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get formulaHint => 'Можно сумму: 5+6,50 или =500+232,23';
}
