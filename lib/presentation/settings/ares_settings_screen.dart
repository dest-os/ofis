import 'package:flutter/material.dart';

import '../../application/ai/ai_gateway.dart';
import '../../application/settings/ares_settings.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';

/// Tablet için sade Sistem & API Ayarları.
class AresSettingsScreen extends StatefulWidget {
  const AresSettingsScreen({super.key, required this.store, required this.gateway});

  final AresSettingsStore store;
  final AresAiGateway gateway;

  @override
  State<AresSettingsScreen> createState() => _AresSettingsScreenState();
}

class _AresSettingsScreenState extends State<AresSettingsScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _localUrl;
  late final TextEditingController _localModel;
  late final TextEditingController _backupUrl;
  late final TextEditingController _backupModel;
  late final TextEditingController _backupKey;
  late bool _localEnabled;
  bool _busy = false;
  String? _status;
  bool _statusOk = false;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final s = widget.store.current;
    _localEnabled = s.localEnabled;
    _localUrl = TextEditingController(text: s.localBaseUrl);
    _localModel = TextEditingController(text: s.localModel);
    _backupUrl = TextEditingController(text: s.freeBaseUrl);
    _backupModel = TextEditingController(text: s.freeModel);
    _backupKey = TextEditingController();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _localUrl.dispose();
    _localModel.dispose();
    _backupUrl.dispose();
    _backupModel.dispose();
    _backupKey.dispose();
    _tabs.dispose();
    super.dispose();
  }

  AresSettings _collect() => AresSettings(
        localEnabled: _localEnabled,
        localBaseUrl: _localUrl.text.trim(),
        localModel: _localModel.text.trim(),
        freeBaseUrl: _backupUrl.text.trim(),
        freeModel: _backupModel.text.trim(),
        freeApiKey: _backupKey.text.trim(),
      );

  Future<void> _save({bool test = false}) async {
    setState(() {
      _busy = true;
      _status = test ? 'Bağlantı test ediliyor…' : 'Ayarlar kaydediliyor…';
      _statusOk = false;
    });
    try {
      await widget.store.save(
        _collect(),
        apiKey: _backupKey.text.trim().isEmpty ? null : _backupKey.text.trim(),
      );
      _backupKey.clear();
      if (test) {
        final result = await widget.gateway.generate(const AiRequest(instruction: 'Sadece TAMAM yaz.', costClass: AiCostClass.free));
        if (!mounted) return;
        setState(() {
          if (result is AresSuccess<AiResponse>) {
            _status = 'Hazır • ${result.value.modelName}';
            _statusOk = true;
          } else if (result is AresFailure<AiResponse>) {
            _status = _friendly(result.message);
          }
        });
      } else if (mounted) {
        setState(() {
          _status = 'Ayarlar kaydedildi.';
          _statusOk = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _status = _friendly(error.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(String value) {
    final text = value.toLowerCase();
    if (text.contains('socket') || text.contains('connection') || text.contains('refused') || text.contains('eriş')) {
      return 'Bağlantı kurulamadı. Adresi ve model adını kontrol edin.';
    }
    if (text.contains('401') || text.contains('403') || text.contains('api key') || text.contains('unauthorized')) {
      return 'API anahtarı kabul edilmedi. Anahtarı kontrol edin.';
    }
    return 'Bağlantı başarısız. Adres, model ve ağ bağlantısını kontrol edin.';
  }

  InputDecoration _input(String label, String hint) => InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('SİSTEM & API AYARLARI'),
        backgroundColor: const Color(0xFF08131D),
        bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
          Tab(text: 'Genel Ayarlar'),
          Tab(text: 'AI Kataloğu'),
          Tab(text: 'API Anahtarları'),
          Tab(text: 'Model Sırası'),
          Tab(text: 'Onaylar'),
        ]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _generalTab(),
        _catalogTab(),
        _keysTab(),
        _orderTab(),
        _approvalTab(),
      ]),
    );
  }

  Widget _generalTab() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            _Panel(title: 'YEREL AI • BİRİNCİL', child: Column(children: [
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Yerel AI kullan'), subtitle: const Text('Önce yerel Qwen denenir.'), value: _localEnabled, onChanged: _busy ? null : (v) => setState(() => _localEnabled = v)),
              const SizedBox(height: 10),
              TextField(controller: _localUrl, decoration: _input('Adres', 'http://127.0.0.1:11434'), enabled: !_busy),
              const SizedBox(height: 12),
              TextField(controller: _localModel, decoration: _input('Model adı', 'qwen2.5-coder:1.5b'), enabled: !_busy),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: _busy ? null : () => _save(test: true), icon: const Icon(Icons.wifi_tethering), label: const Text('KAYDET VE TEST ET'))),
            ])),
            const SizedBox(height: 14),
            _Panel(title: 'YEDEK AI', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: _backupUrl, decoration: _input('Adres', 'Ücretsiz / sınırlı ücretsiz sağlayıcı adresi'), enabled: !_busy),
              const SizedBox(height: 12),
              TextField(controller: _backupModel, decoration: _input('Model adı', 'Model adı'), enabled: !_busy),
              const SizedBox(height: 12),
              TextField(
                controller: _backupKey,
                obscureText: true,
                decoration: _input(
                  'API anahtarı',
                  widget.store.current.freeApiKeyStored
                      ? '••••••••  (kayıtlı — değiştirmek için yeni anahtar yazın)'
                      : 'API anahtarı kayıtlı değil',
                ),
                enabled: !_busy,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    widget.store.current.freeApiKeyStored
                        ? Icons.lock
                        : Icons.lock_outline,
                    size: 18,
                    color: widget.store.current.freeApiKeyStored
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.store.current.freeApiKeyStored
                          ? 'API anahtarı güvenli depoda kayıtlı.'
                          : 'API anahtarı kayıtlı değil.',
                    ),
                  ),
                  if (widget.store.current.freeApiKeyStored)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              await widget.store.save(
                                _collect(),
                                clearApiKey: true,
                              );
                              if (mounted) {
                                setState(() {
                                  _status = 'API anahtarı güvenli depodan silindi.';
                                  _statusOk = true;
                                });
                              }
                            },
                      child: const Text('ANAHTARI SİL'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Anahtar normal ayar dosyasına, arşive veya canlı kayıtlara yazılmaz. '
                'Ücretli veya fiyatı bilinmeyen AI otomatik çalıştırılmaz.',
                style: TextStyle(color: Colors.orangeAccent, height: 1.35),
              ),
            ])),
            const SizedBox(height: 14),
            if (_status != null) _StatusBox(text: _status!, ok: _statusOk),
            const SizedBox(height: 14),
            SizedBox(height: 52, child: OutlinedButton.icon(onPressed: _busy ? null : () => _save(), icon: const Icon(Icons.save), label: const Text('AYARLARI KAYDET'))),
          ]),
        ),
      );

  Widget _catalogTab() => ListView(padding: const EdgeInsets.all(24), children: const [
        _CatalogCard(title: 'Yerel AI’lar', text: 'Birincil alan • Qwen Coder', icon: Icons.memory, primary: true),
        SizedBox(height: 12),
        _CatalogCard(title: 'Ücretsiz AI’lar', text: 'Ücretsiz kullanım sunan sağlayıcılar', icon: Icons.public),
        SizedBox(height: 12),
        _CatalogCard(title: 'Sınırlı Ücretsiz', text: 'Kullanım sınırı olan yedekler', icon: Icons.speed),
        SizedBox(height: 12),
        _CatalogCard(title: 'Ücretli AI’lar', text: 'Yalnızca açık onay ile', icon: Icons.lock_outline),
        SizedBox(height: 12),
        _CatalogCard(title: 'Araç AI’ları', text: 'Belirli görevlerde kullanılan yardımcılar', icon: Icons.build_outlined),
      ]);

  Widget _keysTab() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _InfoPanel(
            title: 'API anahtarları',
            text: widget.store.current.freeApiKeyStored
                ? 'Yedek AI anahtarı güvenli depoda kayıtlı. Anahtarın kendisi burada gösterilmez.'
                : 'API anahtarı kayıtlı değil. Anahtar yalnızca güvenli depoya kaydedilir.',
          ),
          const SizedBox(height: 12),
          const _InfoPanel(
            title: 'Yedek sağlayıcı',
            text: 'Adres, model ve yeni API anahtarı Genel Ayarlar bölümünden girilir.',
          ),
        ],
      );

  Widget _orderTab() => ListView(padding: const EdgeInsets.all(24), children: const [
        _OrderRow(number: '1', title: 'Yerel Qwen Coder', text: 'Birincil • Önce denenir'),
        SizedBox(height: 12),
        _OrderRow(number: '2', title: 'Ücretsiz / sınırlı ücretsiz AI', text: 'Yerel AI yoksa veya çalışmazsa'),
        SizedBox(height: 12),
        _OrderRow(number: '3', title: 'Ücretli AI', text: 'Sadece açık İbrahim onayı ile'),
      ]);

  Widget _approvalTab() => ListView(padding: const EdgeInsets.all(24), children: const [
        _InfoPanel(title: 'Onay kuralı', text: 'Ücretli veya fiyatı bilinmeyen AI kendiliğinden çalışmaz. Önce ne kullanılacağı ve neden gerektiği gösterilir; ardından açık onay beklenir.'),
        SizedBox(height: 12),
        _InfoPanel(title: 'Güvenlik', text: 'Kod üretimi ayrı çıktı klasörüne yazılır. ARES’in kendi kaynak dosyaları üzerine yazılmaz.'),
      ]);
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF0A1722), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 14), child]));
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.text, required this.ok});
  final String text;
  final bool ok;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: ok ? const Color(0xFF0D2B22) : const Color(0xFF2A2012), borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(ok ? Icons.check_circle : Icons.warning_amber, color: ok ? Colors.greenAccent : Colors.orangeAccent), const SizedBox(width: 10), Expanded(child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis))]));
}


class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.title,
    required this.text,
    required this.icon,
    this.primary = false,
  });

  final String title;
  final String text;
  final IconData icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A1722),
      child: ListTile(
        minVerticalPadding: 16,
        leading: Icon(
          icon,
          color: primary ? Colors.cyanAccent : Colors.white70,
          size: 32,
        ),
        title: Text(title),
        subtitle: Text(text),
        trailing: primary ? const Chip(label: Text('BIRINCIL')) : null,
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A1722),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A1722),
      child: ListTile(
        minVerticalPadding: 14,
        leading: CircleAvatar(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          child: Text(number),
        ),
        title: Text(title),
        subtitle: Text(text),
      ),
    );
  }
}
