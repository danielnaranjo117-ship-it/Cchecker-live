import 'core.dart';
import 'checker.dart';
import 'models.dart';
import 'value.dart';

class TestLine {
  TestLine(this.name, this.ok, this.note);
  final String name;
  final bool ok;
  final String note;
}

class SelfTest {
  static List<TestLine> local() {
    final out = <TestLine>[];

    void t(String name, bool Function() fn) {
      try {
        out.add(TestLine(name, fn(), ''));
      } catch (e) {
        out.add(TestLine(name, false, '$e'));
      }
    }

    t('luhn acepta 4242', () => luhnOk('4242424242424242'));
    t('luhn rechaza 4243', () => !luhnOk('4242424242424243'));
    t('repara 4111111111111112', () => completeLuhn('411111111111111') == '4111111111111111');
    t('marca visa', () => brandOf('4111111111111111') == 'visa');
    t('marca amex', () => brandOf('378282246310005') == 'amex');
    t('marca mastercard', () => brandOf('5555555555554444') == 'mastercard');
    t('amex pide 15 digitos', () => panLenFor('amex') == 15);
    t('vencida 01/20', () => expiredCard(1, 20));
    t('no vencida 12/40', () => !expiredCard(12, 40));
    t('sin fondos no es muerta',
        () => CheckEngine.mapStripe('insufficient_funds', '') == CheckStatus.noFunds);
    t('3ds detectado',
        () => CheckEngine.mapStripe('authentication_required', '') == CheckStatus.need3ds);
    t('cvv malo no es muerta',
        () => CheckEngine.mapStripe('incorrect_cvc', '') == CheckStatus.cvcFail);
    t('generico es muerta',
        () => CheckEngine.mapStripe('generic_decline', '') == CheckStatus.dead);
    t('cobrable incluye cvv malo', () => CheckStatus.cvcFail.cobrable);
    t('muerta no es cobrable', () => !CheckStatus.dead.cobrable);
    t('live gana en rank', () => CheckStatus.live.rank < CheckStatus.dead.rank);

    final fake = CreditCard(
      id: 'x',
      pan: '4111111111111111',
      expMonth: 1,
      expYear: 30,
      kind: 'credit',
    );
    t('estimador de credito da rango', () => estimateBalance(fake).hi > 0);

    return out;
  }
}
