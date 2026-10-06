import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:dest_os_ares/domain/codegen/generation_result.dart';
import 'package:dest_os_ares/domain/content/content_generation_result.dart';
import 'package:dest_os_ares/domain/content/content_mode.dart';
import 'package:dest_os_ares/presentation/home/ares_home_screen.dart';

void main() {
  testWidgets('ana ekran üç üretim modunu görünür sunar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AresHomeScreen(
        onCodeGenerate: (request, {onProgress}) async => GenerationResult(
          success: true, artifacts: [], errors: [], metrics: {},
        ),
        onContentGenerate: ({required mode, required request, duration = '60 saniye', style = 'style', platform = 'platform', contentType = 'type', onProgress}) async => ContentGenerationResult(
          success: true, artifacts: [], errors: [], suggestedActions: [], metrics: {},
        ),
      ),
    ));
    expect(find.text('Mobil Uygulama Üret'), findsOneWidget);
    expect(find.text('Video İçerik Üret'), findsOneWidget);
    expect(find.text('Genel İçerik Üret'), findsOneWidget);
  });

  test('content mode labels are stable', () {
    expect(ContentMode.mobileApp.label, 'Mobil Uygulama Üret');
    expect(ContentMode.video.label, 'Video İçerik Üret');
    expect(ContentMode.general.label, 'Genel İçerik Üret');
  });
}
