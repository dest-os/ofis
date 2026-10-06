import 'package:flutter/material.dart';

import '../../domain/codegen/generation_result.dart';

/// ARES Kod Üretim Motorunun kullanıcı arayüzüdür.
class CodeGenerationScreen extends StatefulWidget {
  const CodeGenerationScreen({super.key, this.onGenerate});

  final Future<GenerationResult> Function(
    String request, {
    void Function(String status)? onProgress,
  })? onGenerate;

  @override
  State<CodeGenerationScreen> createState() => _CodeGenerationScreenState();
}

class _CodeGenerationScreenState extends State<CodeGenerationScreen> {
  final TextEditingController _requestController = TextEditingController();
  bool _isGenerating = false;
  String _status = 'Hazır';
  int _activeStep = -1;
  GenerationResult? _result;
  String? _errorMessage;

  static const List<String> _steps = <String>[
    'İstek', 'Plan', 'Scaffold', 'Domain', 'Application',
    'Presentation', 'Doğrulama', 'Yazma', 'Tamam',
  ];

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final request = _requestController.text.trim();
    if (request.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen üretilecek uygulamayı veya projeyi açıklayın.';
        _status = 'İstek bekleniyor';
        _activeStep = 0;
      });
      return;
    }

    final generator = widget.onGenerate;
    if (generator == null) {
      setState(() {
        _errorMessage = 'Kod üretim çalışma zamanı yapılandırılmamış. Mock AI\'ya sessizce düşülmedi.';
        _status = 'Yapılandırma eksik';
        _activeStep = -1;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'İstek hazırlanıyor';
      _activeStep = 0;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await generator(request, onProgress: _handleProgress);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isGenerating = false;
        _activeStep = result.success ? _steps.length - 1 : _activeStep;
        _status = result.success ? 'Üretim tamamlandı' : 'Üretim başarısız';
        _errorMessage = result.success || result.errors.isEmpty ? null : result.errors.join('\n');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _status = 'Üretim sırasında hata oluştu';
        _errorMessage = '$error';
      });
    }
  }

  void _handleProgress(String status) {
    if (!mounted) return;
    final normalized = status.toLowerCase();
    var step = _activeStep;
    for (var index = 0; index < _steps.length; index++) {
      if (normalized.contains(_steps[index].toLowerCase())) {
        step = index;
        break;
      }
    }
    if (normalized.contains('self-healing')) step = 6;
    setState(() {
      _status = status;
      _activeStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final artifacts = result?.artifacts ?? const [];
    final logs = (result?.metrics['logs'] as List?)?.whereType<String>().toList() ?? const <String>[];
    final retryCount = result?.metrics['retryCount'] ?? 0;
    final selfHealingCount = result?.metrics['selfHealingCount'] ?? 0;
    final attemptCount = result?.attemptCount ?? 0;
    final ceoNotes = result?.ceoNotes ?? const <String>[];
    final suggestions = result?.suggestedActions ?? const <String>[];
    final outputPath = _firstString(result?.metrics, const ['outputPath', 'outputRoot', 'projectOutputRoot']);
    final commands = _stringList(result?.metrics, 'commands');

    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('ARES — KOD ÜRETİM MERKEZİ'),
        backgroundColor: const Color(0xFF08131D),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _SectionCard(
              title: 'YÜKSEK SEVİYELİ İSTEK',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _requestController,
                    minLines: 5,
                    maxLines: 9,
                    enabled: !_isGenerating,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Örneğin: Basit bir Counter uygulaması üret.'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generate,
                      icon: _isGenerating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'ÜRETİLİYOR...' : 'ÜRET'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF007C91)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _StatusLine(status: _status, busy: _isGenerating, success: result?.success == true),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'ÜRETİM ADIMLARI',
              child: _ProgressSteps(activeStep: _activeStep),
            ),
            if (result != null) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'ÜRETİM METRİKLERİ',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricChip(label: 'Dosya', value: '${result.artifacts.length}'),
                    _MetricChip(label: 'Tekrar', value: '$retryCount'),
                    _MetricChip(label: 'Otomatik düzeltme', value: '$selfHealingCount'),
                    _MetricChip(label: 'Log', value: '${logs.length}'),
                    _MetricChip(label: 'Derlemeye hazır', value: result.metrics['buildReady'] == true ? 'EVET' : 'HAYIR'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ResultList(artifacts: artifacts),
              if (outputPath != null) ...[
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'ÇIKTI KLASÖRÜ',
                  child: SelectableText(outputPath, style: const TextStyle(color: Colors.white70, height: 1.35)),
                ),
              ],
              if (commands.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'ÇALIŞTIRILACAK KOMUTLAR',
                  child: _ScrollableTextList(commands),
                ),
              ],
            ],
            if (result != null) ...[
              const SizedBox(height: 14),
              _CeoReportCard(
                result: result,
                attemptCount: attemptCount,
                ceoNotes: ceoNotes,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              _MessageCard(title: 'HATA', message: _errorMessage!, icon: Icons.error_outline, isError: true),
            ],
            if (result?.success == true) ...[
              const SizedBox(height: 14),
              const _MessageCard(
                title: 'BAŞARILI',
                message: 'Üretim tamamlandı. Çıktı klasörü ve çalıştırma adımları yukarıda gösteriliyor.',
                icon: Icons.check_circle,
              ),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(title: 'ÖNERİLEN DÜZELTMELER', child: _ScrollableTextList(suggestions)),
            ],
            if (logs.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(title: 'ÜRETİM GÜNLÜĞÜ', child: _ScrollableTextList(logs)),
            ],
          ],
        ),
      ),
    );
  }
}

