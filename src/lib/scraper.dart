import 'checker.dart';
import 'models.dart';

class FetchResult {
  FetchResult({required this.text, required this.note, this.ok = false});
  final String text;
  final String note;
  final bool ok;
}

Future<FetchResult> fetchList(String url, Settings cfg) async {
  final engine = CheckEngine(cfg);
  try {
    final txt = await engine.fetchText(url);
    final lines = txt.split('\n').where((l) => l.trim().isNotEmpty).length;
    return FetchResult(text: txt, note: '$lines lineas', ok: true);
  } catch (e) {
    return FetchResult(text: '', note: '$e');
  } finally {
    engine.dispose();
  }
}
