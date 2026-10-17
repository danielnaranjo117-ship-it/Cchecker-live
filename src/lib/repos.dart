import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';

class Vault {
  static SharedPreferences? _p;
  static String _pin = '';
  static bool hasPin = false;

  static bool get unlocked => !hasPin || _pin.isNotEmpty;
  static bool get needsUnlock => hasPin && _pin.isEmpty;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    hasPin = (_p!.getString('pin_hash') ?? '').isNotEmpty;
  }

  static String _hash(String pin) {
    final salt = _p!.getString('salt') ?? '';
    return sha256.convert(utf8.encode('$salt|$pin|ccheker')).toString();
  }

  static Future<void> setPin(String pin) async {
    if ((_p!.getString('salt') ?? '').isEmpty) {
      await _p!.setString('salt', DateTime.now().microsecondsSinceEpoch.toString());
    }
    await _p!.setString('pin_hash', _hash(pin));
    await _p!.setString('pin_plain', pin);
    hasPin = true;
    _pin = pin;
  }

  static bool checkPin(String pin) => _hash(pin) == _p!.getString('pin_hash');

  static void unlock(String pin) => _pin = pin;

  static void lock() => _pin = '';

  static Uint8List _key() =>
      Uint8List.fromList(sha256.convert(utf8.encode(_hash(_pin))).bytes);

  static String _enc(String plain) {
    if (_pin.isEmpty) return plain;
    final iv = enc.IV.fromSecureRandom(16);
    final e = enc.Encrypter(enc.AES(enc.Key(_key()), mode: enc.AESMode.cbc));
    return 'enc:${iv.base64}:${e.encrypt(plain, iv: iv).base64}';
  }

  static String _dec(String raw) {
    if (!raw.startsWith('enc:')) return raw;
    if (_pin.isEmpty) return raw;
    final parts = raw.split(':');
    final e = enc.Encrypter(enc.AES(enc.Key(_key()), mode: enc.AESMode.cbc));
    return e.decrypt64(parts[2], iv: enc.IV.fromBase64(parts[1]));
  }

  static Future<void> put(String k, String v) async {
    await _p!.setString(k, _enc(v));
  }

  static String get(String k, [String def = '']) {
    final raw = _p!.getString(k);
    if (raw == null || raw.isEmpty) return def;
    try {
      return _dec(raw);
    } catch (_) {
      return def;
    }
  }

  static Future<void> wipe() async {
    await _p!.remove('cards');
    await _p!.remove('settings');
    await _p!.remove('proxies');
  }
}
