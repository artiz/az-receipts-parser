/// Known merchants: a normalised needle, the display name and the default
/// receipt category. Matched against the header rows of the receipt.
///
/// Keep needles lower-case and umlaut-folded (see `normalize`).
library;

class KnownMerchant {
  const KnownMerchant(this.needle, this.name, this.categoryKey, {this.aliases = const [], this.pattern});
  final String needle;
  final String name;
  final String categoryKey;
  final List<String> aliases;

  /// Optional regex on the normalised row, for short names that need an
  /// anchor (the dm logo is OCR'd as a lone "dm").
  final String? pattern;

  bool matches(String normalizedRow) {
    if (normalizedRow.contains(needle) || aliases.any(normalizedRow.contains)) return true;
    final p = pattern;
    return p != null && RegExp(p).hasMatch(normalizedRow);
  }
}

const List<KnownMerchant> knownMerchants = [
  // Drugstores / cosmetics
  KnownMerchant('dm drogerie', 'dm', 'drugstore', aliases: ['dm-drogerie', 'dm drogeriemarkt', 'dm drogerle', 'dm markt'], pattern: r'^dm(\s|$)'),
  KnownMerchant('bipa', 'BIPA', 'drugstore'),
  KnownMerchant('mueller', 'Müller', 'drugstore'),
  KnownMerchant('rossmann', 'Rossmann', 'drugstore'),
  KnownMerchant('douglas', 'Douglas', 'drugstore'),
  // Groceries
  KnownMerchant('billa', 'BILLA', 'groceries'),
  KnownMerchant('spar', 'SPAR', 'groceries', aliases: ['eurospar', 'interspar']),
  KnownMerchant('hofer', 'HOFER', 'groceries'),
  KnownMerchant('lidl', 'Lidl', 'groceries'),
  KnownMerchant('penny', 'PENNY', 'groceries'),
  KnownMerchant('aldi', 'ALDI', 'groceries'),
  KnownMerchant('rewe', 'REWE', 'groceries'),
  KnownMerchant('edeka', 'EDEKA', 'groceries'),
  KnownMerchant('kaufland', 'Kaufland', 'groceries'),
  KnownMerchant('netto', 'Netto', 'groceries'),
  KnownMerchant('unimarkt', 'Unimarkt', 'groceries'),
  KnownMerchant('mpreis', 'MPREIS', 'groceries'),
  KnownMerchant('denns', "denn's", 'groceries'),
  KnownMerchant('nah & frisch', 'Nah&Frisch', 'groceries', aliases: ['nah&frisch']),
  KnownMerchant('merkur', 'MERKUR', 'groceries'),
  KnownMerchant('adeg', 'ADEG', 'groceries'),
  KnownMerchant('anker', 'Anker', 'bakery'),
  KnownMerchant('stroeck', 'Ströck', 'bakery'),
  KnownMerchant('felber', 'Felber', 'bakery'),
  // Discount / household
  KnownMerchant('tedi', 'TEDi', 'household'),
  KnownMerchant('action', 'Action', 'household'),
  KnownMerchant('pagro', 'PAGRO', 'household'),
  KnownMerchant('kik', 'KiK', 'clothing'),
  KnownMerchant('woolworth', 'Woolworth', 'household'),
  KnownMerchant('ikea', 'IKEA', 'household'),
  KnownMerchant('depot', 'DEPOT', 'household'),
  KnownMerchant('xxxlutz', 'XXXLutz', 'household'),
  KnownMerchant('moemax', 'mömax', 'household'),
  KnownMerchant('kika', 'kika', 'household'),
  KnownMerchant('leiner', 'Leiner', 'household'),
  // Clothing
  KnownMerchant('ernsting', "Ernsting's family", 'clothing'),
  KnownMerchant('tk maxx', 'TK Maxx', 'clothing', aliases: ['tkmaxx', 'tkmax', 'tk-maxx', 't.k.maxx', 't-k-maxx', 'tk max']),
  KnownMerchant('h&m', 'H&M', 'clothing', aliases: ['h & m', 'hennes']),
  KnownMerchant('c&a', 'C&A', 'clothing', aliases: ['c & a']),
  KnownMerchant('primark', 'Primark', 'clothing'),
  KnownMerchant('zara', 'ZARA', 'clothing'),
  KnownMerchant('deichmann', 'Deichmann', 'clothing'),
  KnownMerchant('humanic', 'Humanic', 'clothing'),
  KnownMerchant('peek & cloppenburg', 'Peek & Cloppenburg', 'clothing', aliases: ['peek&cloppenburg']),
  KnownMerchant('new yorker', 'New Yorker', 'clothing'),
  KnownMerchant('decathlon', 'Decathlon', 'sports'),
  KnownMerchant('hervis', 'Hervis', 'sports'),
  KnownMerchant('intersport', 'Intersport', 'sports'),
  // Electronics
  KnownMerchant('mediamarkt', 'MediaMarkt', 'electronics', aliases: ['media markt']),
  KnownMerchant('saturn', 'Saturn', 'electronics'),
  KnownMerchant('hartlauer', 'Hartlauer', 'electronics'),
  KnownMerchant('cyberport', 'Cyberport', 'electronics'),
  // Books / office
  KnownMerchant('thalia', 'Thalia', 'books'),
  KnownMerchant('libro', 'LIBRO', 'books'),
  KnownMerchant('morawa', 'Morawa', 'books'),
  // DIY / garden
  KnownMerchant('obi', 'OBI', 'diy'),
  KnownMerchant('bauhaus', 'BAUHAUS', 'diy'),
  KnownMerchant('hornbach', 'HORNBACH', 'diy'),
  KnownMerchant('bellaflora', 'bellaflora', 'diy'),
  KnownMerchant('hagebau', 'hagebau', 'diy'),
  // Pharmacy
  KnownMerchant('apotheke', 'Apotheke', 'pharmacy'),
  // Fuel
  KnownMerchant('omv', 'OMV', 'fuel'),
  KnownMerchant('shell', 'Shell', 'fuel'),
  KnownMerchant('jet tankstelle', 'JET', 'fuel'),
  KnownMerchant('avanti', 'Avanti', 'fuel'),
  KnownMerchant('eni ', 'Eni', 'fuel'),
  KnownMerchant('bp ', 'BP', 'fuel'),
  KnownMerchant('turmoel', 'Turmöl', 'fuel'),
  // Transport
  KnownMerchant('oebb', 'ÖBB', 'transport'),
  KnownMerchant('wiener linien', 'Wiener Linien', 'transport'),
  KnownMerchant('westbahn', 'WESTbahn', 'transport'),
  // Restaurants / fast food
  KnownMerchant("mcdonald", "McDonald's", 'restaurant', aliases: ['mc donald']),
  KnownMerchant('burger king', 'Burger King', 'restaurant'),
  KnownMerchant('starbucks', 'Starbucks', 'restaurant'),
  KnownMerchant('subway', 'Subway', 'restaurant'),
  KnownMerchant('nordsee', 'NORDSEE', 'restaurant'),
  KnownMerchant('vapiano', 'Vapiano', 'restaurant'),
  // Pets
  KnownMerchant('fressnapf', 'Fressnapf', 'pets'),
  KnownMerchant('futterhaus', 'Das Futterhaus', 'pets'),
];
