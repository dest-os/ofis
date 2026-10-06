import 'dart:async';
import 'dart:io';

import '../../application/video/ffmpeg_command_builder.dart';

/// Reports whether the local ffmpeg executable can be invoked safely.
class FfmpegHealth {
  /// Creates an ffmpeg health result.
  const FfmpegHealth({required this.available, required this.message});

  /// Whether ffmpeg responded successfully.
  final bool available;

  /// Human-readable status.
  final String message;
}

/// Runs only ARES-generated ffmpeg commands inside a selected output directory.
class FfmpegCommandRunner {
  /// Creates a runner with an optional executable name for testing.
  const FfmpegCommandRunner({this.executable = 'ffmpeg', this.timeout = const Duration(minutes: 10)});

  /// Executable name resolved by the operating system.
  final String executable;

  /// Maximum allowed render duration.
  final Duration timeout;

  /// Checks whether ffmpeg is available.
  Future<FfmpegHealth> healthCheck() async {
    try {
      final result = await Process.run(executable, const <String>['-version'], runInShell: false).timeout(const Duration(seconds: 5));
      if (result.exitCode == 0) {
        return const FfmpegHealth(available: true, message: 'ffmpeg hazır.');
      }
      return const FfmpegHealth(available: false, message: 'ffmpeg bulundu ancak çalıştırılamadı.');
    } on TimeoutException {
      return const FfmpegHealth(available: false, message: 'ffmpeg sağlık kontrolü zaman aşımına uğradı.');
    } catch (_) {
      return const FfmpegHealth(available: false, message: 'ffmpeg bulunamadı. Render için ffmpeg kurulmalıdır.');
    }
  }

  /// Executes a prebuilt ARES command only after the caller explicitly enables rendering.
  Future<VideoRenderResult> run({
    required List<String> arguments,
    required Directory outputRoot,
    required bool explicitUserApproval,
  }) async {
    if (!explicitUserApproval) {
      return const VideoRenderResult(success: false, message: 'Render çalıştırmak için açık kullanıcı onayı gerekir.', outputFile: null);
    }
    final executableHealth = await healthCheck();
    if (!executableHealth.available) {
      return VideoRenderResult(success: false, message: executableHealth.message, outputFile: null);
    }
    if (!_safeArguments(arguments)) {
      return const VideoRenderResult(success: false, message: 'Güvenli olmayan ffmpeg komutu reddedildi.', outputFile: null);
    }
    try {
      await outputRoot.create(recursive: true);
      final process = await Process.start(executable, arguments, workingDirectory: outputRoot.path, runInShell: false);
      final exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
        process.kill(ProcessSignal.sigterm);
        return -1;
      });
      if (exitCode != 0) {
        return VideoRenderResult(success: false, message: 'ffmpeg render başarısız oldu. Çıkış kodu: $exitCode', outputFile: null);
      }
      final outputName = _findOutput(arguments);
      if (outputName == null) {
        return const VideoRenderResult(success: false, message: 'Render çıktısı tanımlı değil.', outputFile: null);
      }
      final output = File('${outputRoot.path}${Platform.pathSeparator}$outputName');
      if (!await output.exists() || await output.length() == 0) {
        return const VideoRenderResult(success: false, message: 'Render tamamlanmadı: gerçek çıktı dosyası oluşmadı.', outputFile: null);
      }
      return VideoRenderResult(success: true, message: 'Render tamamlandı.', outputFile: output.path);
    } catch (error) {
      return VideoRenderResult(success: false, message: 'Render çalıştırılamadı: $error', outputFile: null);
    }
  }

  bool _safeArguments(List<String> args) {
    if (args.isEmpty || args.length > 40) return false;
    const flags = <String>{'-y', '-f', '-i', '-t', '-c:v', '-pix_fmt', '-c:a'};
    const values = <String>{'lavfi', 'color=c=black:s=1280x720:r=30', 'libx264', 'yuv420p', 'aac'};
    for (final arg in args) {
      if (arg.contains(RegExp(r'[;&|`$<>]'))) return false;
    }
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (flags.contains(arg)) continue;
      if (values.contains(arg)) continue;
      if (RegExp(r'^\d+$').hasMatch(arg)) continue;
      if (RegExp(r'^[A-Za-z0-9_./-]+\.(mp4|mov|m4a|wav|mp3)$', caseSensitive: false).hasMatch(arg)) {
        if (arg.startsWith('/') || arg.contains('../') || arg == '..') return false;
        continue;
      }
      return false;
    }
    return args.contains('-i') && args.any((value) => value.toLowerCase().endsWith('.mp4'));
  }

  String? _findOutput(List<String> args) {
    for (var i = args.length - 1; i >= 0; i--) {
      final value = args[i];
      if (value.toLowerCase().endsWith('.mp4')) return value;
    }
    return null;
  }
}

/// Result of an actual ffmpeg invocation.
class VideoRenderResult {
  /// Creates a render result.
  const VideoRenderResult({required this.success, required this.message, required this.outputFile});

  /// Whether a real output file was created.
  final bool success;

  /// Human-readable result message.
  final String message;

  /// Absolute output path when successful.
  final String? outputFile;
}
