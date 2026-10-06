import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/video/ffmpeg_command_builder.dart';

void main() {
  test('ffmpeg komutu güvenli ve shell bağımsız argümanlardan oluşur', () {
    final args = const FfmpegCommandBuilder().buildMp4Command(
      outputFileName: 'render.mp4',
      durationSeconds: 60,
      videoInput: 'assets/video_source.mp4',
    );
    expect(args, contains('assets/video_source.mp4'));
    expect(args.last, 'render.mp4');
    expect(args.any((value) => value.contains(';')), isFalse);
  });

  test('path traversal ve enjeksiyon denemesi reddedilir', () {
    expect(
      () => const FfmpegCommandBuilder().buildMp4Command(
        outputFileName: '../render.mp4',
        durationSeconds: 60,
        videoInput: 'assets/video_source.mp4',
      ),
      throwsArgumentError,
    );
    expect(
      () => const FfmpegCommandBuilder().buildMp4Command(
        outputFileName: 'render.mp4;touch-pwned.mp4',
        durationSeconds: 60,
        videoInput: 'assets/video_source.mp4',
      ),
      throwsArgumentError,
    );
  });
}
