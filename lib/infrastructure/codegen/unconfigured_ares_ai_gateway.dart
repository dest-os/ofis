import '../../application/ai/ai_gateway.dart';
import '../../core/result/ares_result.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';

/// ARES AI Gateway sağlayıcısı yapılandırılmadığında kullanılan güvenli adaptördür.
///
/// Ağ çağrısı yapmaz ve üretim yapıyormuş gibi davranmaz. Kullanıcıya gerçek
/// sağlayıcının yapılandırılması gerektiğini açıkça bildirir.
class UnconfiguredAresAiGateway implements AresAiGateway {
  /// Creates the unconfigured gateway.
  const UnconfiguredAresAiGateway();

  /// Returns a configuration error without making a network request.
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    return const AresFailure<AiResponse>(
      'Gerçek ARES AI Gateway yapılandırılmamış. Kod üretimi için doğrulanmış '
      'bir AI sağlayıcısını mevcut AI Gateway üzerinden yapılandırın. '
      'UI yolu sessizce Mock AI\'ya düşmez.',
    );
  }
}
