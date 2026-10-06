# DEST-OS ARES V18 – Agent Runtime + AI Gateway

V18, V17 Runtime katmanının üzerine Agent Runtime ve AI Gateway güvenlik temelini ekler.

## Eklenenler
- Agent Run ve durumları
- Agent Execution Contract
- Agent Context Builder
- Agent Decision Loop
- Agent Execution Service
- Structured Output Validator
- AI Capability Profile
- AI Routing Decision
- AI Request Router
- AI Gateway Service

## Güvenlik kuralı
Ücretli veya fiyat/lisans bilgisi doğrulanmamış AI otomatik çalıştırılmaz. Bu istekler `WAITING_APPROVAL` sonucuna gider.

Yerel AI için V18 yalnızca runtime/gateway sözleşmesini sağlar; gerçek model adapteri ve cihaz benchmarkı daha sonraki aşamada bağlanacaktır.
