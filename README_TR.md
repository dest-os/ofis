# DEST-OS ARES


## V9 – Canlı Operasyon
V9, çalışan görev ve ajanların anlık çalışma durumunu UI'ya yansıtan Live Operations katmanını ekler.

Temel kurallar:
- Live Operations yalnızca görünüm/izleme katmanıdır.
- Görevleri kendisi yönetmez, atama yapmaz ve kritik karar vermez.
- Durumlar: queued, running, waitingApproval, paused, blocked, completed, failed, cancelled.
- İlerleme değeri 0..1 aralığında güvenli şekilde sınırlandırılır.
- Gerçek zamanlı altyapının ilk temeli repository + service + snapshot modelidir.
- V9'da gerçek Event Bus, veritabanı ve Android background runtime henüz bağlanmamıştır.

## V10 – Görev ve Rol Sistemi
V10, görevlerin önceliklendirilmesi ve çalışan ajanların görev içindeki rollerinin yönetilmesi için temel katmanı ekler.

Eklenen roller:
- OWNER
- PLANNER
- EXECUTOR
- REVIEWER
- SECURITY_AUDITOR
- TESTER
- RECOVERY_MANAGER
- OBSERVER

Kurallar:
- Aynı ajan aynı görevde aynı role iki kez atanamaz.
- Görev kuyruğu önceliğe göre sıralanır.
- Rol ataması olmayan bir görev için servis hata döndürür.
- Bu sürüm gerçek kalıcı veritabanına veya gerçek ajan runtime'ına bağlanmaz; altyapı sözleşmesini hazırlar.

## V11 – CEO Beyni, Task Engine ve Agent Manager
V11, ARES'in kullanıcı isteğini anlayıp temel bir plan oluşturmasını, planı göreve dönüştürmesini ve uygun aktif ajanı seçmek için ilk Agent Manager katmanını ekler.

Eklenen temel katmanlar:
- CEO Intent Parser
- CEO Brain Service
- CEO Planner
- CEO Plan / Task Definition
- Task Engine
- Agent Manager
- CEO kontrol ekranının ilk temeli
- V11 testleri

Güvenlik:
- Kritik öncelikli planlar otomatik olarak `requiresApproval` işaretlenir.
- Bu sürüm ücretli AI çağrısı yapmaz.
- Gerçek AI Gateway ve Tool Gateway daha sonraki katmanlarda bağlanacaktır.

## V12 – Hafıza ve AI Karar Motoru
V12, ARES'in kalıcı hafıza katmanının ilk temelini ve kaynak seçimini yöneten karar motorunu ekler.

Hafıza:
- Fact, preference, instruction, conversation, project, company, decision türleri
- Personal, project, company, task ve session kapsamları
- Arama
- Hatırla
- Unut
- Arşivle
- Güven puanı
- Kaynak ve etiket bilgisi

Karar motoru:
1. Geçerli arşiv
2. Yerel AI
3. Ücretsiz AI
4. Ücretli AI yalnızca İbrahim onayıyla

Ücretli AI bu sürümde çağrılmaz veya etkinleştirilmez.

## V13 – Ajan Kütüphanesi ve Görev Sözleşmeleri
V13, ARES'in çalışan ajanlarını standart tanımlarla kataloglamasını ve görevlerin kabul kriterleriyle sözleşmeye bağlanmasını sağlar.

Eklenenler:
- Agent Capability
- Agent Skill
- Agent Definition
- Agent Library Entry
- Agent Library Repository / Service
- Agent Matcher
- Task Contract
- Acceptance Criteria
- Task Contract Validator
- Task Contract Result
- Ajan Kütüphanesi ekranının ilk temeli

Ajan seçimi; gerekli beceri ve yeteneklere göre puanlanır. Görev sözleşmesi tüm kabul kriterleri tamamlanmadan başarılı kabul edilmez.

## V14 – Araçlar, Entegrasyonlar ve Güvenlik
V14, ARES'in araç çağrılarını doğrudan çalıştırmak yerine Tool Registry → Tool Gateway → Permission Guard zincirinden geçirmesini sağlayan ilk güvenlik katmanını ekler.

Eklenenler:
- Tool Definition
- Tool Kind
- Tool Risk Level
- Tool Request / Decision
- Tool Registry
- Tool Gateway
- Tool Permission Guard
- External write işlemlerinde onay zorunluluğu
- Credential Vault referans katmanı
- Credential değerlerinin uygulama domain modeline alınmaması
- Security Service
- Araç ve güvenlik ekranının ilk temeli

Güvenlik kuralı:
- Yüksek/kritik riskli araçlar onaysız çalıştırılmaz.
- Harici yazma işlemleri onay gerektirir.
- Credential değerleri log/event/memory/archive içinde tutulmaz; yalnızca güvenli referans mantığı kullanılır.

## V15 – Veritabanı, Veri Modeli ve Kalıcı Hafıza
V15, ARES'in geçici repository yapısından kalıcı veri mimarisine geçiş için ilk database katmanını ekler.

Eklenenler:
- Database schema version
- Entity Record
- Database transaction
- Commit / rollback
- Database Manager
- Migration sözleşmesi
- Persistent Repository
- Persistent Memory Repository
- Memory → Entity adapter
- Backup Manifest
- V15 veritabanı ve kalıcı hafıza testleri

Not:
V15'te gerçek SQLite sürücüsü henüz bağlanmamıştır. Önce database sözleşmeleri, transaction sınırı ve repository katmanı hazırlanmıştır. Gerçek SQLite adapterı sonraki entegrasyon adımında bu sözleşmelere bağlanabilir.

## V16 – Event Bus ve Mesajlaşma
V16, ARES modüllerinin doğrudan birbirine bağlanmak yerine olaylar üzerinden haberleşmesi için merkezi Event Bus altyapısını ekler.

Eklenenler:
- Event Type
- Event Priority
- Event Envelope
- Command Envelope
- Event Bus
- Event Router
- Event Store
- Event Publisher
- Retry Policy
- Dead Letter Queue
- Event Processing Service
- Event Bus Service
- Event Bus ekranının ilk temeli

Olay akışı:
Üreten modül → Event Publisher → Event Store → Event Bus → Aboneler.

Hata durumunda sınırlı retry ve sonunda Dead Letter Queue kullanılır.
