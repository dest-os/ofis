import '../../domain/codegen/project_spec.dart';
import 'project_spec_from_request.dart';

/// Backward-compatible facade for converting high-level requests to ProjectSpec.
class ProjectSpecFromPromptService {
  /// Creates the request converter facade.
  const ProjectSpecFromPromptService({ProjectSpecFromRequest converter = const ProjectSpecFromRequest()})
      : _converter = converter;

  final ProjectSpecFromRequest _converter;

  /// Builds a [ProjectSpec] from [request].
  ProjectSpec build(String request) => _converter.build(request);
}
