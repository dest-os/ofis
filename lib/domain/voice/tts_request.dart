class TtsRequest {
  const TtsRequest({required this.text, this.languageCode = 'tr-TR'});

  final String text;
  final String languageCode;
}
