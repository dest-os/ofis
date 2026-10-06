import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/codegen/code_writer_service.dart';
import 'package:dest_os_ares/domain/codegen/artifact_type.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';
import 'package:dest_os_ares/infrastructure/codegen/file_system_writer.dart';

void main() {
  test('writer service returns written paths and does not overwrite by default', () async {
    final root = await Directory.systemTemp.createTemp('ares_writer_');
    addTearDown(() => root.delete(recursive: true));

    final service = CodeWriterService(writer: FileSystemWriter(rootDirectory: root));
    const artifact = CodeArtifact(
      relativePath: 'codegen_test.txt',
      content: 'ARES',
      type: ArtifactType.other,
      generatedBy: 'test',
    );

    final first = await service.writeArtifacts(const [artifact]);
    expect(first.writtenPaths, contains('codegen_test.txt'));

    const secondArtifact = CodeArtifact(
      relativePath: 'codegen_test.txt',
      content: 'CHANGED',
      type: ArtifactType.other,
      generatedBy: 'test',
    );
    final second = await service.writeArtifacts(const [secondArtifact]);
    expect(second.errors.single, contains('üzerine yazma kapalı'));
    expect(await File('${root.path}/codegen_test.txt').readAsString(), 'ARES');
  });

  test('writer service path traversal isteğini reddeder', () async {
    final root = await Directory.systemTemp.createTemp('ares_writer_security_');
    addTearDown(() => root.delete(recursive: true));

    final service = CodeWriterService(writer: FileSystemWriter(rootDirectory: root));
    const artifact = CodeArtifact(
      relativePath: '../escape.txt',
      content: 'BLOCKED',
      type: ArtifactType.other,
      generatedBy: 'test',
    );

    final result = await service.writeArtifacts(const [artifact]);
    expect(result.success, isFalse);
    expect(result.errors.single, contains('Path traversal'));
    expect(await File('${root.parent.path}/escape.txt').exists(), isFalse);
  });
}
