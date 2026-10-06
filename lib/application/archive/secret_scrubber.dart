/// Arşive yazılmadan önce API anahtarı, token ve parola benzeri metinleri gizler.
class SecretScrubber {
  const SecretScrubber();

  static final List<RegExp> _patterns = <RegExp>[
    RegExp(r'sk-[A-Za-z0-9_\-]{16,}'),
    RegExp(r'AIza[0-9A-Za-z_\-]{20,}'),
    RegExp(r'gh[pousr]_[A-Za-z0-9]{20,}'),
    RegExp(r'Bearer\s+[A-Za-z0-9._\-]{16,}', caseSensitive: false),
    RegExp(r'(api[_ -]?key|apikey|token|password|secret|şifre|parola|anahtar)\s*[:=]\s*\S+', caseSensitive: false),
  ];

  /// [input] içindeki gizli değerleri "[GİZLİ]" ile değiştirir.
  String scrub(String input, {List<String> extraSecrets = const <String>[]}) {
    var output = input;
    for (final secret in extraSecrets) {
      final trimmed = secret.trim();
      if (trimmed.length >= 6) {
        output = output.replaceAll(trimmed, '[GİZLİ]');
      }
    }
    for (final pattern in _patterns) {
      output = output.replaceAll(pattern, '[GİZLİ]');
    }
    return output;
  }
}
