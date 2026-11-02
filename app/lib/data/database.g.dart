// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _builtinMeta = const VerificationMeta(
    'builtin',
  );
  @override
  late final GeneratedColumn<bool> builtin = GeneratedColumn<bool>(
    'builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    customName,
    sortOrder,
    builtin,
    hidden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('builtin')) {
      context.handle(
        _builtinMeta,
        builtin.isAcceptableOrUnknown(data['builtin']!, _builtinMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      builtin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}builtin'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String key;
  final String? customName;
  final int sortOrder;
  final bool builtin;
  final bool hidden;
  const Category({
    required this.key,
    this.customName,
    required this.sortOrder,
    required this.builtin,
    required this.hidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['builtin'] = Variable<bool>(builtin);
    map['hidden'] = Variable<bool>(hidden);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      key: Value(key),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      sortOrder: Value(sortOrder),
      builtin: Value(builtin),
      hidden: Value(hidden),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      key: serializer.fromJson<String>(json['key']),
      customName: serializer.fromJson<String?>(json['customName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      builtin: serializer.fromJson<bool>(json['builtin']),
      hidden: serializer.fromJson<bool>(json['hidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'customName': serializer.toJson<String?>(customName),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'builtin': serializer.toJson<bool>(builtin),
      'hidden': serializer.toJson<bool>(hidden),
    };
  }

  Category copyWith({
    String? key,
    Value<String?> customName = const Value.absent(),
    int? sortOrder,
    bool? builtin,
    bool? hidden,
  }) => Category(
    key: key ?? this.key,
    customName: customName.present ? customName.value : this.customName,
    sortOrder: sortOrder ?? this.sortOrder,
    builtin: builtin ?? this.builtin,
    hidden: hidden ?? this.hidden,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      key: data.key.present ? data.key.value : this.key,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      builtin: data.builtin.present ? data.builtin.value : this.builtin,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('key: $key, ')
          ..write('customName: $customName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('builtin: $builtin, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, customName, sortOrder, builtin, hidden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.key == this.key &&
          other.customName == this.customName &&
          other.sortOrder == this.sortOrder &&
          other.builtin == this.builtin &&
          other.hidden == this.hidden);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> key;
  final Value<String?> customName;
  final Value<int> sortOrder;
  final Value<bool> builtin;
  final Value<bool> hidden;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.key = const Value.absent(),
    this.customName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.builtin = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String key,
    this.customName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.builtin = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<Category> custom({
    Expression<String>? key,
    Expression<String>? customName,
    Expression<int>? sortOrder,
    Expression<bool>? builtin,
    Expression<bool>? hidden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (customName != null) 'custom_name': customName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (builtin != null) 'builtin': builtin,
      if (hidden != null) 'hidden': hidden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? key,
    Value<String?>? customName,
    Value<int>? sortOrder,
    Value<bool>? builtin,
    Value<bool>? hidden,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      key: key ?? this.key,
      customName: customName ?? this.customName,
      sortOrder: sortOrder ?? this.sortOrder,
      builtin: builtin ?? this.builtin,
      hidden: hidden ?? this.hidden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (builtin.present) {
      map['builtin'] = Variable<bool>(builtin.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('key: $key, ')
          ..write('customName: $customName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('builtin: $builtin, ')
          ..write('hidden: $hidden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantRawMeta = const VerificationMeta(
    'merchantRaw',
  );
  @override
  late final GeneratedColumn<String> merchantRaw = GeneratedColumn<String>(
    'merchant_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasedAtMeta = const VerificationMeta(
    'purchasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
    'purchased_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCentsMeta = const VerificationMeta(
    'totalCents',
  );
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
    'total_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EUR'),
  );
  static const VerificationMeta _paymentMeta = const VerificationMeta(
    'payment',
  );
  @override
  late final GeneratedColumn<String> payment = GeneratedColumn<String>(
    'payment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrJsonMeta = const VerificationMeta(
    'ocrJson',
  );
  @override
  late final GeneratedColumn<String> ocrJson = GeneratedColumn<String>(
    'ocr_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qrTextMeta = const VerificationMeta('qrText');
  @override
  late final GeneratedColumn<String> qrText = GeneratedColumn<String>(
    'qr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rksvKassenIdMeta = const VerificationMeta(
    'rksvKassenId',
  );
  @override
  late final GeneratedColumn<String> rksvKassenId = GeneratedColumn<String>(
    'rksv_kassen_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rksvBelegNummerMeta = const VerificationMeta(
    'rksvBelegNummer',
  );
  @override
  late final GeneratedColumn<String> rksvBelegNummer = GeneratedColumn<String>(
    'rksv_beleg_nummer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _warningsMeta = const VerificationMeta(
    'warnings',
  );
  @override
  late final GeneratedColumn<String> warnings = GeneratedColumn<String>(
    'warnings',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    merchant,
    merchantRaw,
    address,
    purchasedAt,
    totalCents,
    currency,
    payment,
    categoryKey,
    imagePath,
    ocrJson,
    qrText,
    rksvKassenId,
    rksvBelegNummer,
    notes,
    confidence,
    warnings,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('merchant_raw')) {
      context.handle(
        _merchantRawMeta,
        merchantRaw.isAcceptableOrUnknown(
          data['merchant_raw']!,
          _merchantRawMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
        _purchasedAtMeta,
        purchasedAt.isAcceptableOrUnknown(
          data['purchased_at']!,
          _purchasedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasedAtMeta);
    }
    if (data.containsKey('total_cents')) {
      context.handle(
        _totalCentsMeta,
        totalCents.isAcceptableOrUnknown(data['total_cents']!, _totalCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCentsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('payment')) {
      context.handle(
        _paymentMeta,
        payment.isAcceptableOrUnknown(data['payment']!, _paymentMeta),
      );
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('ocr_json')) {
      context.handle(
        _ocrJsonMeta,
        ocrJson.isAcceptableOrUnknown(data['ocr_json']!, _ocrJsonMeta),
      );
    }
    if (data.containsKey('qr_text')) {
      context.handle(
        _qrTextMeta,
        qrText.isAcceptableOrUnknown(data['qr_text']!, _qrTextMeta),
      );
    }
    if (data.containsKey('rksv_kassen_id')) {
      context.handle(
        _rksvKassenIdMeta,
        rksvKassenId.isAcceptableOrUnknown(
          data['rksv_kassen_id']!,
          _rksvKassenIdMeta,
        ),
      );
    }
    if (data.containsKey('rksv_beleg_nummer')) {
      context.handle(
        _rksvBelegNummerMeta,
        rksvBelegNummer.isAcceptableOrUnknown(
          data['rksv_beleg_nummer']!,
          _rksvBelegNummerMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('warnings')) {
      context.handle(
        _warningsMeta,
        warnings.isAcceptableOrUnknown(data['warnings']!, _warningsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      merchantRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_raw'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      purchasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchased_at'],
      )!,
      totalCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cents'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      payment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment'],
      )!,
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      ocrJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_json'],
      ),
      qrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_text'],
      ),
      rksvKassenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rksv_kassen_id'],
      ),
      rksvBelegNummer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rksv_beleg_nummer'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      warnings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final int id;
  final String? merchant;
  final String? merchantRaw;
  final String? address;
  final DateTime purchasedAt;
  final int totalCents;
  final String currency;
  final String payment;
  final String categoryKey;
  final String? imagePath;
  final String? ocrJson;
  final String? qrText;
  final String? rksvKassenId;
  final String? rksvBelegNummer;
  final String? notes;
  final double confidence;
  final String? warnings;
  final DateTime createdAt;
  const Receipt({
    required this.id,
    this.merchant,
    this.merchantRaw,
    this.address,
    required this.purchasedAt,
    required this.totalCents,
    required this.currency,
    required this.payment,
    required this.categoryKey,
    this.imagePath,
    this.ocrJson,
    this.qrText,
    this.rksvKassenId,
    this.rksvBelegNummer,
    this.notes,
    required this.confidence,
    this.warnings,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || merchantRaw != null) {
      map['merchant_raw'] = Variable<String>(merchantRaw);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['purchased_at'] = Variable<DateTime>(purchasedAt);
    map['total_cents'] = Variable<int>(totalCents);
    map['currency'] = Variable<String>(currency);
    map['payment'] = Variable<String>(payment);
    map['category_key'] = Variable<String>(categoryKey);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || ocrJson != null) {
      map['ocr_json'] = Variable<String>(ocrJson);
    }
    if (!nullToAbsent || qrText != null) {
      map['qr_text'] = Variable<String>(qrText);
    }
    if (!nullToAbsent || rksvKassenId != null) {
      map['rksv_kassen_id'] = Variable<String>(rksvKassenId);
    }
    if (!nullToAbsent || rksvBelegNummer != null) {
      map['rksv_beleg_nummer'] = Variable<String>(rksvBelegNummer);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['confidence'] = Variable<double>(confidence);
    if (!nullToAbsent || warnings != null) {
      map['warnings'] = Variable<String>(warnings);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      merchantRaw: merchantRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantRaw),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      purchasedAt: Value(purchasedAt),
      totalCents: Value(totalCents),
      currency: Value(currency),
      payment: Value(payment),
      categoryKey: Value(categoryKey),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      ocrJson: ocrJson == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrJson),
      qrText: qrText == null && nullToAbsent
          ? const Value.absent()
          : Value(qrText),
      rksvKassenId: rksvKassenId == null && nullToAbsent
          ? const Value.absent()
          : Value(rksvKassenId),
      rksvBelegNummer: rksvBelegNummer == null && nullToAbsent
          ? const Value.absent()
          : Value(rksvBelegNummer),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      confidence: Value(confidence),
      warnings: warnings == null && nullToAbsent
          ? const Value.absent()
          : Value(warnings),
      createdAt: Value(createdAt),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<int>(json['id']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      merchantRaw: serializer.fromJson<String?>(json['merchantRaw']),
      address: serializer.fromJson<String?>(json['address']),
      purchasedAt: serializer.fromJson<DateTime>(json['purchasedAt']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      currency: serializer.fromJson<String>(json['currency']),
      payment: serializer.fromJson<String>(json['payment']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      ocrJson: serializer.fromJson<String?>(json['ocrJson']),
      qrText: serializer.fromJson<String?>(json['qrText']),
      rksvKassenId: serializer.fromJson<String?>(json['rksvKassenId']),
      rksvBelegNummer: serializer.fromJson<String?>(json['rksvBelegNummer']),
      notes: serializer.fromJson<String?>(json['notes']),
      confidence: serializer.fromJson<double>(json['confidence']),
      warnings: serializer.fromJson<String?>(json['warnings']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'merchant': serializer.toJson<String?>(merchant),
      'merchantRaw': serializer.toJson<String?>(merchantRaw),
      'address': serializer.toJson<String?>(address),
      'purchasedAt': serializer.toJson<DateTime>(purchasedAt),
      'totalCents': serializer.toJson<int>(totalCents),
      'currency': serializer.toJson<String>(currency),
      'payment': serializer.toJson<String>(payment),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'imagePath': serializer.toJson<String?>(imagePath),
      'ocrJson': serializer.toJson<String?>(ocrJson),
      'qrText': serializer.toJson<String?>(qrText),
      'rksvKassenId': serializer.toJson<String?>(rksvKassenId),
      'rksvBelegNummer': serializer.toJson<String?>(rksvBelegNummer),
      'notes': serializer.toJson<String?>(notes),
      'confidence': serializer.toJson<double>(confidence),
      'warnings': serializer.toJson<String?>(warnings),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Receipt copyWith({
    int? id,
    Value<String?> merchant = const Value.absent(),
    Value<String?> merchantRaw = const Value.absent(),
    Value<String?> address = const Value.absent(),
    DateTime? purchasedAt,
    int? totalCents,
    String? currency,
    String? payment,
    String? categoryKey,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> ocrJson = const Value.absent(),
    Value<String?> qrText = const Value.absent(),
    Value<String?> rksvKassenId = const Value.absent(),
    Value<String?> rksvBelegNummer = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    double? confidence,
    Value<String?> warnings = const Value.absent(),
    DateTime? createdAt,
  }) => Receipt(
    id: id ?? this.id,
    merchant: merchant.present ? merchant.value : this.merchant,
    merchantRaw: merchantRaw.present ? merchantRaw.value : this.merchantRaw,
    address: address.present ? address.value : this.address,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    totalCents: totalCents ?? this.totalCents,
    currency: currency ?? this.currency,
    payment: payment ?? this.payment,
    categoryKey: categoryKey ?? this.categoryKey,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    ocrJson: ocrJson.present ? ocrJson.value : this.ocrJson,
    qrText: qrText.present ? qrText.value : this.qrText,
    rksvKassenId: rksvKassenId.present ? rksvKassenId.value : this.rksvKassenId,
    rksvBelegNummer: rksvBelegNummer.present
        ? rksvBelegNummer.value
        : this.rksvBelegNummer,
    notes: notes.present ? notes.value : this.notes,
    confidence: confidence ?? this.confidence,
    warnings: warnings.present ? warnings.value : this.warnings,
    createdAt: createdAt ?? this.createdAt,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      merchantRaw: data.merchantRaw.present
          ? data.merchantRaw.value
          : this.merchantRaw,
      address: data.address.present ? data.address.value : this.address,
      purchasedAt: data.purchasedAt.present
          ? data.purchasedAt.value
          : this.purchasedAt,
      totalCents: data.totalCents.present
          ? data.totalCents.value
          : this.totalCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      payment: data.payment.present ? data.payment.value : this.payment,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      ocrJson: data.ocrJson.present ? data.ocrJson.value : this.ocrJson,
      qrText: data.qrText.present ? data.qrText.value : this.qrText,
      rksvKassenId: data.rksvKassenId.present
          ? data.rksvKassenId.value
          : this.rksvKassenId,
      rksvBelegNummer: data.rksvBelegNummer.present
          ? data.rksvBelegNummer.value
          : this.rksvBelegNummer,
      notes: data.notes.present ? data.notes.value : this.notes,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      warnings: data.warnings.present ? data.warnings.value : this.warnings,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('merchantRaw: $merchantRaw, ')
          ..write('address: $address, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('totalCents: $totalCents, ')
          ..write('currency: $currency, ')
          ..write('payment: $payment, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('imagePath: $imagePath, ')
          ..write('ocrJson: $ocrJson, ')
          ..write('qrText: $qrText, ')
          ..write('rksvKassenId: $rksvKassenId, ')
          ..write('rksvBelegNummer: $rksvBelegNummer, ')
          ..write('notes: $notes, ')
          ..write('confidence: $confidence, ')
          ..write('warnings: $warnings, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    merchant,
    merchantRaw,
    address,
    purchasedAt,
    totalCents,
    currency,
    payment,
    categoryKey,
    imagePath,
    ocrJson,
    qrText,
    rksvKassenId,
    rksvBelegNummer,
    notes,
    confidence,
    warnings,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.merchant == this.merchant &&
          other.merchantRaw == this.merchantRaw &&
          other.address == this.address &&
          other.purchasedAt == this.purchasedAt &&
          other.totalCents == this.totalCents &&
          other.currency == this.currency &&
          other.payment == this.payment &&
          other.categoryKey == this.categoryKey &&
          other.imagePath == this.imagePath &&
          other.ocrJson == this.ocrJson &&
          other.qrText == this.qrText &&
          other.rksvKassenId == this.rksvKassenId &&
          other.rksvBelegNummer == this.rksvBelegNummer &&
          other.notes == this.notes &&
          other.confidence == this.confidence &&
          other.warnings == this.warnings &&
          other.createdAt == this.createdAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<int> id;
  final Value<String?> merchant;
  final Value<String?> merchantRaw;
  final Value<String?> address;
  final Value<DateTime> purchasedAt;
  final Value<int> totalCents;
  final Value<String> currency;
  final Value<String> payment;
  final Value<String> categoryKey;
  final Value<String?> imagePath;
  final Value<String?> ocrJson;
  final Value<String?> qrText;
  final Value<String?> rksvKassenId;
  final Value<String?> rksvBelegNummer;
  final Value<String?> notes;
  final Value<double> confidence;
  final Value<String?> warnings;
  final Value<DateTime> createdAt;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.merchant = const Value.absent(),
    this.merchantRaw = const Value.absent(),
    this.address = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.payment = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.ocrJson = const Value.absent(),
    this.qrText = const Value.absent(),
    this.rksvKassenId = const Value.absent(),
    this.rksvBelegNummer = const Value.absent(),
    this.notes = const Value.absent(),
    this.confidence = const Value.absent(),
    this.warnings = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    this.id = const Value.absent(),
    this.merchant = const Value.absent(),
    this.merchantRaw = const Value.absent(),
    this.address = const Value.absent(),
    required DateTime purchasedAt,
    required int totalCents,
    this.currency = const Value.absent(),
    this.payment = const Value.absent(),
    required String categoryKey,
    this.imagePath = const Value.absent(),
    this.ocrJson = const Value.absent(),
    this.qrText = const Value.absent(),
    this.rksvKassenId = const Value.absent(),
    this.rksvBelegNummer = const Value.absent(),
    this.notes = const Value.absent(),
    this.confidence = const Value.absent(),
    this.warnings = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : purchasedAt = Value(purchasedAt),
       totalCents = Value(totalCents),
       categoryKey = Value(categoryKey);
  static Insertable<Receipt> custom({
    Expression<int>? id,
    Expression<String>? merchant,
    Expression<String>? merchantRaw,
    Expression<String>? address,
    Expression<DateTime>? purchasedAt,
    Expression<int>? totalCents,
    Expression<String>? currency,
    Expression<String>? payment,
    Expression<String>? categoryKey,
    Expression<String>? imagePath,
    Expression<String>? ocrJson,
    Expression<String>? qrText,
    Expression<String>? rksvKassenId,
    Expression<String>? rksvBelegNummer,
    Expression<String>? notes,
    Expression<double>? confidence,
    Expression<String>? warnings,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (merchant != null) 'merchant': merchant,
      if (merchantRaw != null) 'merchant_raw': merchantRaw,
      if (address != null) 'address': address,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (totalCents != null) 'total_cents': totalCents,
      if (currency != null) 'currency': currency,
      if (payment != null) 'payment': payment,
      if (categoryKey != null) 'category_key': categoryKey,
      if (imagePath != null) 'image_path': imagePath,
      if (ocrJson != null) 'ocr_json': ocrJson,
      if (qrText != null) 'qr_text': qrText,
      if (rksvKassenId != null) 'rksv_kassen_id': rksvKassenId,
      if (rksvBelegNummer != null) 'rksv_beleg_nummer': rksvBelegNummer,
      if (notes != null) 'notes': notes,
      if (confidence != null) 'confidence': confidence,
      if (warnings != null) 'warnings': warnings,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReceiptsCompanion copyWith({
    Value<int>? id,
    Value<String?>? merchant,
    Value<String?>? merchantRaw,
    Value<String?>? address,
    Value<DateTime>? purchasedAt,
    Value<int>? totalCents,
    Value<String>? currency,
    Value<String>? payment,
    Value<String>? categoryKey,
    Value<String?>? imagePath,
    Value<String?>? ocrJson,
    Value<String?>? qrText,
    Value<String?>? rksvKassenId,
    Value<String?>? rksvBelegNummer,
    Value<String?>? notes,
    Value<double>? confidence,
    Value<String?>? warnings,
    Value<DateTime>? createdAt,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      merchantRaw: merchantRaw ?? this.merchantRaw,
      address: address ?? this.address,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      totalCents: totalCents ?? this.totalCents,
      currency: currency ?? this.currency,
      payment: payment ?? this.payment,
      categoryKey: categoryKey ?? this.categoryKey,
      imagePath: imagePath ?? this.imagePath,
      ocrJson: ocrJson ?? this.ocrJson,
      qrText: qrText ?? this.qrText,
      rksvKassenId: rksvKassenId ?? this.rksvKassenId,
      rksvBelegNummer: rksvBelegNummer ?? this.rksvBelegNummer,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (merchantRaw.present) {
      map['merchant_raw'] = Variable<String>(merchantRaw.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (payment.present) {
      map['payment'] = Variable<String>(payment.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (ocrJson.present) {
      map['ocr_json'] = Variable<String>(ocrJson.value);
    }
    if (qrText.present) {
      map['qr_text'] = Variable<String>(qrText.value);
    }
    if (rksvKassenId.present) {
      map['rksv_kassen_id'] = Variable<String>(rksvKassenId.value);
    }
    if (rksvBelegNummer.present) {
      map['rksv_beleg_nummer'] = Variable<String>(rksvBelegNummer.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (warnings.present) {
      map['warnings'] = Variable<String>(warnings.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('merchantRaw: $merchantRaw, ')
          ..write('address: $address, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('totalCents: $totalCents, ')
          ..write('currency: $currency, ')
          ..write('payment: $payment, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('imagePath: $imagePath, ')
          ..write('ocrJson: $ocrJson, ')
          ..write('qrText: $qrText, ')
          ..write('rksvKassenId: $rksvKassenId, ')
          ..write('rksvBelegNummer: $rksvBelegNummer, ')
          ..write('notes: $notes, ')
          ..write('confidence: $confidence, ')
          ..write('warnings: $warnings, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReceiptItemsTable extends ReceiptItems
    with TableInfo<$ReceiptItemsTable, ReceiptItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitCentsMeta = const VerificationMeta(
    'unitCents',
  );
  @override
  late final GeneratedColumn<int> unitCents = GeneratedColumn<int>(
    'unit_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCentsMeta = const VerificationMeta(
    'totalCents',
  );
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
    'total_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatRateMeta = const VerificationMeta(
    'vatRate',
  );
  @override
  late final GeneratedColumn<double> vatRate = GeneratedColumn<double>(
    'vat_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    name,
    quantity,
    unitCents,
    totalCents,
    vatRate,
    categoryKey,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_cents')) {
      context.handle(
        _unitCentsMeta,
        unitCents.isAcceptableOrUnknown(data['unit_cents']!, _unitCentsMeta),
      );
    }
    if (data.containsKey('total_cents')) {
      context.handle(
        _totalCentsMeta,
        totalCents.isAcceptableOrUnknown(data['total_cents']!, _totalCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCentsMeta);
    }
    if (data.containsKey('vat_rate')) {
      context.handle(
        _vatRateMeta,
        vatRate.isAcceptableOrUnknown(data['vat_rate']!, _vatRateMeta),
      );
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_cents'],
      ),
      totalCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cents'],
      )!,
      vatRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_rate'],
      ),
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ReceiptItemsTable createAlias(String alias) {
    return $ReceiptItemsTable(attachedDatabase, alias);
  }
}

class ReceiptItem extends DataClass implements Insertable<ReceiptItem> {
  final int id;
  final int receiptId;
  final String name;
  final double quantity;
  final int? unitCents;
  final int totalCents;
  final double? vatRate;
  final String categoryKey;
  final int sortOrder;
  const ReceiptItem({
    required this.id,
    required this.receiptId,
    required this.name,
    required this.quantity,
    this.unitCents,
    required this.totalCents,
    this.vatRate,
    required this.categoryKey,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receipt_id'] = Variable<int>(receiptId);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || unitCents != null) {
      map['unit_cents'] = Variable<int>(unitCents);
    }
    map['total_cents'] = Variable<int>(totalCents);
    if (!nullToAbsent || vatRate != null) {
      map['vat_rate'] = Variable<double>(vatRate);
    }
    map['category_key'] = Variable<String>(categoryKey);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ReceiptItemsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptItemsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      name: Value(name),
      quantity: Value(quantity),
      unitCents: unitCents == null && nullToAbsent
          ? const Value.absent()
          : Value(unitCents),
      totalCents: Value(totalCents),
      vatRate: vatRate == null && nullToAbsent
          ? const Value.absent()
          : Value(vatRate),
      categoryKey: Value(categoryKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory ReceiptItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptItem(
      id: serializer.fromJson<int>(json['id']),
      receiptId: serializer.fromJson<int>(json['receiptId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitCents: serializer.fromJson<int?>(json['unitCents']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      vatRate: serializer.fromJson<double?>(json['vatRate']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receiptId': serializer.toJson<int>(receiptId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double>(quantity),
      'unitCents': serializer.toJson<int?>(unitCents),
      'totalCents': serializer.toJson<int>(totalCents),
      'vatRate': serializer.toJson<double?>(vatRate),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ReceiptItem copyWith({
    int? id,
    int? receiptId,
    String? name,
    double? quantity,
    Value<int?> unitCents = const Value.absent(),
    int? totalCents,
    Value<double?> vatRate = const Value.absent(),
    String? categoryKey,
    int? sortOrder,
  }) => ReceiptItem(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unitCents: unitCents.present ? unitCents.value : this.unitCents,
    totalCents: totalCents ?? this.totalCents,
    vatRate: vatRate.present ? vatRate.value : this.vatRate,
    categoryKey: categoryKey ?? this.categoryKey,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ReceiptItem copyWithCompanion(ReceiptItemsCompanion data) {
    return ReceiptItem(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCents: data.unitCents.present ? data.unitCents.value : this.unitCents,
      totalCents: data.totalCents.present
          ? data.totalCents.value
          : this.totalCents,
      vatRate: data.vatRate.present ? data.vatRate.value : this.vatRate,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItem(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unitCents: $unitCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('vatRate: $vatRate, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptId,
    name,
    quantity,
    unitCents,
    totalCents,
    vatRate,
    categoryKey,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptItem &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unitCents == this.unitCents &&
          other.totalCents == this.totalCents &&
          other.vatRate == this.vatRate &&
          other.categoryKey == this.categoryKey &&
          other.sortOrder == this.sortOrder);
}

class ReceiptItemsCompanion extends UpdateCompanion<ReceiptItem> {
  final Value<int> id;
  final Value<int> receiptId;
  final Value<String> name;
  final Value<double> quantity;
  final Value<int?> unitCents;
  final Value<int> totalCents;
  final Value<double?> vatRate;
  final Value<String> categoryKey;
  final Value<int> sortOrder;
  const ReceiptItemsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCents = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ReceiptItemsCompanion.insert({
    this.id = const Value.absent(),
    required int receiptId,
    required String name,
    this.quantity = const Value.absent(),
    this.unitCents = const Value.absent(),
    required int totalCents,
    this.vatRate = const Value.absent(),
    required String categoryKey,
    this.sortOrder = const Value.absent(),
  }) : receiptId = Value(receiptId),
       name = Value(name),
       totalCents = Value(totalCents),
       categoryKey = Value(categoryKey);
  static Insertable<ReceiptItem> custom({
    Expression<int>? id,
    Expression<int>? receiptId,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<int>? unitCents,
    Expression<int>? totalCents,
    Expression<double>? vatRate,
    Expression<String>? categoryKey,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unitCents != null) 'unit_cents': unitCents,
      if (totalCents != null) 'total_cents': totalCents,
      if (vatRate != null) 'vat_rate': vatRate,
      if (categoryKey != null) 'category_key': categoryKey,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ReceiptItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? receiptId,
    Value<String>? name,
    Value<double>? quantity,
    Value<int?>? unitCents,
    Value<int>? totalCents,
    Value<double?>? vatRate,
    Value<String>? categoryKey,
    Value<int>? sortOrder,
  }) {
    return ReceiptItemsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitCents: unitCents ?? this.unitCents,
      totalCents: totalCents ?? this.totalCents,
      vatRate: vatRate ?? this.vatRate,
      categoryKey: categoryKey ?? this.categoryKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitCents.present) {
      map['unit_cents'] = Variable<int>(unitCents.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (vatRate.present) {
      map['vat_rate'] = Variable<double>(vatRate.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItemsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unitCents: $unitCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('vatRate: $vatRate, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ReceiptVatTable extends ReceiptVat
    with TableInfo<$ReceiptVatTable, ReceiptVatData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptVatTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netCentsMeta = const VerificationMeta(
    'netCents',
  );
  @override
  late final GeneratedColumn<int> netCents = GeneratedColumn<int>(
    'net_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vatCentsMeta = const VerificationMeta(
    'vatCents',
  );
  @override
  late final GeneratedColumn<int> vatCents = GeneratedColumn<int>(
    'vat_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grossCentsMeta = const VerificationMeta(
    'grossCents',
  );
  @override
  late final GeneratedColumn<int> grossCents = GeneratedColumn<int>(
    'gross_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    rate,
    netCents,
    vatCents,
    grossCents,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_vat';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptVatData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('net_cents')) {
      context.handle(
        _netCentsMeta,
        netCents.isAcceptableOrUnknown(data['net_cents']!, _netCentsMeta),
      );
    }
    if (data.containsKey('vat_cents')) {
      context.handle(
        _vatCentsMeta,
        vatCents.isAcceptableOrUnknown(data['vat_cents']!, _vatCentsMeta),
      );
    }
    if (data.containsKey('gross_cents')) {
      context.handle(
        _grossCentsMeta,
        grossCents.isAcceptableOrUnknown(data['gross_cents']!, _grossCentsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptVatData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptVatData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      netCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_cents'],
      ),
      vatCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_cents'],
      ),
      grossCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gross_cents'],
      ),
    );
  }

  @override
  $ReceiptVatTable createAlias(String alias) {
    return $ReceiptVatTable(attachedDatabase, alias);
  }
}

class ReceiptVatData extends DataClass implements Insertable<ReceiptVatData> {
  final int id;
  final int receiptId;
  final double rate;
  final int? netCents;
  final int? vatCents;
  final int? grossCents;
  const ReceiptVatData({
    required this.id,
    required this.receiptId,
    required this.rate,
    this.netCents,
    this.vatCents,
    this.grossCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receipt_id'] = Variable<int>(receiptId);
    map['rate'] = Variable<double>(rate);
    if (!nullToAbsent || netCents != null) {
      map['net_cents'] = Variable<int>(netCents);
    }
    if (!nullToAbsent || vatCents != null) {
      map['vat_cents'] = Variable<int>(vatCents);
    }
    if (!nullToAbsent || grossCents != null) {
      map['gross_cents'] = Variable<int>(grossCents);
    }
    return map;
  }

  ReceiptVatCompanion toCompanion(bool nullToAbsent) {
    return ReceiptVatCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      rate: Value(rate),
      netCents: netCents == null && nullToAbsent
          ? const Value.absent()
          : Value(netCents),
      vatCents: vatCents == null && nullToAbsent
          ? const Value.absent()
          : Value(vatCents),
      grossCents: grossCents == null && nullToAbsent
          ? const Value.absent()
          : Value(grossCents),
    );
  }

  factory ReceiptVatData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptVatData(
      id: serializer.fromJson<int>(json['id']),
      receiptId: serializer.fromJson<int>(json['receiptId']),
      rate: serializer.fromJson<double>(json['rate']),
      netCents: serializer.fromJson<int?>(json['netCents']),
      vatCents: serializer.fromJson<int?>(json['vatCents']),
      grossCents: serializer.fromJson<int?>(json['grossCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receiptId': serializer.toJson<int>(receiptId),
      'rate': serializer.toJson<double>(rate),
      'netCents': serializer.toJson<int?>(netCents),
      'vatCents': serializer.toJson<int?>(vatCents),
      'grossCents': serializer.toJson<int?>(grossCents),
    };
  }

  ReceiptVatData copyWith({
    int? id,
    int? receiptId,
    double? rate,
    Value<int?> netCents = const Value.absent(),
    Value<int?> vatCents = const Value.absent(),
    Value<int?> grossCents = const Value.absent(),
  }) => ReceiptVatData(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    rate: rate ?? this.rate,
    netCents: netCents.present ? netCents.value : this.netCents,
    vatCents: vatCents.present ? vatCents.value : this.vatCents,
    grossCents: grossCents.present ? grossCents.value : this.grossCents,
  );
  ReceiptVatData copyWithCompanion(ReceiptVatCompanion data) {
    return ReceiptVatData(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      rate: data.rate.present ? data.rate.value : this.rate,
      netCents: data.netCents.present ? data.netCents.value : this.netCents,
      vatCents: data.vatCents.present ? data.vatCents.value : this.vatCents,
      grossCents: data.grossCents.present
          ? data.grossCents.value
          : this.grossCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptVatData(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('rate: $rate, ')
          ..write('netCents: $netCents, ')
          ..write('vatCents: $vatCents, ')
          ..write('grossCents: $grossCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, receiptId, rate, netCents, vatCents, grossCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptVatData &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.rate == this.rate &&
          other.netCents == this.netCents &&
          other.vatCents == this.vatCents &&
          other.grossCents == this.grossCents);
}

class ReceiptVatCompanion extends UpdateCompanion<ReceiptVatData> {
  final Value<int> id;
  final Value<int> receiptId;
  final Value<double> rate;
  final Value<int?> netCents;
  final Value<int?> vatCents;
  final Value<int?> grossCents;
  const ReceiptVatCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.rate = const Value.absent(),
    this.netCents = const Value.absent(),
    this.vatCents = const Value.absent(),
    this.grossCents = const Value.absent(),
  });
  ReceiptVatCompanion.insert({
    this.id = const Value.absent(),
    required int receiptId,
    required double rate,
    this.netCents = const Value.absent(),
    this.vatCents = const Value.absent(),
    this.grossCents = const Value.absent(),
  }) : receiptId = Value(receiptId),
       rate = Value(rate);
  static Insertable<ReceiptVatData> custom({
    Expression<int>? id,
    Expression<int>? receiptId,
    Expression<double>? rate,
    Expression<int>? netCents,
    Expression<int>? vatCents,
    Expression<int>? grossCents,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (rate != null) 'rate': rate,
      if (netCents != null) 'net_cents': netCents,
      if (vatCents != null) 'vat_cents': vatCents,
      if (grossCents != null) 'gross_cents': grossCents,
    });
  }

  ReceiptVatCompanion copyWith({
    Value<int>? id,
    Value<int>? receiptId,
    Value<double>? rate,
    Value<int?>? netCents,
    Value<int?>? vatCents,
    Value<int?>? grossCents,
  }) {
    return ReceiptVatCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      rate: rate ?? this.rate,
      netCents: netCents ?? this.netCents,
      vatCents: vatCents ?? this.vatCents,
      grossCents: grossCents ?? this.grossCents,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (netCents.present) {
      map['net_cents'] = Variable<int>(netCents.value);
    }
    if (vatCents.present) {
      map['vat_cents'] = Variable<int>(vatCents.value);
    }
    if (grossCents.present) {
      map['gross_cents'] = Variable<int>(grossCents.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptVatCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('rate: $rate, ')
          ..write('netCents: $netCents, ')
          ..write('vatCents: $vatCents, ')
          ..write('grossCents: $grossCents')
          ..write(')'))
        .toString();
  }
}

class $MerchantRulesTable extends MerchantRules
    with TableInfo<$MerchantRulesTable, MerchantRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('seed'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pattern,
    categoryKey,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<MerchantRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MerchantRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern'],
      )!,
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MerchantRulesTable createAlias(String alias) {
    return $MerchantRulesTable(attachedDatabase, alias);
  }
}

class MerchantRuleRow extends DataClass implements Insertable<MerchantRuleRow> {
  final int id;
  final String pattern;
  final String categoryKey;
  final String source;
  final DateTime createdAt;
  const MerchantRuleRow({
    required this.id,
    required this.pattern,
    required this.categoryKey,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pattern'] = Variable<String>(pattern);
    map['category_key'] = Variable<String>(categoryKey);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MerchantRulesCompanion toCompanion(bool nullToAbsent) {
    return MerchantRulesCompanion(
      id: Value(id),
      pattern: Value(pattern),
      categoryKey: Value(categoryKey),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory MerchantRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantRuleRow(
      id: serializer.fromJson<int>(json['id']),
      pattern: serializer.fromJson<String>(json['pattern']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pattern': serializer.toJson<String>(pattern),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MerchantRuleRow copyWith({
    int? id,
    String? pattern,
    String? categoryKey,
    String? source,
    DateTime? createdAt,
  }) => MerchantRuleRow(
    id: id ?? this.id,
    pattern: pattern ?? this.pattern,
    categoryKey: categoryKey ?? this.categoryKey,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  MerchantRuleRow copyWithCompanion(MerchantRulesCompanion data) {
    return MerchantRuleRow(
      id: data.id.present ? data.id.value : this.id,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRuleRow(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pattern, categoryKey, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantRuleRow &&
          other.id == this.id &&
          other.pattern == this.pattern &&
          other.categoryKey == this.categoryKey &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class MerchantRulesCompanion extends UpdateCompanion<MerchantRuleRow> {
  final Value<int> id;
  final Value<String> pattern;
  final Value<String> categoryKey;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const MerchantRulesCompanion({
    this.id = const Value.absent(),
    this.pattern = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MerchantRulesCompanion.insert({
    this.id = const Value.absent(),
    required String pattern,
    required String categoryKey,
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : pattern = Value(pattern),
       categoryKey = Value(categoryKey);
  static Insertable<MerchantRuleRow> custom({
    Expression<int>? id,
    Expression<String>? pattern,
    Expression<String>? categoryKey,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pattern != null) 'pattern': pattern,
      if (categoryKey != null) 'category_key': categoryKey,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MerchantRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? pattern,
    Value<String>? categoryKey,
    Value<String>? source,
    Value<DateTime>? createdAt,
  }) {
    return MerchantRulesCompanion(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      categoryKey: categoryKey ?? this.categoryKey,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRulesCompanion(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KeywordRulesTable extends KeywordRules
    with TableInfo<$KeywordRulesTable, KeywordRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeywordRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keywordMeta = const VerificationMeta(
    'keyword',
  );
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
    'keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _categoryKeyMeta = const VerificationMeta(
    'categoryKey',
  );
  @override
  late final GeneratedColumn<String> categoryKey = GeneratedColumn<String>(
    'category_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories ("key")',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('seed'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    keyword,
    categoryKey,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'keyword_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeywordRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('keyword')) {
      context.handle(
        _keywordMeta,
        keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('category_key')) {
      context.handle(
        _categoryKeyMeta,
        categoryKey.isAcceptableOrUnknown(
          data['category_key']!,
          _categoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryKeyMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KeywordRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeywordRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      keyword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyword'],
      )!,
      categoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_key'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $KeywordRulesTable createAlias(String alias) {
    return $KeywordRulesTable(attachedDatabase, alias);
  }
}

class KeywordRuleRow extends DataClass implements Insertable<KeywordRuleRow> {
  final int id;
  final String keyword;
  final String categoryKey;
  final String source;
  final DateTime createdAt;
  const KeywordRuleRow({
    required this.id,
    required this.keyword,
    required this.categoryKey,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['keyword'] = Variable<String>(keyword);
    map['category_key'] = Variable<String>(categoryKey);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  KeywordRulesCompanion toCompanion(bool nullToAbsent) {
    return KeywordRulesCompanion(
      id: Value(id),
      keyword: Value(keyword),
      categoryKey: Value(categoryKey),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory KeywordRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeywordRuleRow(
      id: serializer.fromJson<int>(json['id']),
      keyword: serializer.fromJson<String>(json['keyword']),
      categoryKey: serializer.fromJson<String>(json['categoryKey']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyword': serializer.toJson<String>(keyword),
      'categoryKey': serializer.toJson<String>(categoryKey),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  KeywordRuleRow copyWith({
    int? id,
    String? keyword,
    String? categoryKey,
    String? source,
    DateTime? createdAt,
  }) => KeywordRuleRow(
    id: id ?? this.id,
    keyword: keyword ?? this.keyword,
    categoryKey: categoryKey ?? this.categoryKey,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  KeywordRuleRow copyWithCompanion(KeywordRulesCompanion data) {
    return KeywordRuleRow(
      id: data.id.present ? data.id.value : this.id,
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      categoryKey: data.categoryKey.present
          ? data.categoryKey.value
          : this.categoryKey,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeywordRuleRow(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyword, categoryKey, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeywordRuleRow &&
          other.id == this.id &&
          other.keyword == this.keyword &&
          other.categoryKey == this.categoryKey &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class KeywordRulesCompanion extends UpdateCompanion<KeywordRuleRow> {
  final Value<int> id;
  final Value<String> keyword;
  final Value<String> categoryKey;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const KeywordRulesCompanion({
    this.id = const Value.absent(),
    this.keyword = const Value.absent(),
    this.categoryKey = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  KeywordRulesCompanion.insert({
    this.id = const Value.absent(),
    required String keyword,
    required String categoryKey,
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : keyword = Value(keyword),
       categoryKey = Value(categoryKey);
  static Insertable<KeywordRuleRow> custom({
    Expression<int>? id,
    Expression<String>? keyword,
    Expression<String>? categoryKey,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyword != null) 'keyword': keyword,
      if (categoryKey != null) 'category_key': categoryKey,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  KeywordRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? keyword,
    Value<String>? categoryKey,
    Value<String>? source,
    Value<DateTime>? createdAt,
  }) {
    return KeywordRulesCompanion(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      categoryKey: categoryKey ?? this.categoryKey,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (categoryKey.present) {
      map['category_key'] = Variable<String>(categoryKey.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeywordRulesCompanion(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('categoryKey: $categoryKey, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ReceiptItemsTable receiptItems = $ReceiptItemsTable(this);
  late final $ReceiptVatTable receiptVat = $ReceiptVatTable(this);
  late final $MerchantRulesTable merchantRules = $MerchantRulesTable(this);
  late final $KeywordRulesTable keywordRules = $KeywordRulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    receipts,
    receiptItems,
    receiptVat,
    merchantRules,
    keywordRules,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'receipts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('receipt_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'receipts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('receipt_vat', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String key,
  Value<String?> customName,
  Value<int> sortOrder,
  Value<bool> builtin,
  Value<bool> hidden,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> key,
  Value<String?> customName,
  Value<int> sortOrder,
  Value<bool> builtin,
  Value<bool> hidden,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReceiptsTable, List<Receipt>> _receiptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.receipts,
    aliasName: 'categories__key__receipts__category_key',
  );

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReceiptItemsTable, List<ReceiptItem>>
  _receiptItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptItems,
    aliasName: 'categories__key__receipt_items__category_key',
  );

  $$ReceiptItemsTableProcessedTableManager get receiptItemsRefs {
    final manager = $$ReceiptItemsTableTableManager(
      $_db,
      $_db.receiptItems,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_receiptItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MerchantRulesTable, List<MerchantRuleRow>>
  _merchantRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.merchantRules,
    aliasName: 'categories__key__merchant_rules__category_key',
  );

  $$MerchantRulesTableProcessedTableManager get merchantRulesRefs {
    final manager = $$MerchantRulesTableTableManager(
      $_db,
      $_db.merchantRules,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_merchantRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$KeywordRulesTable, List<KeywordRuleRow>>
  _keywordRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.keywordRules,
    aliasName: 'categories__key__keyword_rules__category_key',
  );

  $$KeywordRulesTableProcessedTableManager get keywordRulesRefs {
    final manager = $$KeywordRulesTableTableManager(
      $_db,
      $_db.keywordRules,
    ).filter((f) => f.categoryKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_keywordRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtin => $composableBuilder(
    column: $table.builtin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> receiptsRefs(
    Expression<bool> Function($$ReceiptsTableFilterComposer f) f,
  ) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> receiptItemsRefs(
    Expression<bool> Function($$ReceiptItemsTableFilterComposer f) f,
  ) {
    final $$ReceiptItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableFilterComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> merchantRulesRefs(
    Expression<bool> Function($$MerchantRulesTableFilterComposer f) f,
  ) {
    final $$MerchantRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.merchantRules,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MerchantRulesTableFilterComposer(
            $db: $db,
            $table: $db.merchantRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> keywordRulesRefs(
    Expression<bool> Function($$KeywordRulesTableFilterComposer f) f,
  ) {
    final $$KeywordRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.keywordRules,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeywordRulesTableFilterComposer(
            $db: $db,
            $table: $db.keywordRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtin => $composableBuilder(
    column: $table.builtin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get builtin =>
      $composableBuilder(column: $table.builtin, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  Expression<T> receiptsRefs<T extends Object>(
    Expression<T> Function($$ReceiptsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> receiptItemsRefs<T extends Object>(
    Expression<T> Function($$ReceiptItemsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> merchantRulesRefs<T extends Object>(
    Expression<T> Function($$MerchantRulesTableAnnotationComposer a) f,
  ) {
    final $$MerchantRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.merchantRules,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MerchantRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.merchantRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> keywordRulesRefs<T extends Object>(
    Expression<T> Function($$KeywordRulesTableAnnotationComposer a) f,
  ) {
    final $$KeywordRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.keywordRules,
      getReferencedColumn: (t) => t.categoryKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeywordRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.keywordRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool receiptsRefs,
            bool receiptItemsRefs,
            bool merchantRulesRefs,
            bool keywordRulesRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> builtin = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                key: key,
                customName: customName,
                sortOrder: sortOrder,
                builtin: builtin,
                hidden: hidden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> customName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> builtin = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                key: key,
                customName: customName,
                sortOrder: sortOrder,
                builtin: builtin,
                hidden: hidden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                receiptsRefs = false,
                receiptItemsRefs = false,
                merchantRulesRefs = false,
                keywordRulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (receiptsRefs) db.receipts,
                    if (receiptItemsRefs) db.receiptItems,
                    if (merchantRulesRefs) db.merchantRules,
                    if (keywordRulesRefs) db.keywordRules,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (receiptsRefs)
                        await $_getPrefetchedDataByColumns<
                          Category,
                          $CategoriesTable,
                          Receipt,
                          $ReceiptsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._receiptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptsRefs,
                          currentColumn: 'key',
                          referencedColumn: 'category_key',
                          typedResults: items,
                        ),
                      if (receiptItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          Category,
                          $CategoriesTable,
                          ReceiptItem,
                          $ReceiptItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._receiptItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptItemsRefs,
                          currentColumn: 'key',
                          referencedColumn: 'category_key',
                          typedResults: items,
                        ),
                      if (merchantRulesRefs)
                        await $_getPrefetchedDataByColumns<
                          Category,
                          $CategoriesTable,
                          MerchantRuleRow,
                          $MerchantRulesTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._merchantRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).merchantRulesRefs,
                          currentColumn: 'key',
                          referencedColumn: 'category_key',
                          typedResults: items,
                        ),
                      if (keywordRulesRefs)
                        await $_getPrefetchedDataByColumns<
                          Category,
                          $CategoriesTable,
                          KeywordRuleRow,
                          $KeywordRulesTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._keywordRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).keywordRulesRefs,
                          currentColumn: 'key',
                          referencedColumn: 'category_key',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({
        bool receiptsRefs,
        bool receiptItemsRefs,
        bool merchantRulesRefs,
        bool keywordRulesRefs,
      })
    >;
typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  Value<String?> merchant,
  Value<String?> merchantRaw,
  Value<String?> address,
  required DateTime purchasedAt,
  required int totalCents,
  Value<String> currency,
  Value<String> payment,
  required String categoryKey,
  Value<String?> imagePath,
  Value<String?> ocrJson,
  Value<String?> qrText,
  Value<String?> rksvKassenId,
  Value<String?> rksvBelegNummer,
  Value<String?> notes,
  Value<double> confidence,
  Value<String?> warnings,
  Value<DateTime> createdAt,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  Value<String?> merchant,
  Value<String?> merchantRaw,
  Value<String?> address,
  Value<DateTime> purchasedAt,
  Value<int> totalCents,
  Value<String> currency,
  Value<String> payment,
  Value<String> categoryKey,
  Value<String?> imagePath,
  Value<String?> ocrJson,
  Value<String?> qrText,
  Value<String?> rksvKassenId,
  Value<String?> rksvBelegNummer,
  Value<String?> notes,
  Value<double> confidence,
  Value<String?> warnings,
  Value<DateTime> createdAt,
});

final class $$ReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) =>
      db.categories.createAlias('receipts__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReceiptItemsTable, List<ReceiptItem>>
  _receiptItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptItems,
    aliasName: 'receipts__id__receipt_items__receipt_id',
  );

  $$ReceiptItemsTableProcessedTableManager get receiptItemsRefs {
    final manager = $$ReceiptItemsTableTableManager(
      $_db,
      $_db.receiptItems,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReceiptVatTable, List<ReceiptVatData>>
  _receiptVatRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptVat,
    aliasName: 'receipts__id__receipt_vat__receipt_id',
  );

  $$ReceiptVatTableProcessedTableManager get receiptVatRefs {
    final manager = $$ReceiptVatTableTableManager(
      $_db,
      $_db.receiptVat,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptVatRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantRaw => $composableBuilder(
    column: $table.merchantRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payment => $composableBuilder(
    column: $table.payment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrJson => $composableBuilder(
    column: $table.ocrJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrText => $composableBuilder(
    column: $table.qrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rksvKassenId => $composableBuilder(
    column: $table.rksvKassenId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rksvBelegNummer => $composableBuilder(
    column: $table.rksvBelegNummer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warnings => $composableBuilder(
    column: $table.warnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> receiptItemsRefs(
    Expression<bool> Function($$ReceiptItemsTableFilterComposer f) f,
  ) {
    final $$ReceiptItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableFilterComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> receiptVatRefs(
    Expression<bool> Function($$ReceiptVatTableFilterComposer f) f,
  ) {
    final $$ReceiptVatTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptVat,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptVatTableFilterComposer(
            $db: $db,
            $table: $db.receiptVat,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantRaw => $composableBuilder(
    column: $table.merchantRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payment => $composableBuilder(
    column: $table.payment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrJson => $composableBuilder(
    column: $table.ocrJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrText => $composableBuilder(
    column: $table.qrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rksvKassenId => $composableBuilder(
    column: $table.rksvKassenId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rksvBelegNummer => $composableBuilder(
    column: $table.rksvBelegNummer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warnings => $composableBuilder(
    column: $table.warnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get merchantRaw => $composableBuilder(
    column: $table.merchantRaw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get payment =>
      $composableBuilder(column: $table.payment, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get ocrJson =>
      $composableBuilder(column: $table.ocrJson, builder: (column) => column);

  GeneratedColumn<String> get qrText =>
      $composableBuilder(column: $table.qrText, builder: (column) => column);

  GeneratedColumn<String> get rksvKassenId => $composableBuilder(
    column: $table.rksvKassenId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rksvBelegNummer => $composableBuilder(
    column: $table.rksvBelegNummer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warnings =>
      $composableBuilder(column: $table.warnings, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> receiptItemsRefs<T extends Object>(
    Expression<T> Function($$ReceiptItemsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> receiptVatRefs<T extends Object>(
    Expression<T> Function($$ReceiptVatTableAnnotationComposer a) f,
  ) {
    final $$ReceiptVatTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptVat,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptVatTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptVat,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, $$ReceiptsTableReferences),
          Receipt,
          PrefetchHooks Function({
            bool categoryKey,
            bool receiptItemsRefs,
            bool receiptVatRefs,
          })
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> merchantRaw = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<DateTime> purchasedAt = const Value.absent(),
                Value<int> totalCents = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> payment = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> ocrJson = const Value.absent(),
                Value<String?> qrText = const Value.absent(),
                Value<String?> rksvKassenId = const Value.absent(),
                Value<String?> rksvBelegNummer = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String?> warnings = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                merchant: merchant,
                merchantRaw: merchantRaw,
                address: address,
                purchasedAt: purchasedAt,
                totalCents: totalCents,
                currency: currency,
                payment: payment,
                categoryKey: categoryKey,
                imagePath: imagePath,
                ocrJson: ocrJson,
                qrText: qrText,
                rksvKassenId: rksvKassenId,
                rksvBelegNummer: rksvBelegNummer,
                notes: notes,
                confidence: confidence,
                warnings: warnings,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> merchantRaw = const Value.absent(),
                Value<String?> address = const Value.absent(),
                required DateTime purchasedAt,
                required int totalCents,
                Value<String> currency = const Value.absent(),
                Value<String> payment = const Value.absent(),
                required String categoryKey,
                Value<String?> imagePath = const Value.absent(),
                Value<String?> ocrJson = const Value.absent(),
                Value<String?> qrText = const Value.absent(),
                Value<String?> rksvKassenId = const Value.absent(),
                Value<String?> rksvBelegNummer = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String?> warnings = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                merchant: merchant,
                merchantRaw: merchantRaw,
                address: address,
                purchasedAt: purchasedAt,
                totalCents: totalCents,
                currency: currency,
                payment: payment,
                categoryKey: categoryKey,
                imagePath: imagePath,
                ocrJson: ocrJson,
                qrText: qrText,
                rksvKassenId: rksvKassenId,
                rksvBelegNummer: rksvBelegNummer,
                notes: notes,
                confidence: confidence,
                warnings: warnings,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptsTable, Receipt>(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryKey = false,
                receiptItemsRefs = false,
                receiptVatRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (receiptItemsRefs) db.receiptItems,
                    if (receiptVatRefs) db.receiptVat,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryKey) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryKey,
                            referencedTable: $$ReceiptsTableReferences
                                ._categoryKeyTable(db),
                            referencedColumn: $$ReceiptsTableReferences
                                ._categoryKeyTable(db)
                                .key,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (receiptItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          Receipt,
                          $ReceiptsTable,
                          ReceiptItem,
                          $ReceiptItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ReceiptsTableReferences
                              ._receiptItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'receipt_id',
                          typedResults: items,
                        ),
                      if (receiptVatRefs)
                        await $_getPrefetchedDataByColumns<
                          Receipt,
                          $ReceiptsTable,
                          ReceiptVatData,
                          $ReceiptVatTable
                        >(
                          currentTable: table,
                          referencedTable: $$ReceiptsTableReferences
                              ._receiptVatRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptVatRefs,
                          currentColumn: 'id',
                          referencedColumn: 'receipt_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, $$ReceiptsTableReferences),
      Receipt,
      PrefetchHooks Function({
        bool categoryKey,
        bool receiptItemsRefs,
        bool receiptVatRefs,
      })
    >;
typedef $$ReceiptItemsTableCreateCompanionBuilder =
    ReceiptItemsCompanion Function({
      Value<int> id,
      required int receiptId,
      required String name,
      Value<double> quantity,
      Value<int?> unitCents,
      required int totalCents,
      Value<double?> vatRate,
      required String categoryKey,
      Value<int> sortOrder,
    });
typedef $$ReceiptItemsTableUpdateCompanionBuilder =
    ReceiptItemsCompanion Function({
      Value<int> id,
      Value<int> receiptId,
      Value<String> name,
      Value<double> quantity,
      Value<int?> unitCents,
      Value<int> totalCents,
      Value<double?> vatRate,
      Value<String> categoryKey,
      Value<int> sortOrder,
    });

final class $$ReceiptItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptItemsTable, ReceiptItem> {
  $$ReceiptItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias('receipt_items__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) =>
      db.categories.createAlias('receipt_items__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTable> {
  $$ReceiptItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitCents => $composableBuilder(
    column: $table.unitCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTable> {
  $$ReceiptItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitCents => $composableBuilder(
    column: $table.unitCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTable> {
  $$ReceiptItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitCents =>
      $composableBuilder(column: $table.unitCents, builder: (column) => column);

  GeneratedColumn<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatRate =>
      $composableBuilder(column: $table.vatRate, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptItemsTable,
          ReceiptItem,
          $$ReceiptItemsTableFilterComposer,
          $$ReceiptItemsTableOrderingComposer,
          $$ReceiptItemsTableAnnotationComposer,
          $$ReceiptItemsTableCreateCompanionBuilder,
          $$ReceiptItemsTableUpdateCompanionBuilder,
          (ReceiptItem, $$ReceiptItemsTableReferences),
          ReceiptItem,
          PrefetchHooks Function({bool receiptId, bool categoryKey})
        > {
  $$ReceiptItemsTableTableManager(_$AppDatabase db, $ReceiptItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> receiptId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<int?> unitCents = const Value.absent(),
                Value<int> totalCents = const Value.absent(),
                Value<double?> vatRate = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ReceiptItemsCompanion(
                id: id,
                receiptId: receiptId,
                name: name,
                quantity: quantity,
                unitCents: unitCents,
                totalCents: totalCents,
                vatRate: vatRate,
                categoryKey: categoryKey,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int receiptId,
                required String name,
                Value<double> quantity = const Value.absent(),
                Value<int?> unitCents = const Value.absent(),
                required int totalCents,
                Value<double?> vatRate = const Value.absent(),
                required String categoryKey,
                Value<int> sortOrder = const Value.absent(),
              }) => ReceiptItemsCompanion.insert(
                id: id,
                receiptId: receiptId,
                name: name,
                quantity: quantity,
                unitCents: unitCents,
                totalCents: totalCents,
                vatRate: vatRate,
                categoryKey: categoryKey,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptItemsTable, ReceiptItem>(table),
                  $$ReceiptItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false, categoryKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.receiptId,
                        referencedTable: $$ReceiptItemsTableReferences
                            ._receiptIdTable(db),
                        referencedColumn: $$ReceiptItemsTableReferences
                            ._receiptIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (categoryKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryKey,
                        referencedTable: $$ReceiptItemsTableReferences
                            ._categoryKeyTable(db),
                        referencedColumn: $$ReceiptItemsTableReferences
                            ._categoryKeyTable(db)
                            .key,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptItemsTable,
      ReceiptItem,
      $$ReceiptItemsTableFilterComposer,
      $$ReceiptItemsTableOrderingComposer,
      $$ReceiptItemsTableAnnotationComposer,
      $$ReceiptItemsTableCreateCompanionBuilder,
      $$ReceiptItemsTableUpdateCompanionBuilder,
      (ReceiptItem, $$ReceiptItemsTableReferences),
      ReceiptItem,
      PrefetchHooks Function({bool receiptId, bool categoryKey})
    >;
typedef $$ReceiptVatTableCreateCompanionBuilder = ReceiptVatCompanion Function({
  Value<int> id,
  required int receiptId,
  required double rate,
  Value<int?> netCents,
  Value<int?> vatCents,
  Value<int?> grossCents,
});
typedef $$ReceiptVatTableUpdateCompanionBuilder = ReceiptVatCompanion Function({
  Value<int> id,
  Value<int> receiptId,
  Value<double> rate,
  Value<int?> netCents,
  Value<int?> vatCents,
  Value<int?> grossCents,
});

final class $$ReceiptVatTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptVatTable, ReceiptVatData> {
  $$ReceiptVatTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias('receipt_vat__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptVatTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptVatTable> {
  $$ReceiptVatTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netCents => $composableBuilder(
    column: $table.netCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatCents => $composableBuilder(
    column: $table.vatCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grossCents => $composableBuilder(
    column: $table.grossCents,
    builder: (column) => ColumnFilters(column),
  );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptVatTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptVatTable> {
  $$ReceiptVatTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netCents => $composableBuilder(
    column: $table.netCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatCents => $composableBuilder(
    column: $table.vatCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grossCents => $composableBuilder(
    column: $table.grossCents,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptVatTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptVatTable> {
  $$ReceiptVatTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<int> get netCents =>
      $composableBuilder(column: $table.netCents, builder: (column) => column);

  GeneratedColumn<int> get vatCents =>
      $composableBuilder(column: $table.vatCents, builder: (column) => column);

  GeneratedColumn<int> get grossCents => $composableBuilder(
    column: $table.grossCents,
    builder: (column) => column,
  );

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptVatTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptVatTable,
          ReceiptVatData,
          $$ReceiptVatTableFilterComposer,
          $$ReceiptVatTableOrderingComposer,
          $$ReceiptVatTableAnnotationComposer,
          $$ReceiptVatTableCreateCompanionBuilder,
          $$ReceiptVatTableUpdateCompanionBuilder,
          (ReceiptVatData, $$ReceiptVatTableReferences),
          ReceiptVatData,
          PrefetchHooks Function({bool receiptId})
        > {
  $$ReceiptVatTableTableManager(_$AppDatabase db, $ReceiptVatTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptVatTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptVatTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptVatTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> receiptId = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<int?> netCents = const Value.absent(),
                Value<int?> vatCents = const Value.absent(),
                Value<int?> grossCents = const Value.absent(),
              }) => ReceiptVatCompanion(
                id: id,
                receiptId: receiptId,
                rate: rate,
                netCents: netCents,
                vatCents: vatCents,
                grossCents: grossCents,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int receiptId,
                required double rate,
                Value<int?> netCents = const Value.absent(),
                Value<int?> vatCents = const Value.absent(),
                Value<int?> grossCents = const Value.absent(),
              }) => ReceiptVatCompanion.insert(
                id: id,
                receiptId: receiptId,
                rate: rate,
                netCents: netCents,
                vatCents: vatCents,
                grossCents: grossCents,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptVatTable, ReceiptVatData>(table),
                  $$ReceiptVatTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.receiptId,
                        referencedTable: $$ReceiptVatTableReferences
                            ._receiptIdTable(db),
                        referencedColumn: $$ReceiptVatTableReferences
                            ._receiptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptVatTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptVatTable,
      ReceiptVatData,
      $$ReceiptVatTableFilterComposer,
      $$ReceiptVatTableOrderingComposer,
      $$ReceiptVatTableAnnotationComposer,
      $$ReceiptVatTableCreateCompanionBuilder,
      $$ReceiptVatTableUpdateCompanionBuilder,
      (ReceiptVatData, $$ReceiptVatTableReferences),
      ReceiptVatData,
      PrefetchHooks Function({bool receiptId})
    >;
typedef $$MerchantRulesTableCreateCompanionBuilder =
    MerchantRulesCompanion Function({
      Value<int> id,
      required String pattern,
      required String categoryKey,
      Value<String> source,
      Value<DateTime> createdAt,
    });
typedef $$MerchantRulesTableUpdateCompanionBuilder =
    MerchantRulesCompanion Function({
      Value<int> id,
      Value<String> pattern,
      Value<String> categoryKey,
      Value<String> source,
      Value<DateTime> createdAt,
    });

final class $$MerchantRulesTableReferences
    extends
        BaseReferences<_$AppDatabase, $MerchantRulesTable, MerchantRuleRow> {
  $$MerchantRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) => db.categories
      .createAlias('merchant_rules__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MerchantRulesTableFilterComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MerchantRulesTable,
          MerchantRuleRow,
          $$MerchantRulesTableFilterComposer,
          $$MerchantRulesTableOrderingComposer,
          $$MerchantRulesTableAnnotationComposer,
          $$MerchantRulesTableCreateCompanionBuilder,
          $$MerchantRulesTableUpdateCompanionBuilder,
          (MerchantRuleRow, $$MerchantRulesTableReferences),
          MerchantRuleRow,
          PrefetchHooks Function({bool categoryKey})
        > {
  $$MerchantRulesTableTableManager(_$AppDatabase db, $MerchantRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MerchantRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MerchantRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MerchantRulesCompanion(
                id: id,
                pattern: pattern,
                categoryKey: categoryKey,
                source: source,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String pattern,
                required String categoryKey,
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MerchantRulesCompanion.insert(
                id: id,
                pattern: pattern,
                categoryKey: categoryKey,
                source: source,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MerchantRulesTable, MerchantRuleRow>(table),
                  $$MerchantRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryKey,
                        referencedTable: $$MerchantRulesTableReferences
                            ._categoryKeyTable(db),
                        referencedColumn: $$MerchantRulesTableReferences
                            ._categoryKeyTable(db)
                            .key,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MerchantRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MerchantRulesTable,
      MerchantRuleRow,
      $$MerchantRulesTableFilterComposer,
      $$MerchantRulesTableOrderingComposer,
      $$MerchantRulesTableAnnotationComposer,
      $$MerchantRulesTableCreateCompanionBuilder,
      $$MerchantRulesTableUpdateCompanionBuilder,
      (MerchantRuleRow, $$MerchantRulesTableReferences),
      MerchantRuleRow,
      PrefetchHooks Function({bool categoryKey})
    >;
typedef $$KeywordRulesTableCreateCompanionBuilder =
    KeywordRulesCompanion Function({
      Value<int> id,
      required String keyword,
      required String categoryKey,
      Value<String> source,
      Value<DateTime> createdAt,
    });
typedef $$KeywordRulesTableUpdateCompanionBuilder =
    KeywordRulesCompanion Function({
      Value<int> id,
      Value<String> keyword,
      Value<String> categoryKey,
      Value<String> source,
      Value<DateTime> createdAt,
    });

final class $$KeywordRulesTableReferences
    extends BaseReferences<_$AppDatabase, $KeywordRulesTable, KeywordRuleRow> {
  $$KeywordRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryKeyTable(_$AppDatabase db) =>
      db.categories.createAlias('keyword_rules__category_key__categories__key');

  $$CategoriesTableProcessedTableManager get categoryKey {
    final $_column = $_itemColumn<String>('category_key')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KeywordRulesTableFilterComposer
    extends Composer<_$AppDatabase, $KeywordRulesTable> {
  $$KeywordRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryKey {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeywordRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeywordRulesTable> {
  $$KeywordRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryKey {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeywordRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeywordRulesTable> {
  $$KeywordRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryKey {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryKey,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeywordRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeywordRulesTable,
          KeywordRuleRow,
          $$KeywordRulesTableFilterComposer,
          $$KeywordRulesTableOrderingComposer,
          $$KeywordRulesTableAnnotationComposer,
          $$KeywordRulesTableCreateCompanionBuilder,
          $$KeywordRulesTableUpdateCompanionBuilder,
          (KeywordRuleRow, $$KeywordRulesTableReferences),
          KeywordRuleRow,
          PrefetchHooks Function({bool categoryKey})
        > {
  $$KeywordRulesTableTableManager(_$AppDatabase db, $KeywordRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeywordRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeywordRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeywordRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> keyword = const Value.absent(),
                Value<String> categoryKey = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => KeywordRulesCompanion(
                id: id,
                keyword: keyword,
                categoryKey: categoryKey,
                source: source,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String keyword,
                required String categoryKey,
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => KeywordRulesCompanion.insert(
                id: id,
                keyword: keyword,
                categoryKey: categoryKey,
                source: source,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeywordRulesTable, KeywordRuleRow>(table),
                  $$KeywordRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryKey,
                        referencedTable: $$KeywordRulesTableReferences
                            ._categoryKeyTable(db),
                        referencedColumn: $$KeywordRulesTableReferences
                            ._categoryKeyTable(db)
                            .key,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$KeywordRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeywordRulesTable,
      KeywordRuleRow,
      $$KeywordRulesTableFilterComposer,
      $$KeywordRulesTableOrderingComposer,
      $$KeywordRulesTableAnnotationComposer,
      $$KeywordRulesTableCreateCompanionBuilder,
      $$KeywordRulesTableUpdateCompanionBuilder,
      (KeywordRuleRow, $$KeywordRulesTableReferences),
      KeywordRuleRow,
      PrefetchHooks Function({bool categoryKey})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ReceiptItemsTableTableManager get receiptItems =>
      $$ReceiptItemsTableTableManager(_db, _db.receiptItems);
  $$ReceiptVatTableTableManager get receiptVat =>
      $$ReceiptVatTableTableManager(_db, _db.receiptVat);
  $$MerchantRulesTableTableManager get merchantRules =>
      $$MerchantRulesTableTableManager(_db, _db.merchantRules);
  $$KeywordRulesTableTableManager get keywordRules =>
      $$KeywordRulesTableTableManager(_db, _db.keywordRules);
}
