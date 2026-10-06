import 'dart:io';

import '../../domain/codegen/code_artifact.dart';
import '../codegen/code_writer_service.dart';
import 'ffmpeg_command_builder.dart';
import '../../infrastructure/video/ffmpeg_command_runner.dart';

/// Creates safe video render plans and optionally executes them with explicit approval.
class VideoRenderService {
  /// Creates the video render service.
  const VideoRenderService({FfmpegCommandBuilder builder = const FfmpegCommandBuilder(), FfmpegCommandRunner runner = const FfmpegCommandRunner()})
      : _builder = builder,
        _runner = runner;

  final FfmpegCommandBuilder _builder;
  final FfmpegCommandRunner _runner;

  /// Writes a deterministic render plan into the supplied video output root.
  Future<CodeWriteResult> writeRenderPlan({required CodeWriterService writer, required String relativeRoot, required int durationSeconds}) async {
    final args = _builder.buildMp4Command(outputFileName: 'render.mp4', durationSeconds: durationSeconds);
    final artifact = CodeArtifact(relativePath: '$relativeRoot/render_plan.json', content: _json(args, durationSeconds), type: ArtifactType.json, generatedBy: 'VideoRenderService');
    return writer.writeArtifacts(<CodeArtifact>[artifact], overwrite: false);
  }

  /// Runs a previously built ARES ffmpeg command after explicit user approval.
  Future<VideoRenderResult> render({required List<String> arguments, required Directory outputRoot, required bool explicitUserApproval}) =>
      _runner.run(arguments: arguments, outputRoot: outputRoot, explicitUserApproval: explicitUserApproval);

  /// Checks local ffmpeg availability.
  Future<FfmpegHealth> healthCheck() => _runner.healthCheck();

  String _json(List<String> args, int duration) {
    final escaped = args.map((value) => '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"').join(', ');
    return '{\n  "durationSeconds": $duration,\n  "executable": "ffmpeg",\n  "arguments": [$escaped],\n  "automaticExecution": false\n}\n';
  }
}
