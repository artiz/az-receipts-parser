/// Local SQLite schema (drift). Everything stays on the device.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../categorize/categories.dart';
import '../categorize/categorizer.dart';

part 'database.g.dart';

class Categories extends Table {
  TextColumn get key => text()();
  TextColumn get customName => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get builtin => boolean().withDefault(const Constant(true))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}

class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchant => text().nullable()();
  TextColumn get merchantRaw => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get purchasedAt => dateTime()();
  IntColumn get totalCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  TextColumn get payment => text().withDefault(const Constant('unknown'))();
  TextColumn get categoryKey => text().references(Categories, #key)();
  TextColumn get imagePath => text().nullable()();
  TextColumn get ocrJson => text().nullable()();
  TextColumn get qrText => text().nullable()();
  TextColumn get rksvKassenId => text().nullable()();
  TextColumn get rksvBelegNummer => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(0))();
  TextColumn get warnings => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ReceiptItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId => integer().references(Receipts, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  IntColumn get unitCents => integer().nullable()();
  IntColumn get totalCents => integer()();
  RealColumn get vatRate => real().nullable()();
  TextColumn get categoryKey => text().references(Categories, #key)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ReceiptVat extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId => integer().references(Receipts, #id, onDelete: KeyAction.cascade)();
  RealColumn get rate => real()();
  IntColumn get netCents => integer().nullable()();
  IntColumn get vatCents => integer().nullable()();
  IntColumn get grossCents => integer().nullable()();
}

@DataClassName('MerchantRuleRow')
class MerchantRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pattern => text().unique()();
  TextColumn get categoryKey => text().references(Categories, #key)();
  TextColumn get source => text().withDefault(const Constant('seed'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('KeywordRuleRow')
class KeywordRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text().unique()();
  TextColumn get categoryKey => text().references(Categories, #key)();
  TextColumn get source => text().withDefault(const Constant('seed'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Categories, Receipts, ReceiptItems, ReceiptVat, MerchantRules, KeywordRules])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seed();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Seed the built-in categories and rules. Idempotent: existing rows are
  /// left alone, so user edits survive a re-seed after an app update.
  Future<void> seed() async {
    await batch((b) {
      var order = 0;
      for (final c in builtinCategories) {
        b.insert(
          categories,
          CategoriesCompanion.insert(key: c.key, sortOrder: Value(order++), builtin: const Value(true)),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final r in Categorizer.defaultMerchantRules()) {
        b.insert(
          merchantRules,
          MerchantRulesCompanion.insert(pattern: r.pattern, categoryKey: r.categoryKey),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final r in Categorizer.defaultKeywordRules()) {
        b.insert(
          keywordRules,
          KeywordRulesCompanion.insert(keyword: r.keyword, categoryKey: r.categoryKey),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'az_receipts',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
