import 'dart:math';

import 'core.dart';
import 'models.dart';

class GenSpec {
  GenSpec({
    required this.bin,
    this.count = 10,
    this.len = 16,
    this.month = 0,
    this.year = 0,
    this.cvv = '',
  });
  final String bin;
  final int count;
  final int len;
  final int month;
  final int year;
  final String cvv;
}

List<CreditCard> generate(GenSpec spec) {
  final r = Random();
  final out = <CreditCard>[];
  final seen = <String>{};
  final now = DateTime.now();
  final base = digitsOf(spec.bin);
  if (base.isEmpty) return out;

  final baseBrand = brandOf(base);
  final target = spec.len == 16 ? panLenFor(baseBrand) : spec.len;

  var guard = 0;
  while (out.length < spec.count && guard < spec.count * 40) {
    guard++;
    final b = StringBuffer(base);
    while (b.length < target - 1) {
      b.write(r.nextInt(10));
    }
    final pan = completeLuhn(b.toString());
    if (!seen.add(pan)) continue;

    final brand = brandOf(pan);
    final mm = spec.month >= 1 && spec.month <= 12 ? spec.month : 1 + r.nextInt(12);
    final yy = spec.year >= 1 ? spec.year : (now.year % 100) + 2 + r.nextInt(6);
    final cvv = spec.cvv.isNotEmpty
        ? spec.cvv
        : brand == 'amex'
            ? (1000 + r.nextInt(9000)).toString()
            : (100 + r.nextInt(900)).toString();

    out.add(
      CreditCard(
        id: newId(),
        pan: pan,
        expMonth: mm,
        expYear: yy,
        cvv: cvv,
        brand: brand,
        bin: pan.substring(0, 6),
      ),
    );
  }
  return out;
}
