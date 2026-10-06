import '../../application/ai/ai_gateway.dart';
import '../../application/settings/ares_settings.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import 'fallback_ares_ai_gateway.dart';
import 'free_remote_ai_gateway_adapter.dart';
import 'local_ai_gateway_adapter.dart';
import 'openai_compatible_transport.dart';

/// Ayarlar ekranındaki güncel bilgilere göre her istekte sağlayıcıyı seçen gateway.
///
/// Ayar değişince uygulamayı yeniden derlemeye veya açmaya gerek kalmaz.
class DynamicAresAiGateway implements AresAiGateway {
  DynamicAresAiGateway({required this.settings, this.transport});

  final AresSettingsStore settings;

  /// Testlerde sahte HTTP vermek için.
  final AiHttpTransport? transport;

  static const String notConfiguredMessage =
      'Yapay zekâ ayarlanmamış. Ana ekranda CEO masasındaki Ayarlar bölümünden bir sağlayıcı girin.';

  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    final current = settings.current;
    if (!current.anyConfigured) {
      return const AresFailure<AiResponse>(notConfiguredMessage);
    }
    if (request.costClass == AiCostClass.paid || request.costClass == AiCostClass.unknown) {
      return const AresFailure<AiResponse>('Paid/unknown AI yolu otomatik olarak açılmaz.');
    }

    final AresAiGateway? free = current.freeConfigured
        ? FreeRemoteAiGatewayAdapter(
            baseUrl: current.freeBaseUrl,
            model: current.freeModel,
            apiKey: current.freeApiKey.trim().isEmpty ? null : current.freeApiKey,
            transport: transport,
          )
        : null;

    if (!current.localEnabled) {
      // Yalnızca uzak sağlayıcı yapılandırılmış (anyConfigured bunu garanti eder).
      return free!.generate(request);
    }

    final local = LocalAiGatewayAdapter(
      baseUrl: current.localBaseUrl,
      model: current.localModel,
      transport: transport,
    );
    return FallbackAresAiGateway(local: local, free: free).generate(request);
  }
}
