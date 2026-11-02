/// Austrian RKSV (Registrierkassensicherheitsverordnung) receipt QR codes.
///
/// Layout (underscore separated, 14 fields):
/// `_R1-AT1_<KassenID>_<Belegnummer>_<yyyy-MM-ddTHH:mm:ss>_<Betrag 20%>_<10%>_<13%>_<0%>_<19%>_<Umsatzzähler>_<Zertifikat>_<Sig voriger Beleg>_<Signatur>`
/// Amounts use a decimal comma; the five VAT buckets are gross amounts.
library;

class RksvQr {
  RksvQr({
    required this.raw,
    required this.kassenId,
    required this.belegNummer,
    required this.timestamp,
    required this.grossByRate,
    required this.certificateSerial,
  });

  final String raw;
  final String kassenId;
  final String belegNummer;
  final DateTime timestamp;

  /// Gross amount in cents per VAT rate (20, 10, 13, 0, 19).
  final Map<int, int> grossByRate;
  final String certificateSerial;

  int get totalCents => grossByRate.values.fold(0, (a, b) => a + b);

  static const List<int> rates = [20, 10, 13, 0, 19];

  static final RegExp _prefix = RegExp(r'^_R1-AT\d+_');

  /// Parse a QR payload; null when it is not an RKSV code.
  static RksvQr? tryParse(String text) {
    final t = text.trim();
    if (!_prefix.hasMatch(t)) return null;
    final parts = t.split('_');
    // parts[0] is '' (leading underscore), parts[1] = R1-AT1
    if (parts.length < 14) return null;
    final ts = DateTime.tryParse(parts[4]);
    if (ts == null) return null;
    final gross = <int, int>{};
    for (var i = 0; i < rates.length; i++) {
      final cents = _cents(parts[5 + i]);
      if (cents == null) return null;
      gross[rates[i]] = cents;
    }
    return RksvQr(
      raw: t,
      kassenId: parts[2],
      belegNummer: parts[3],
      timestamp: ts,
      grossByRate: gross,
      certificateSerial: parts[11],
    );
  }

  static int? _cents(String s) {
    final m = RegExp(r'^(-?)(\d+)[,.](\d{2})$').firstMatch(s.trim());
    if (m == null) return null;
    final v = int.parse(m.group(2)!) * 100 + int.parse(m.group(3)!);
    return m.group(1) == '-' ? -v : v;
  }
}