String? _firstString(Map<String, Object?>? metrics, List<String> keys) {
  if (metrics == null) return null;
  for (final key in keys) {
    final value = metrics[key];
    if (value is String && value.trim().isNotEmpty) return value;
  }
  return null;
}

List<String> _stringList(Map<String, Object?>? metrics, String key) {
  final value = metrics?[key];
  if (value is List) return value.whereType<String>().toList(growable: false);
  return const <String>[];
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF071019),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.cyanAccent)),
    );

class _CeoReportCard extends StatelessWidget {
  const _CeoReportCard({
    required this.result,
    required this.attemptCount,
    required this.ceoNotes,
  });

  final GenerationResult result;
  final int attemptCount;
  final List<String> ceoNotes;

  @override
  Widget build(BuildContext context) {
    final title = result.success
        ? 'BAŞARILI'
        : (result.artifacts.isNotEmpty ? 'KISMEN' : 'BAŞARISIZ');
    final remaining = result.errors.isEmpty
        ? 'Kalan sorun yok.'
        : result.errors.first.replaceFirst(RegExp(r'^.*?: '), '');
    final tried = ceoNotes.isEmpty
        ? 'Hata oluşmadı; yeniden düzeltme gerekmedi.'
        : ceoNotes.last;

    return _SectionCard(
      title: 'CEO SONUCU',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deneme sayısı: $attemptCount',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Düzeltilmeye çalışılan: $tried',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Kalan sorun: $remaining',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: result.success ? Colors.white70 : Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status, required this.busy, required this.success});
  final String status;
  final bool busy;
  final bool success;

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'CANLI DURUM',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(busy ? Icons.sync : success ? Icons.check_circle_outline : Icons.memory, color: Colors.cyanAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(status, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1722),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.activeStep});
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const steps = <String>['İstek', 'Plan', 'Temel dosyalar', 'Veri yapısı', 'İşleyiş', 'Ekranlar', 'Kontrol', 'Kaydetme', 'Tamam'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        steps.length,
        (index) => Chip(
          label: Text(steps[index], overflow: TextOverflow.ellipsis),
          avatar: index < activeStep
              ? const Icon(Icons.check, size: 15, color: Colors.cyanAccent)
              : index == activeStep
                  ? const Icon(Icons.play_arrow, size: 15, color: Colors.white)
                  : null,
          labelStyle: TextStyle(color: index == activeStep ? Colors.white : Colors.white70, fontWeight: index == activeStep ? FontWeight.bold : FontWeight.normal),
          backgroundColor: index == activeStep ? const Color(0xFF007C91) : const Color(0xFF10232F),
          side: BorderSide(color: index == activeStep ? Colors.cyanAccent : Colors.white12),
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.artifacts});
  final List artifacts;

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'ÜRETİLEN DOSYALAR',
        child: artifacts.isEmpty
            ? const Text('Henüz üretilen dosya yok.', style: TextStyle(color: Colors.white54))
            : SizedBox(
                height: 260,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: artifacts.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final artifact = artifacts[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined, color: Colors.cyanAccent),
                      title: Text(artifact.relativePath, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${artifact.type.name} • ${artifact.generatedBy}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38)),
                    );
                  },
                ),
              ),
      );
}

class _ScrollableTextList extends StatelessWidget {
  const _ScrollableTextList(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 180,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 7),
          itemBuilder: (_, index) => Text(items[index], maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, height: 1.3)),
        ),
      );
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text('$label: $value', overflow: TextOverflow.ellipsis),
        labelStyle: const TextStyle(color: Colors.white70),
        backgroundColor: const Color(0xFF10232F),
        side: const BorderSide(color: Colors.white12),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.message, required this.icon, this.isError = false});
  final String title;
  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: title,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isError ? Colors.redAccent : Colors.cyanAccent),
            const SizedBox(width: 12),
            Expanded(child: Text(message, maxLines: 8, overflow: TextOverflow.ellipsis, style: TextStyle(color: isError ? Colors.redAccent.shade100 : Colors.white70, height: 1.4))),
          ],
        ),
      );
}
