import 'package:flutter/material.dart';

import '../../application/ai/ai_gateway.dart';
import '../../application/archive/archive_similarity.dart';
import '../../application/archive/secret_scrubber.dart';
import '../../application/archive/work_archive_repository.dart';
import '../../core/format/tr_date.dart';
import '../../core/ids/ares_id.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import '../../domain/archive/work_archive_entry.dart';
import '../../domain/codegen/generation_result.dart';
import '../codegen/code_generation_screen.dart';

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser, this.isError = false});
  final String text;
  final bool fromUser;
  final bool isError;
}

/// Dinleyici masası: yazılan prompt'u yapay zekâya iletir ve cevabı gösterir.
class AresChatScreen extends StatefulWidget {
  const AresChatScreen({super.key, required this.gateway, required this.archive, this.onOpenSettings, this.onOpenMobileProduction});

  final AresAiGateway gateway;
  final WorkArchiveRepository archive;

  /// Ayar eksikse "Ayarlara git" düğmesi için.
  final VoidCallback? onOpenSettings;

  final Future<GenerationResult> Function(String request, {void Function(String status)? onProgress})? onOpenMobileProduction;

  @override
  State<AresChatScreen> createState() => _AresChatScreenState();
}

class _AresChatScreenState extends State<AresChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final DateTime _startedAt = DateTime.now();
  final SecretScrubber _scrubber = const SecretScrubber();

  bool _busy = false;
  bool? _useReference;
  ArchiveMatch? _offer;
  String? _pendingText;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;

    if (_useReference == null && _messages.isEmpty) {
      final match = await _findSimilar(text);
      if (!mounted) return;
      if (match != null) {
        setState(() {
          _offer = match;
          _pendingText = text;
        });
        return;
      }
      _useReference = false;
    }
    await _dispatch(text);
  }

  Future<ArchiveMatch?> _findSimilar(String text) async {
    try {
      final all = await widget.archive.search('');
      final ranked = const ArchiveSimilarity().rank(text, all, limit: 1);
      return ranked.isEmpty ? null : ranked.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _decideReference(bool use) async {
    final text = _pendingText;
    setState(() {
      _useReference = use;
      _pendingText = null;
      if (!use) _offer = null;
    });
    if (text != null) await _dispatch(text);
  }

  String _buildInstruction() {
    final buffer = StringBuffer()
      ..writeln('Sen DEST-OS ARES asistanısın. Türkçe, kısa ve net cevap ver. Bilmediğin şeyi uydurma.');
    final offer = _offer;
    if (_useReference == true && offer != null) {
      buffer
        ..writeln()
        ..writeln('ÖNCEKİ BENZER ÇALIŞMA (gerekirse referans al):')
        ..writeln(offer.entry.summary);
    }
    final history = _messages.where((m) => !m.isError).toList();
    final recent = history.length > 7 ? history.sublist(history.length - 7) : history;
    buffer
      ..writeln()
      ..writeln('KONUŞMA:');
    for (final message in recent) {
      buffer.writeln('${message.fromUser ? 'Kullanıcı' : 'ARES'}: ${_limit(message.text, 1200)}');
    }
    buffer.write('ARES:');
    return buffer.toString();
  }

  String _limit(String value, int max) => value.length <= max ? value : value.substring(0, max);

  Future<AresResult<AiResponse>> _ask() async {
    try {
      return await widget.gateway.generate(
        AiRequest(instruction: _buildInstruction(), costClass: AiCostClass.free),
      );
    } catch (error) {
      return AresFailure<AiResponse>('Beklenmeyen hata: $error');
    }
  }

  Future<void> _dispatch(String text) async {
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _controller.clear();
      _busy = true;
    });
    _scrollToEnd();

    final result = await _ask();
    if (!mounted) return;

    setState(() {
      if (result is AresSuccess<AiResponse>) {
        _messages.add(_ChatMessage(text: result.value.text.trim(), fromUser: false));
      } else if (result is AresFailure<AiResponse>) {
        _messages.add(_ChatMessage(text: result.message, fromUser: false, isError: true));
      }
      _busy = false;
    });
    _scrollToEnd();
    await _saveToArchive();
  }

  Future<void> _saveToArchive() async {
    try {
      final firstUser = _messages.firstWhere((m) => m.fromUser).text;
      final answers = _messages.where((m) => !m.fromUser && !m.isError).toList();
      if (answers.isEmpty) return;
      final lastAnswer = answers.last.text;
      final entry = WorkArchiveEntry(
        id: AresId('chat_${_startedAt.microsecondsSinceEpoch}'),
        title: '${formatTrDate(_startedAt)} — ${clipText(_scrubber.scrub(firstUser), 40)}',
        summary: _scrubber.scrub('Soru: ${clipText(firstUser, 200)}\nCevap: ${clipText(lastAnswer, 400)}'),
        completedAt: DateTime.now(),
        tags: const <String>['sohbet'],
      );
      await widget.archive.save(entry);
    } catch (_) {
      // Arşiv yazılamazsa sohbet devam etsin.
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Widget _bubble(_ChatMessage message) {
    final color = message.isError
        ? const Color(0xFF3A1F1A)
        : message.fromUser
            ? const Color(0xFF12324A)
            : const Color(0xFF0E1C28);
    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: SelectableText(
          message.text,
          style: TextStyle(color: message.isError ? Colors.orangeAccent : Colors.white, height: 1.35),
        ),
      ),
    );
  }

  Widget _offerBanner() {
    final offer = _offer!;
    return Card(
      color: const Color(0xFF10222F),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Benzer bir çalışma bulundu', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(offer.entry.title, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(clipText(offer.entry.summary, 160), style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: () => _decideReference(true), child: const Text('Referans olarak kullan')),
                OutlinedButton(onPressed: () => _decideReference(false), child: const Text('Yeni başla')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openMobileProduction() {
    final callback = widget.onOpenMobileProduction;
    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobil üretim servisi hazır değil.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CodeGenerationScreen(onGenerate: callback)));
  }

  Widget _quickActions() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(label: const Text('Bir görev planla'), onPressed: () => _controller.text = 'Bu işi planla: '),
          ActionChip(label: const Text('Mobil uygulama üret'), onPressed: _openMobileProduction),
          ActionChip(label: const Text('Belge / analiz'), onPressed: () => _controller.text = 'Belgeyi analiz et: '),
          ActionChip(label: const Text('Araştırma'), onPressed: () => _controller.text = 'Araştır: '),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final waitingDecision = _pendingText != null && _offer != null;
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('ARES SOHBET'),
        backgroundColor: const Color(0xFF08131D),
        actions: [
          if (widget.onOpenSettings != null)
            IconButton(tooltip: 'Ayarlar', onPressed: widget.onOpenSettings, icon: const Icon(Icons.settings)),
        ],
      ),
      body: Column(
        children: [
          _quickActions(),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Merhaba İbrahim, size nasıl yardımcı olabilirim?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 18)),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: _messages.length,
                    itemBuilder: (_, index) => _bubble(_messages[index]),
                  ),
          ),
          if (waitingDecision) _offerBanner(),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !waitingDecision,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Mesajınızı buraya yazın…',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Gönder',
                    color: Colors.cyanAccent,
                    onPressed: (_busy || waitingDecision) ? null : _onSend,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
