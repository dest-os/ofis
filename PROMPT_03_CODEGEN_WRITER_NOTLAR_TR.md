# Prompt 3 — Code Writer / File System Writer

Eklenenler:
- `lib/application/codegen/code_writer_service.dart`
- `lib/infrastructure/codegen/file_system_writer.dart`
- Path traversal koruması
- İzin verilen kök dizin sınırı
- Otomatik klasör oluşturma
- Varsayılan olarak üzerine yazmama
- İsteğe bağlı `overwrite: true`
- `path` ve `path_provider` kullanımı
- Yazılan dosya ve hata sonucunun döndürülmesi
- Temel güvenlik testleri

Application katmanı orkestrasyon yapar; gerçek dosya I/O infrastructure katmanındadır.
