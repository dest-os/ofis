import '../../domain/ai_radar/ai_radar_candidate.dart';

/// Güvenli, önceden tanımlı AI aday kataloğunu sağlar.
///
/// Bu servis hiçbir sağlayıcıyı otomatik etkinleştirmez ve API anahtarı istemez.
class AiRadarService {
  const AiRadarService();

  List<AiRadarCandidate> catalog() => const [
        AiRadarCandidate(
          id: 'qwen2.5-coder-1.5b-local',
          name: 'Qwen2.5-Coder 1.5B',
          type: AiRadarCandidateType.local,
          model: 'qwen2.5-coder:1.5b',
          address: 'http://127.0.0.1:11434',
          description: 'Yerel kod odaklı model adayı. Küçük işler için uygundur.',
          configurationHint: 'Yerel AI ayarlarında adres ve model adıyla yapılandırılabilir.',
        ),
        AiRadarCandidate(
          id: 'groq-free-candidate',
          name: 'Groq',
          type: AiRadarCandidateType.limited,
          model: 'Sağlayıcıdaki güncel ücretsiz/deneme modeli',
          description: 'Hızlı metin ve kod işleri için sağlayıcı adayı. Ücretsiz kullanım sınırları değişebilir.',
          configurationHint: 'Ayarlar > Yedek AI alanından güncel sağlayıcı bilgileriyle yapılandırılabilir.',
        ),
        AiRadarCandidate(
          id: 'gemini-free-candidate',
          name: 'Gemini',
          type: AiRadarCandidateType.limited,
          model: 'Sağlayıcıdaki güncel ücretsiz kullanım modeli',
          description: 'Metin ve analiz işleri için sağlayıcı adayı. Ücretsiz kullanım koşulları değişebilir.',
          configurationHint: 'Ayarlar > Yedek AI alanından güncel sağlayıcı bilgileriyle yapılandırılabilir.',
        ),
      ];
}
