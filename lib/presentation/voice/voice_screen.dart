import 'package:flutter/material.dart';

import '../../application/voice/voice_command_parser.dart';
import '../../application/voice/voice_command_service.dart';
import '../../domain/codegen/generation_result.dart';
import '../../domain/voice/stt_result.dart';

enum _VoiceUiState { ready, listening, processing, error }

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({
    super.key,
    required this.onOpenChat,
    required this.onOpenSettings,
    required this.onOpenLiveOperations,
    this.onMobileProduction,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLiveOperations;
  final Future<GenerationResult> Function(String request)? onMobileProduction;

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final VoiceCommandService _service = VoiceCommandService();
  final VoiceCommandParser _parser = const VoiceCommandParser();

  _VoiceUiState _state = _VoiceUiState.ready;
  String _transcript = '';
  String? _error;
  bool _handlingCommand = false;

  @override
  void dispose() {
    _service.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_state == _VoiceUiState.listening) {
      await _stop();
      return;
    }
    setState(() {
      _state = _VoiceUiState.listening;
      _error = null;
      _transcript = '';
    });

    final result = await _service.start(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' && _state == _VoiceUiState.listening) {
          setState(() => _state = _VoiceUiState.processing);
        }
      },
      onResult: _onResult,
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _state = _VoiceUiState.error;
          _error = message;
        });
      },
    );

    if (!mounted) return;
    if (result == VoiceStartResult.denied) {
      setState(() {
        _state = _VoiceUiState.error;
        _error = 'Mikrofon izni verilmedi. İzin için cihaz ayarlarını açın.';
      });
    } else if (result == VoiceStartResult.unsupported) {
      setState(() {
        _state = _VoiceUiState.error;
        _error = 'Bu cihazda sesli komut kullanılamıyor.';
      });
    }
  }

  Future<void> _stop() async {
    await _service.stop();
    if (!mounted) return;
    setState(() => _state = _VoiceUiState.processing);
    if (_transcript.trim().isNotEmpty) await _handleTranscript(_transcript.trim());
  }

  void _onResult(SttResult result) {
    if (!mounted) return;
    setState(() => _transcript = result.text);
    if (result.isFinal && result.text.trim().isNotEmpty) {
      _handleTranscript(result.text.trim());
    }
  }

  Future<void> _handleTranscript(String text) async {
    if (_handlingCommand) return;
    _handlingCommand = true;
    final action = _parser.parse(text);
    if (!mounted) {
      _handlingCommand = false;
      return;
    }
    setState(() => _state = _VoiceUiState.processing);
    await _service.stop();

    try {
      switch (action.type) {
        case VoiceCommandActionType.stop:
          _setReady();
          return;
        case VoiceCommandActionType.openChat:
          _setReady();
          widget.onOpenChat();
          return;
        case VoiceCommandActionType.openSettings:
          _setReady();
          widget.onOpenSettings();
          return;
        case VoiceCommandActionType.openLiveOperations:
          _setReady();
          widget.onOpenLiveOperations();
          return;
        case VoiceCommandActionType.mobileProduction:
          final callback = widget.onMobileProduction;
          if (callback == null) {
            setState(() {
              _state = _VoiceUiState.error;
              _error = 'Mobil üretim servisi hazır değil.';
            });
            return;
          }
          final request = action.request;
          if (request == null || request.isEmpty) {
            setState(() {
              _state = _VoiceUiState.error;
              _error = 'Mobil uygulama isteğini de söyleyin. Örneğin: Mobil uygulama üret, not uygulaması.';
            });
            return;
          }
          try {
            final result = await callback(request);
            if (!mounted) return;
            if (result.success) {
              _setReady();
            } else {
              setState(() {
                _state = _VoiceUiState.error;
                _error = result.errors.isEmpty
                    ? 'Mobil uygulama üretimi tamamlanamadı. Canlı Operasyon bölümünden sonucu kontrol edin.'
                    : 'Mobil uygulama üretimi tamamlanamadı: ${result.errors.first}';
              });
            }
          } catch (_) {
            if (!mounted) return;
            setState(() {
              _state = _VoiceUiState.error;
              _error = 'Mobil uygulama üretimi başlatılamadı. Canlı Operasyon bölümünden sonucu kontrol edin.';
            });
          }
          return;
        case VoiceCommandActionType.unknown:
          setState(() {
            _state = _VoiceUiState.error;
            _error = 'Komut anlaşılmadı. “Sohbet aç”, “Ayarlar aç”, “Canlı operasyon aç” veya “Mobil uygulama üret …” diyebilirsiniz.';
          });
          return;
        case VoiceCommandActionType.none:
          _setReady();
          return;
      }
    } finally {
      _handlingCommand = false;
    }
  }

  void _setReady() {
    if (!mounted) return;
    setState(() {
      _state = _VoiceUiState.ready;
      _error = null;
    });
  }

  String get _stateText {
    switch (_state) {
      case _VoiceUiState.ready:
        return 'Hazır';
      case _VoiceUiState.listening:
        return 'Dinliyor';
      case _VoiceUiState.processing:
        return 'İşleniyor';
      case _VoiceUiState.error:
        return 'Hata';
    }
  }

  Color get _stateColor {
    switch (_state) {
      case _VoiceUiState.ready:
        return Colors.cyanAccent;
      case _VoiceUiState.listening:
        return Colors.greenAccent;
      case _VoiceUiState.processing:
        return Colors.orangeAccent;
      case _VoiceUiState.error:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listening = _state == _VoiceUiState.listening;
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(title: const Text('ARES SESLİ KOMUT')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  color: const Color(0xFF08131C),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Text(_stateText, style: TextStyle(color: _stateColor, fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 18),
                        Icon(listening ? Icons.mic : Icons.mic_none, color: _stateColor, size: 72),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _state == _VoiceUiState.processing ? null : _start,
                          icon: Icon(listening ? Icons.stop : Icons.mic),
                          label: Text(listening ? 'Dinlemeyi bitir' : 'Dinlemeye başla'),
                          style: FilledButton.styleFrom(minimumSize: const Size(260, 58)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(title: 'Tanınan konuşma', text: _transcript.isEmpty ? 'Henüz konuşma alınmadı.' : _transcript),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _InfoCard(title: 'Ne yapmalısınız?', text: _error!, error: true),
                ],
                const SizedBox(height: 16),
                const _InfoCard(
                  title: 'Örnek komutlar',
                  text: '“Sohbet aç”\n“Ayarlar aç”\n“Canlı operasyon aç”\n“Mobil uygulama üret, basit bir not uygulaması yap”\n“Dur”',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.text, this.error = false});
  final String title;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF0B1722),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: error ? Colors.orangeAccent : Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(text, maxLines: 8, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.4)),
          ]),
        ),
      );
}
