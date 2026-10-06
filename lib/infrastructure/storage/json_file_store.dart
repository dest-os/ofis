import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Uygulamanın özel klasöründe küçük JSON dosyalarını kalıcı saklar.
///
/// Yazma işlemi önce geçici dosyaya yapılır, sonra yeniden adlandırılır;
/// böylece yazma sırasında uygulama kapansa bile eski veri bozulmaz.
class JsonFileStore {
  /// [directoryProvider] testlerde geçici klasör vermek için kullanılır.
  JsonFileStore({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file(String name) async {
    final base = await _directoryProvider();
    final dir = Directory('${base.path}/ares_data');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$name.json');
  }

  /// Kayıtlı JSON'u okur. Dosya yoksa veya bozuksa null döner.
  Future<Object?> read(String name) async {
    try {
      final file = await _file(name);
      if (!await file.exists()) return null;
      final text = await file.readAsString();
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  /// JSON'a çevrilebilir [data] değerini kalıcı olarak yazar.
  Future<void> write(String name, Object? data) async {
    final file = await _file(name);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(data), flush: true);
    await temp.rename(file.path);
  }
}
