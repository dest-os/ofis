import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/domain/content/content_generation_result.dart';
import 'package:dest_os_ares/domain/content/content_mode.dart';
import 'package:dest_os_ares/domain/codegen/generation_result.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';
import 'package:dest_os_ares/domain/codegen/artifact_type.dart';
import 'package:dest_os_ares/presentation/codegen/code_generation_screen.dart';
import 'package:dest_os_ares/presentation/content/content_generation_screen.dart';

void main() {
  testWidgets('kod üretimi sırasında eski ÜRET butonu görünmez', (tester) async {
    final future = Future<GenerationResult>.delayed(
      const Duration(milliseconds: 200),
      () => GenerationResult(success: true, artifacts: <CodeArtifact>[], errors: <String>[], metrics: <String, Object?>{}),
    );
    await tester.pumpWidget(MaterialApp(home: CodeGenerationScreen(onGenerate: (_, {onProgress}) => future)));
    await tester.enterText(find.byType(TextField), 'Bir uygulama üret');
    await tester.tap(find.text('ÜRET'));
    await tester.pump();
    expect(find.text('ÜRETİLİYOR...'), findsOneWidget);
    expect(find.text('ÜRET'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('içerik ekranında canlı durum ve sonuç ayrı alanlardadır', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContentGenerationScreen(
          mode: ContentMode.general,
          onGenerate: ({required mode, required request, duration = '', style = '', platform = '', contentType = '', onProgress}) async {
            onProgress?.call('İçerik hazırlanıyor');
            return ContentGenerationResult(
              success: true,
              artifacts: <CodeArtifact>[
                CodeArtifact(relativePath: 'README.md', content: '# test', type: ArtifactType.markdown, generatedBy: 'test'),
              ],
              errors: <String>[],
              suggestedActions: <String>[],
              metrics: <String, Object?>{},
            );
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Bir genel içerik üret');
    await tester.tap(find.text('ÜRET'));
    await tester.pumpAndSettle();
    expect(find.text('CANLI DURUM'), findsOneWidget);
    expect(find.text('SONUÇ'), findsOneWidget);
    expect(find.text('İçerik hazırlanıyor'), findsNothing);
    expect(find.text('Üretim tamamlandı'), findsOneWidget);
  });
}
