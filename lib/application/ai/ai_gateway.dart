import '../../core/result/ares_result.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';

abstract interface class AresAiGateway {
  Future<AresResult<AiResponse>> generate(AiRequest request);
}
