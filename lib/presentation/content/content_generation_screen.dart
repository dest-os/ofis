import 'package:flutter/material.dart';

import '../../domain/content/content_generation_result.dart';
import '../../domain/content/content_mode.dart';
import '../../domain/content/general_content_type.dart';
import '../../infrastructure/video/ffmpeg_command_runner.dart';

/// Video ve genel içerik üretimini kullanıcıya sunan tablet ekranıdır.
class ContentGenerationScreen extends StatefulWidget {
  const ContentGenerationScreen({super.key, required this.mode, required this.onGenerate, this.onRender});
  final ContentMode mode;
  final Future<ContentGenerationResult> Function({
    required ContentMode mode,
    required String request,
    String duration,
    String style,
    String platform,
    String contentType,
    void Function(String status)? onProgress,
  }) onGenerate;
  final Future<VideoRenderResult> Function({required List<String> arguments, required String relativeOutputRoot})? onRender;

  @override
  State<ContentGenerationScreen> createState() => _ContentGenerationScreenState();
}

class _ContentGenerationScreenState extends State<ContentGenerationScreen> {
  final _request = TextEditingController();
  final _duration = TextEditingController(text: '60 saniye');
  final _style = TextEditingController(text: 'modern, temiz ve ARES uyumlu');
  final _platform = TextEditingController(text: 'YouTube Shorts');
  GeneralContentType _generalType = GeneralContentType.appIdea;
  bool _busy = false;
  bool _renderBusy = false;
  String _status = 'Hazır';
  ContentGenerationResult? _result;
  String? _renderStatus;

  @override
  void dispose() {
    _request.dispose();
    _duration.dispose();
    _style.dispose();
    _platform.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_request.text.trim().length < 8) {
      setState(() => _status = 'Daha açıklayıcı bir istek yazın.');
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
      _renderStatus = null;
      _status = 'Başlatılıyor...';
    });
    try {
      final result = await widget.onGenerate(
        mode: widget.mode,
        request: _request.text.trim(),
        duration: _duration.text,
        style: _style.text,
        platform: _platform.text,
        contentType: _generalType.label,
        onProgress: (value) {
          if (mounted) setState(() => _status = value);
        },
      );
      if (mounted) {
        setState(() {
          _result = result;
          _busy = false;
          _status = result.success ? 'Üretim tamamlandı' : 'Üretim başarısız';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = 'Üretim sırasında hata oluştu';
          _result = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Üretim hatası: $error')));
      }
    }
  }

  Future<void> _render() async {
    if (_renderBusy) return;
    final result = _result;
    final callback = widget.onRender;
    if (result == null || !result.success || callback == null) return;
    final raw = result.metrics['renderArguments'];
    if (raw is! List) {
      setState(() => _renderStatus = 'Render planı bulunamadı. Önce geçerli bir video paketi üretin.');
      return;
    }
    setState(() {
      _renderBusy = true;
      _renderStatus = 'Render başlatılıyor...';
    });
    try {
      final relativeOutputRoot = result.metrics['outputRoot'] is String
          ? result.metrics['outputRoot'] as String
          : 'ARES_Output/video/uretim';
      final render = await callback(
        arguments: raw.whereType<String>().toList(growable: false),
        relativeOutputRoot: relativeOutputRoot,
      );
      if (mounted) {
        setState(() {
          _renderBusy = false;
          _renderStatus = render.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _renderBusy = false;
          _renderStatus = 'Render sırasında hata oluştu: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final isVideo = widget.mode == ContentMode.video;
    final renderPlan = result?.metrics['renderPlan'];
    final renderPlanText = renderPlan is String ? renderPlan : null;
    final outputPath = result?.metrics['outputRoot'];

    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(title: Text(widget.mode.label), backgroundColor: const Color(0xFF07131D)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Panel(
              'GİRİŞ',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _request,
                    minLines: 6,
                    maxLines: 10,
                    enabled: !_busy,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Yüksek seviye fikir / istek',
                      hintText: 'Örneğin: 60 saniyelik verimlilik videosu üret',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isVideo) ...[
                    const SizedBox(height: 14),
                    _Input(controller: _duration, label: 'Süre', enabled: !_busy),
                    const SizedBox(height: 10),
                    _Input(controller: _style, label: 'Stil', enabled: !_busy),
                    const SizedBox(height: 10),
                    _Input(controller: _platform, label: 'Platform', enabled: !_busy),
                  ],
                  if (!isVideo) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<GeneralContentType>(
                      value: _generalType,
                      decoration: const InputDecoration(labelText: 'İçerik türü', border: OutlineInputBorder()),
                      items: GeneralContentType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
                      onChanged: _busy ? null : (value) { if (value != null) setState(() => _generalType = value); },
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _run,
                      icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                      label: Text(_busy ? 'ÜRETİLİYOR...' : 'ÜRET'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              'CANLI DURUM',
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_busy ? Icons.sync : result?.success == true ? Icons.check_circle_outline : Icons.memory, color: Colors.cyanAccent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_status, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 16),
              _ResultPanel(result: result),
              if (outputPath is String && outputPath.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _Panel('ÇIKTI YOLU', SelectableText(outputPath, style: const TextStyle(color: Colors.white70, height: 1.35))),
              ],
              if (isVideo && result.success) ...[
                const SizedBox(height: 16),
                _Panel(
                  'RENDER PLANI',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (renderPlanText != null)
                        SizedBox(height: 180, child: SingleChildScrollView(child: SelectableText(renderPlanText, style: const TextStyle(color: Colors.white70, height: 1.35))))
                      else
                        const Text('Render planı üretildi ancak ekranda metin özeti bulunmuyor.', style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _renderBusy ? null : _render,
                          icon: _renderBusy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.movie_filter_outlined),
                          label: Text(_renderBusy ? 'RENDER ÇALIŞIYOR...' : 'RENDER’I BAŞLAT'),
                        ),
                      ),
                      if (_renderStatus != null) ...[
                        const SizedBox(height: 12),
                        Text(_renderStatus!, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.3)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result});
  final ContentGenerationResult result;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      'SONUÇ',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.success ? 'Üretim başarılı.' : 'Üretim başarısız.', style: TextStyle(color: result.success ? Colors.cyanAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: result.artifacts.isEmpty
                ? const Align(alignment: Alignment.topLeft, child: Text('Dosya üretilmedi.', style: TextStyle(color: Colors.white54)))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: result.artifacts.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (_, index) {
                      final artifact = result.artifacts[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined, color: Colors.cyanAccent),
                        title: Text(artifact.relativePath, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(artifact.generatedBy, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38)),
                      );
                    },
                  ),
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('HATALAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SizedBox(height: 110, child: _TextList(items: result.errors, color: Colors.redAccent.shade100)),
          ],
          if (result.suggestedActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('ÖNERİLEN DÜZELTMELER', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SizedBox(height: 110, child: _TextList(items: result.suggestedActions, color: Colors.amberAccent)),
          ],
        ],
      ),
    );
  }
}

class _TextList extends StatelessWidget {
  const _TextList({required this.items, required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, index) => Text('• ${items[index]}', maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, height: 1.3)),
      );
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.label, required this.enabled});
  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      );
}

class _Panel extends StatelessWidget {
  const _Panel(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1722),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.cyanAccent.withOpacity(.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}
