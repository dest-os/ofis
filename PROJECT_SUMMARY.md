# DEST-OS ARES Production Summary

## Üretim merkezleri

ARES tablet ana ekranından üç mod açılır:

1. Mobil Uygulama Üret
2. Video İçerik Üret
3. Genel İçerik Üret

## Mobil akış

Yüksek seviye fikir → ProjectSpec → Scaffold → ajanlar → gerçek Local/Free AI → Validator/Self-Healing → Build Readiness → güvenli ayrı output root.

Zorunlu proje çıktıları: `lib/main.dart`, `lib/app/app.dart`, domain/application/presentation Dart dosyaları, `pubspec.yaml`, `analysis_options.yaml`, `README.md`, `BUILD_READY.md`, `SMOKE_CHECKLIST.md`.

## Video akışı

Yüksek seviye fikir + süre + stil + platform → Product Manager → Architect → Specialist Producer → QA → DevOps → kalite kapısı → ayrı video output.

Zorunlu dosyalar: `video_brief.md`, `script.md`, `shot_list.md`, `voiceover_script.md`, `captions.srt`, `thumbnail_prompt.md`, `production_checklist.md`, `assets_plan.md`, `timeline.json`, `render_plan.json`.

Gerçek render yalnız kullanıcı açıkça başlatırsa çalışır. ffmpeg yoksa render yapılmış kabul edilmez.

## AI sırası

Local Ollama/LM Studio → yapılandırılmış Free/Limited-Free endpoint → açık onay gerektiren Paid/Unknown kapısı. Üretim UI'sı Mock'a sessizce düşmez.

## Güvenlik

PaidAiRuntimeGate/DecisionEngine, path traversal koruması, ayrı output root, shell kapalı ffmpeg çalıştırma, timeout ve allowlist korunur.

## Ortam bağımlılıkları

Gerçek AI için Ollama/LM Studio veya doğrulanmış ücretsiz endpoint erişilebilir olmalıdır. APK/analyze/test için Flutter SDK gerekir. Gerçek video render için ffmpeg ve kullanıcı tarafından sağlanan/lisansı doğrulanmış medya girdileri gerekir.

## Son kontrol listesi

- [x] Tablet üretim merkezi
- [x] Mobil üretim
- [x] Video paket üretimi
- [x] Genel içerik üretimi
- [x] Local/Free AI fallback
- [x] Sessiz Mock yok
- [x] Build readiness
- [x] Ayrı mobil output root
- [x] Ayrı video output root
- [x] ffmpeg komut allowlist'i
- [x] Açık render onayı
- [x] Path traversal koruması
- [x] Paid/unknown AI kapısı
- [x] Health/status kartı
- [x] Edge-case testleri
