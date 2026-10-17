import 'core.dart';
import 'models.dart';

final _sep = RegExp(r'[|,;:\t= ]+');

ImportResult parseCards(String text, {bool repair = true}) {
  final out = <CreditCard>[];
  final seen = <String>{};
  var junk = 0;
  var dup = 0;
  var fixed = 0;
  var exp = 0;

  for (var line in text.split('\n')) {
    line = line.trim();
    if (line.isEmpty) continue;

    final parts = line.split(_sep).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) continue;

    var pan = '';
    var mm = 0;
    var yy = 0;
    var cvv = '';

    for (final p in parts) {
      final d = digitsOf(p);
      if (d.isEmpty) continue;

      if (pan.isEmpty && d.length >= 12 && d.length <= 19) {
        pan = d;
        continue;
      }
      if (p.contains('/')) {
        final sub = p.split('/');
        if (sub.length == 2) {
          final a = digitsOf(sub[0]);
          final b = digitsOf(sub[1]);
          if (a.isNotEmpty && b.isNotEmpty) {
            mm = int.parse(a);
            yy = int.parse(b);
            continue;
          }
        }
      }
      if (mm == 0 && d.length <= 2 && int.parse(d) >= 1 && int.parse(d) <= 12) {
        mm = int.parse(d);
        continue;
      }
      if (yy == 0 && d.length <= 4 && int.parse(d) >= 20) {
        yy = int.parse(d);
        continue;
      }
      if (cvv.isEmpty && (d.length == 3 || d.length == 4)) {
        cvv = d;
        continue;
      }
    }

    if (pan.isEmpty || pan.length < 12) {
      junk++;
      continue;
    }

    if (repair && !luhnOk(pan)) {
      final fixedPan = completeLuhn(pan);
      if (fixedPan != pan && luhnOk(fixedPan)) {
        pan = fixedPan;
        fixed++;
      }
    }

    if (!luhnOk(pan)) {
      junk++;
      continue;
    }

    final brand = brandOf(pan);
    if (pan.length != panLenFor(brand) && pan.length != 16 && pan.length != 15) {
      junk++;
      continue;
    }

    if (mm < 1 || mm > 12) mm = 1;
    if (yy == 0) yy = (DateTime.now().year % 100) + 2;

    if (expiredCard(mm, yy)) exp++;

    final card = CreditCard(
      id: newId(),
      pan: pan,
      expMonth: mm,
      expYear: yy,
      cvv: cvv,
      brand: brand,
      bin: pan.substring(0, 6),
    );

    if (!seen.add(card.key)) {
      dup++;
      continue;
    }
    out.add(card);
  }

  return ImportResult(cards: out, duplicates: dup, junk: junk, fixed: fixed, expired: exp);
}
