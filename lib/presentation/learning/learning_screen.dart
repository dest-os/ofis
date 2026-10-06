import 'package:flutter/material.dart';

import '../../application/archive/work_archive_repository.dart';
import '../../core/format/tr_date.dart';
import '../../domain/archive/work_archive_entry.dart';

/// Eğitim / Çalışma Arşivi: tarih başlıklı kayıtlar, elle silinebilir.
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key, required this.archive});

  final WorkArchiveRepository archive;

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final TextEditingController _search = TextEditingController();
  List<WorkArchiveEntry> _entries = const <WorkArchiveEntry>[];
  int _oldCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final all = await widget.archive.search('');
    final filtered = await widget.archive.search(_search.text);
    final limit = DateTime.now().subtract(const Duration(days: 90));
    if (!mounted) return;
    setState(() {
      _entries = filtered;
      _oldCount = all.where((e) => e.completedAt.isBefore(limit)).length;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(WorkArchiveEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kayıt silinsin mi?'),
        content: Text('${entry.title}\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.archive.delete(entry.id.value);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final limit = DateTime.now().subtract(const Duration(days: 90));
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(title: const Text('EĞİTİM — ÇALIŞMA ARŞİVİ'), backgroundColor: const Color(0xFF08131D)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => _reload(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Kayıtlarda ara…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_oldCount > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF241D10), borderRadius: BorderRadius.circular(8)),
              child: Text('90 günden eski $_oldCount kayıt var. Gerekmiyorsa silebilirsiniz.', style: const TextStyle(color: Colors.orangeAccent)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(child: Text('Henüz kayıt yok. Sohbet ve üretimler burada görünür.', style: TextStyle(color: Colors.white60)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          final isOld = entry.completedAt.isBefore(limit);
                          return Card(
                            color: const Color(0xFF0A1722),
                            child: ListTile(
                              title: Text(entry.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${entry.tags.join(' · ')}${isOld ? ' · eski' : ''}\n${clipText(entry.summary, 200)}',
                                  style: const TextStyle(color: Colors.white60, height: 1.3),
                                ),
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: 'Sil',
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(entry),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
