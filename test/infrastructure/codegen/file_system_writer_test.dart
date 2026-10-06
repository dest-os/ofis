import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/domain/codegen/artifact_type.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';
import 'package:dest_os_ares/infrastructure/codegen/file_system_writer.dart';

void main() {
  test('blocks path traversal', () async {
    final root = await Directory.systemTemp.createTemp('ares_writer_test_');
    addTearDown(() => root.delete(recursive: true));

    final writer = FileSystemWriter(rootDirectory: root);
    const artifact = CodeArtifact(
      relativePath: '../outside.txt',
      content: 'blocked',
      type: ArtifactType.other,
      generatedBy: 'test',
    );

    expect(
      () => writer.writeArtifact(artifact),
      throwsA(isA<FileSystemWriterException>()),
    );
  });

  test('yazma kökü kaynak ağacından ayrıdır', () async {
    final root = await Directory.systemTemp.createTemp('ares_output_root_test_');
    addTearDown(() => root.delete(recursive: true));
    final writer = FileSystemWriter(rootDirectory: root);
    final result = await writer.writeArtifact(
      const CodeArtifact(
        relativePath: 'ARES_Output/video/demo/README.md',
        content: 'output',
        type: ArtifactType.markdown,
        generatedBy: 'test',
      ),
    );
    expect(result.written, isTrue);
    expect(await File('${root.path}/ARES_Output/video/demo/README.md').readAsString(), 'output');
  });
}
