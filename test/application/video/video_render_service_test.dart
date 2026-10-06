import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/infrastructure/video/ffmpeg_command_runner.dart';

void main() {
  test('render açık onay olmadan çalışmaz', () async {
    final root = await Directory.systemTemp.createTemp('ares_render_guard_');
    addTearDown(() => root.delete(recursive: true));
    final result = await const FfmpegCommandRunner().run(
      arguments: const <String>['-y', '-i', 'assets/video_source.mp4', 'render.mp4'],
      outputRoot: root,
      explicitUserApproval: false,
    );
    expect(result.success, isFalse);
    expect(result.message, contains('açık kullanıcı onayı'));
  });
}
