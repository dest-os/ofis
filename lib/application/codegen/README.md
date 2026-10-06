# DEST-OS ARES Kod Üretim Motoru

## Tablet ilk kurulum

1. Flutter SDK bulunan geliştirme ortamında ARES'i build edin.
2. Yerel AI için Ollama veya LM Studio kurun.
3. Örnek Ollama modeli: `qwen3:4b`.
4. ARES'i şu değerlerle başlatabilirsiniz:

```text
--dart-define=ARES_LOCAL_AI_BASE_URL=http://localhost:11434
--dart-define=ARES_LOCAL_AI_MODEL=qwen3:4b
```

LM Studio OpenAI uyumlu endpoint kullanıyorsa base URL ve model adını ona göre verin.

## Ücretsiz uzak AI

Yerel AI erişilemiyorsa doğrulanmış ücretsiz/limited-free OpenAI-compatible endpoint yapılandırılabilir:

```text
--dart-define=ARES_FREE_AI_BASE_URL=https://...
--dart-define=ARES_FREE_AI_MODEL=...
--dart-define=ARES_FREE_AI_API_KEY=...
--dart-define=ARES_FREE_AI_COST_CLASS=free
```

API anahtarı kaynak koda yazılmaz. Gerçek dağıtımda secure storage veya güvenli CI/secret yönetimi tercih edilmelidir.

## İlk üretim

Ana ekran → **Mobil Uygulama Üret** → `Basit bir Counter uygulaması üret` → ÜRET.

Sıra: ProjectSpec → Scaffold → Product Manager → Architect → Flutter Developer → QA → DevOps → Validator/Self-Healing → Build Readiness → Secure Writer.

Çıktı ARES'in kaynak `lib/` ağacına değil, uygulama belgeleri altında `ARES_Generated_Projects/<proje>/` köküne yazılır.

## Video

Ana ekran → **Video İçerik Üret**. Paket içinde `video_brief.md`, `script.md`, `shot_list.md`, `voiceover_script.md`, `captions.srt`, `thumbnail_prompt.md`, `assets_plan.md`, `timeline.json`, `render_plan.json`, `production_checklist.md` ve kalite çıktıları bulunur.

Gerçek video render paket üretiminden farklıdır. ARES otomatik olarak ffmpeg çalıştırmaz. Kullanıcı **RENDER'I BAŞLAT** düğmesine basarsa, yalnızca allowlist edilmiş ffmpeg argümanları `runInShell:false`, timeout ve ayrı `ARES_Output/video/<slug>/` çalışma kökü ile çalıştırılır. ffmpeg yoksa veya medya girdisi yoksa gerçek render yapılmış gibi gösterilmez.

## Genel içerik

Genel içerik modu standart dosya sözleşmelerine göre doküman, pazarlama metni, post serisi veya ürün açıklaması üretir.

## Güvenlik

- Paid ve unknown AI otomatik çalışmaz.
- Mock yalnızca test içindir.
- Path traversal engellenir.
- Üretilen çıktı ARES kaynak ağacını ezmez.
- Dış komutlar kullanıcı onayı olmadan çalıştırılmaz.
- Komutlar shell üzerinden çalıştırılmaz.
- Kullanıcıya ait gizli veri loglara yazılmaz.

## ffmpeg kurulumu

Render isteğe bağlıdır. ffmpeg kurulmadıysa ARES video paketini yine üretir ve `render_plan.json` dosyasını hazırlar; render tamamlandı mesajı göstermez.

- Windows: ffmpeg'i güvenilir bir dağıtımdan kurup PATH'e ekleyin.
- Linux: dağıtımınızın paket yöneticisiyle ffmpeg kurun.
- Android tablette: sistem PATH'inde ffmpeg bulunması garanti değildir; ARES bu durumda yalnızca güvenli render planını sunar.

Render komutları ARES tarafından oluşturulur, shell üzerinden çalıştırılmaz, allowlist uygulanır ve çalışma dizini yalnızca video output köküyle sınırlıdır.
