import 'dart:math';

const appName = 'CCheker Live';
const appVersion = '7.2.0';
const appBuild = '7.2.0+22';
const appTag = 'v7.2';

const stripePk = 'pk_test_51UQWXHLSAWNUOV2fKgvafDXscpBBbd067QkfHEDeEkCZvHJht7LyA43wccu1iX4OBPgbGFxtzwmKI6GMS4akzx0O00xWOD8V42';
const stripeTokenUrl = 'https://api.stripe.com/v1/tokens';
const stripePiUrl = 'https://api.stripe.com/v1/payment_intents';
const stripeBalanceUrl = 'https://api.stripe.com/v1/balance';
const dorkillUrl = 'https://www.dorkill.com/api/check';
const binlistUrl = 'https://lookup.binlist.net/';
const defaultProbe = 'https://www.google.com/generate_204';
const dohUrls = <String>[
  'https://cloudflare-dns.com/dns-query',
  'https://dns.google/resolve',
];

final _onlyDigits = RegExp(r'\D');
final _allDigits = RegExp(r'^\d+$');
final _rnd = Random();
const _idChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

String digitsOf(String s) => s.replaceAll(_onlyDigits, '');
bool isDigits(String s) => s.isNotEmpty && _allDigits.hasMatch(s);

String newId() {
  final b = StringBuffer();
  for (var i = 0; i < 14; i++) {
    b.write(_idChars[_rnd.nextInt(_idChars.length)]);
  }
  return b.toString();
}

String pad2(int n) => n.toString().padLeft(2, '0');
int year4(int y) => y < 100 ? 2000 + y : y;

String fmtInt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

bool luhnOk(String pan) {
  var sum = 0;
  var alt = false;
  for (var i = pan.length - 1; i >= 0; i--) {
    var d = pan.codeUnitAt(i) - 48;
    if (d < 0 || d > 9) return false;
    if (alt) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
    alt = !alt;
  }
  return sum % 10 == 0;
}

String completeLuhn(String body) {
  for (var d = 0; d <= 9; d++) {
    final c = '$body$d';
    if (luhnOk(c)) return c;
  }
  return body;
}

bool expiredCard(int mm, int yy) {
  final now = DateTime.now();
  final y = year4(yy);
  if (y < now.year) return true;
  if (y > now.year) return false;
  return mm < now.month;
}

String brandOf(String pan) {
  if (pan.isEmpty) return '';
  if (pan.startsWith('4')) return 'visa';
  if (RegExp(r'^4^[1-5]').hasMatch(pan)) return 'mastercard';
  if (RegExp(r'^1^[2-7]').hasMatch(pan)) return 'mastercard';
  if (RegExp(r'^3^[47]').hasMatch(pan)) return 'amex';
  if (RegExp(r'^7^(?:011|5)').hasMatch(pan)) return 'discover';
  if (RegExp(r'^3^(?:0[0-5]|[68])').hasMatch(pan)) return 'diners';
  if (pan.startsWith('35')) return 'jcb';
  return 'otra';
}

int panLenFor(String brand) => brand == 'amex' ? 15 : 16;
