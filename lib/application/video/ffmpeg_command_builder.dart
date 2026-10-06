/// Builds only ARES-approved ffmpeg argument lists.
class FfmpegCommandBuilder {
  /// Creates the command builder.
  const FfmpegCommandBuilder();

  /// Builds a safe MP4 render command from already validated local asset paths.
  List<String> buildMp4Command({
    required String outputFileName,
    required int durationSeconds,
    String? videoInput,
    String? audioInput,
  }) {
    final output = _safeFileName(outputFileName, extension: '.mp4');
    if (durationSeconds < 1 || durationSeconds > 86400) {
      throw ArgumentError('Süre 1 ile 86400 saniye arasında olmalıdır.');
    }
    final args = <String>['-y'];
    if (videoInput == null && audioInput == null) {
      throw ArgumentError('Gerçek render için en az bir medya girdisi gerekir.');
    } else {
      if (videoInput != null) args.addAll(<String>['-i', _safeRelativePath(videoInput)]);
      if (audioInput != null) args.addAll(<String>['-i', _safeRelativePath(audioInput)]);
      args.addAll(<String>['-t', '$durationSeconds']);
    }
    args.addAll(<String>['-c:v', 'libx264', '-pix_fmt', 'yuv420p']);
    if (audioInput != null) args.addAll(<String>['-c:a', 'aac']);
    args.add(output);
    return List.unmodifiable(args);
  }

  String _safeFileName(String value, {required String extension}) {
    final trimmed = value.trim();
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$').hasMatch(trimmed) ||
        !trimmed.toLowerCase().endsWith(extension)) {
      throw ArgumentError('Güvenli olmayan çıktı dosya adı.');
    }
    return trimmed;
  }

  String _safeRelativePath(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty || normalized.startsWith('/') || normalized.contains('../') || normalized == '..') {
      throw ArgumentError('Güvenli olmayan medya yolu.');
    }
    return normalized;
  }
}
