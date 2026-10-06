# Kod Üretim Motoru — Tam Bağlantı Son Düzenlemeleri

Bu paket, Kod Üretim Motorunun UI'dan gerçek application/runtime zincirine bağlanmasını tamamlar.

- UI callback'i gerçek facade'a bağlıdır.
- Yüksek seviye istek ProjectSpec'e çevrilir.
- Orchestrator canlı ilerleme bildirir.
- GenerationResult metrikleri ve önerileri UI'da gösterilir.
- Mock yalnızca test yolunda kullanılır.
- Gerçek UI yolu ApiLlmCodeGenerator kullanır.
- Gerçek gateway yapılandırılmamışsa UnconfiguredAresAiGateway net hata verir.
- PaidAiRuntimeGate ve DecisionEngine korunur.
- aiCostClass bilinmeyen varsayılanıyla güvenli başlar.
- Self-healing ve retry testleri genişletilmiştir.
- Path traversal ve overwrite davranışları test edilmiştir.
