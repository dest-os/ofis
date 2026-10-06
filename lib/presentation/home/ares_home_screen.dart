import 'package:flutter/material.dart';

import '../../application/environment/environment_health_service.dart';
import '../../core/constants/ares_constants.dart';
import '../../domain/codegen/generation_result.dart';
import '../../domain/content/content_generation_result.dart';
import '../../domain/content/content_mode.dart';
import '../../infrastructure/video/ffmpeg_command_runner.dart';
import '../codegen/code_generation_screen.dart';
import '../content/content_generation_screen.dart';
import '../voice/voice_screen.dart';
import '../ai_radar/ai_radar_screen.dart';

/// DEST-OS ARES için sadeleştirilmiş 14 inç tablet ana ofis ekranı.
class AresHomeScreen extends StatefulWidget {
  const AresHomeScreen({
    super.key,
    this.onCodeGenerate,
    this.onContentGenerate,
    this.environmentHealthService,
    this.onVideoRender,
    this.chatBuilder,
    this.settingsBuilder,
    this.learningBuilder,
    this.healthServiceFactory,
    this.liveOperationsBuilder,
    this.voiceBuilder,
  });

  final WidgetBuilder? chatBuilder;
  final WidgetBuilder? settingsBuilder;
  final WidgetBuilder? learningBuilder;
  final WidgetBuilder? liveOperationsBuilder;
  final WidgetBuilder? voiceBuilder;
  final EnvironmentHealthService Function()? healthServiceFactory;
  final EnvironmentHealthService? environmentHealthService;

  final Future<GenerationResult> Function(
    String request, {
    void Function(String status)? onProgress,
  })? onCodeGenerate;

  final Future<ContentGenerationResult> Function({
    required ContentMode mode,
    required String request,
    String duration,
    String style,
    String platform,
    String contentType,
    void Function(String status)? onProgress,
  })? onContentGenerate;

  final Future<VideoRenderResult> Function({
    required List<String> arguments,
    required String relativeOutputRoot,
  })? onVideoRender;

  @override
  State<AresHomeScreen> createState() => _AresHomeScreenState();
}

class _AresHomeScreenState extends State<AresHomeScreen> {
  EnvironmentHealth? _health;

  @override
  void initState() {
    super.initState();
    _refreshHealth();
  }

  void _refreshHealth() {
    final service = widget.healthServiceFactory?.call() ?? widget.environmentHealthService;
    service?.check().then((value) {
      if (mounted) setState(() => _health = value);
    });
  }

