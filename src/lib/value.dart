import 'models.dart';

class BalanceRange {
  const BalanceRange(this.lo, this.hi, this.conf, this.note);
  final int lo;
  final int hi;
  final int conf;
  final String note;

  String get text {
    if (hi <= 0) return 'sin datos';
    final l = lo >= 1000 ? '\$${(lo / 1000).toStringAsFixed(1)}k' : '\$$lo';
    final h = hi >= 1000 ? '\$${(hi / 1000).toStringAsFixed(0)}k' : '\$$hi';
    return '$l - $h';
  }
}

BalanceRange estimateBalance(CreditCard card) {
  final level = card.level.toLowerCase();
  final kind = card.kind.toLowerCase();
  var lo = 20;
  var hi = 1500;
  var conf = 0;
  final note = StringBuffer();

  if (kind.contains('prepaid')) {
    lo = 5;
    hi = 300;
    conf++;
    note.write('prepaid ');
  } else if (kind.contains('debit')) {
    lo = 50;
    hi = 2500;
    conf++;
    note.write('debito ');
  } else if (kind.isNotEmpty) {
    lo = 200;
    hi = 5000;
    conf++;
    note.write('credito ');
  }

  if (level.contains('platinum')) {
    lo = lo < 1500 ? 1500 : lo;
    hi = 20000;
    conf++;
    note.write('platinum ');
  } else if (level.contains('signature') || level.contains('world elite')) {
    lo = lo < 2000 ? 2000 : lo;
    hi = 25000;
    conf++;
    note.write('signature ');
  } else if (level.contains('gold')) {
    lo = lo < 800 ? 800 : lo;
    hi = 10000;
    conf++;
    note.write('gold ');
  } else if (level.contains('classic') || level.contains('standard')) {
    conf++;
  }

  final c = card.country.toUpperCase();
  if (c == 'US' || c == 'CA') {
    hi = (hi * 1.3).round();
    conf++;
  } else if (c.isNotEmpty) {
    note.write('${c.toLowerCase()} ');
  }

  if (card.status == CheckStatus.noFunds) {
    note.write('· sin fondos ahora');
  }

  return BalanceRange(lo, hi, conf > 3 ? 3 : conf, note.toString().trim());
}
