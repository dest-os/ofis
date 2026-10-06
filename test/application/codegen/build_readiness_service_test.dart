import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/codegen/build_readiness_service.dart';
import 'package:dest_os_ares/domain/codegen/artifact_type.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';

void main() {
  test('tam Flutter iskeleti build-ready olur', () {
    const artifacts = <CodeArtifact>[
      CodeArtifact(relativePath: 'lib/main.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/domain/model.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/application/service.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/presentation/home.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'pubspec.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'analysis_options.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'README.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'BUILD_READY.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'SMOKE_CHECKLIST.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
    ];
    expect(const BuildReadinessService().evaluate(artifacts).ready, isTrue);
  });

  test('eksik application dosyası build-ready sayılmaz', () {
    const artifacts = <CodeArtifact>[
      CodeArtifact(relativePath: 'lib/main.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/domain/model.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/presentation/home.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'pubspec.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'analysis_options.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'README.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'BUILD_READY.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'SMOKE_CHECKLIST.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
    ];
    expect(const BuildReadinessService().evaluate(artifacts).ready, isFalse);
  });

  test('eksik main veya pubspec build-ready sayılmaz', () {
    const withoutMain = <CodeArtifact>[
      CodeArtifact(relativePath: 'lib/domain/model.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/application/service.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/presentation/home.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'pubspec.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'analysis_options.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'README.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'BUILD_READY.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'SMOKE_CHECKLIST.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
    ];

    const withoutPubspec = <CodeArtifact>[
      CodeArtifact(relativePath: 'lib/main.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/domain/model.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/application/service.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/presentation/home.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'analysis_options.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'README.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'BUILD_READY.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'SMOKE_CHECKLIST.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
    ];

    final service = const BuildReadinessService();
    expect(service.evaluate(withoutMain).ready, isFalse);
    expect(service.evaluate(withoutPubspec).ready, isFalse);
  });
}