  Future<void> _open(WidgetBuilder? builder, {bool refresh = false}) async {
    if (builder == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    if (refresh && mounted) _refreshHealth();
  }

  void _openMobile() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CodeGenerationScreen(onGenerate: widget.onCodeGenerate),
    ));
  }

  void _openContent(ContentMode mode) {
    final callback = widget.onContentGenerate;
    if (callback == null) {
      _message('Üretim servisi hazır değil. Ayarlar bölümünden yapay zekâyı test edin.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ContentGenerationScreen(
        mode: mode,
        onGenerate: callback,
        onRender: widget.onVideoRender,
      ),
    ));
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('DEST-OS ARES', style: TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('ANA OFİS • İbrahim Halil Ezen', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
                    _HeaderButton(icon: Icons.radar, label: 'AI Radar', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AiRadarScreen()))),
                    if (widget.settingsBuilder != null) ...[
                      const SizedBox(width: 10),
                      _HeaderButton(icon: Icons.settings, label: 'Ayarlar', onTap: () => _open(widget.settingsBuilder, refresh: true)),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                _OfficeFlow(onTap: widget.voiceBuilder == null ? null : () => _open(widget.voiceBuilder)),
                const SizedBox(height: 16),
                if (_health != null) _HealthCard(health: _health!),
                const SizedBox(height: 16),
                _SectionTitle(title: 'HIZLI İŞLEMLER', subtitle: 'Tek dokunuşla başlat'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 4 : 2;
                    final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ActionCard(width: width, icon: Icons.chat_bubble_outline, title: 'Sohbet', subtitle: 'ARES ile konuş', onTap: () => _open(widget.chatBuilder)),
                        _ActionCard(width: width, icon: Icons.phone_android, title: 'Mobil Üret', subtitle: 'Uygulama üret', onTap: _openMobile),
                        _ActionCard(width: width, icon: Icons.settings, title: 'Ayarlar', subtitle: 'AI ve bağlantılar', onTap: () => _open(widget.settingsBuilder, refresh: true)),
                        _ActionCard(width: width, icon: Icons.monitor_heart_outlined, title: 'Canlı Operasyon', subtitle: 'Görevleri gör', onTap: () => _open(widget.liveOperationsBuilder)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'İKİNCİL ÜRETİM', subtitle: 'Gerektiğinde kullan'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _SecondaryButton(icon: Icons.movie_outlined, text: 'Video Paketi', onTap: () => _openContent(ContentMode.video))),
                    const SizedBox(width: 12),
                    Expanded(child: _SecondaryButton(icon: Icons.description_outlined, text: 'Genel İçerik', onTap: () => _openContent(ContentMode.general))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficeFlow extends StatelessWidget {
  const _OfficeFlow({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const names = ['DİNLEYİCİ', 'CEO', 'ARES', 'CIO'];
    return Card(
      color: const Color(0xFF08131C),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.cyanAccent.withOpacity(.20))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            for (var i = 0; i < names.length; i++) ...[
              Expanded(child: _FlowNode(label: names[i], active: i == 2, onTap: i == 0 ? onTap : null)),
              if (i < names.length - 1) const Icon(Icons.arrow_forward, color: Colors.cyanAccent, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.label, required this.active, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(color: active ? const Color(0xFF0B3140) : const Color(0xFF0A1722), borderRadius: BorderRadius.circular(12)),
        child: Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? Colors.cyanAccent : Colors.white70, fontWeight: FontWeight.bold)),
      ),
      );
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});
  final EnvironmentHealth health;

  @override
  Widget build(BuildContext context) {
    final localReady = health.localAi.ready;
    final backupReady = health.freeAi.ready;
    final aiReady = localReady || backupReady;
    return Card(
      color: const Color(0xFF08131C),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SİSTEM DURUMU', style: TextStyle(color: Colors.cyanAccent, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 12, children: [
            _HealthItem(title: 'Yerel AI', ready: localReady, message: localReady ? 'Hazır • Qwen yerel model çalışıyor.' : 'Eksik • Ayarlar > Yerel AI bölümünden bağlantıyı test edin.'),
            _HealthItem(title: 'Yedek AI', ready: backupReady, message: backupReady ? 'Hazır • Yedek bağlantı çalışıyor.' : 'Bekliyor • İsterseniz ücretsiz yedek bağlantı ekleyin.'),
            _HealthItem(title: 'FFmpeg', ready: health.ffmpeg.ready, message: health.ffmpeg.ready ? 'Hazır • Video render kullanılabilir.' : 'Eksik • Gerçek video render için FFmpeg gerekir.'),
          ]),
          if (!aiReady) ...[
            const SizedBox(height: 12),
            const _Notice(title: 'AI hazır değil', text: 'Eksik olan: Yerel AI veya yedek AI bağlantısı. Yapılacak: Ayarlar ekranını açın, yerel Qwen bağlantısını kaydedip test edin.'),
          ],
          if (!health.ffmpeg.ready) ...[
            const SizedBox(height: 8),
            const _Notice(title: 'Video render hazır değil', text: 'Video paketi yine üretilebilir. Gerçek render için FFmpeg kurulmalı ve uygulamanın erişebildiği bir konumda olmalıdır.'),
          ],
        ]),
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  const _HealthItem({required this.title, required this.ready, required this.message});
  final String title;
  final bool ready;
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 330,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ready ? Icons.check_circle : Icons.warning_amber_rounded, color: ready ? Colors.greenAccent : Colors.orangeAccent, size: 22),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, height: 1.25)),
          ])),
        ]),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF151E25), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orangeAccent.withOpacity(.28))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.white70, height: 1.3)),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        Text(subtitle, style: const TextStyle(color: Colors.white54)),
      ]);
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label));
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.width, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 126,
        child: Card(
          color: const Color(0xFF0A1722),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.cyanAccent.withOpacity(.20))),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
              Icon(icon, color: Colors.cyanAccent, size: 34),
              const SizedBox(width: 14),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
              ])),
              const Icon(Icons.chevron_right, color: Colors.cyanAccent),
            ])),
          ),
        ),
      );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(text), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)));
}
