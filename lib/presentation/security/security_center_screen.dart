import 'package:flutter/material.dart';

import '../../application/security/secure_credential_store.dart';
import '../../application/security/security_screen_model.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key, this.model = const SecurityScreenModel(), this.credentialStore});

  final SecurityScreenModel model;
  final SecureCredentialStore? credentialStore;

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  late Future<bool> _keyStatus;

  @override
  void initState() {
    super.initState();
    _keyStatus = _readKeyStatus();
  }

  Future<bool> _readKeyStatus() async {
    final store = widget.credentialStore ?? FlutterSecureCredentialStore();
    final value = await store.readApiKey(providerId: 'free_remote');
    return value != null && value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: Text(widget.model.title),
        backgroundColor: const Color(0xFF08131D),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SecurityCard(
            title: 'Ücretli AI kapısı',
            value: 'Kapalı • açık onay olmadan çalışmaz',
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          FutureBuilder<bool>(
            future: _keyStatus,
            builder: (context, snapshot) {
              final text = snapshot.hasError
                  ? 'Kontrol edilemedi'
                  : snapshot.connectionState != ConnectionState.done
                      ? 'Kontrol ediliyor…'
                      : snapshot.data == true
                          ? 'Evet • güvenli depoda'
                          : 'Hayır • kayıtlı değil';
              return _SecurityCard(
                title: 'API anahtarı',
                value: text,
                icon: snapshot.data == true ? Icons.lock : Icons.lock_outline,
              );
            },
          ),
          const SizedBox(height: 12),
          const _SecurityCard(
            title: 'Dosya yolu koruması',
            value: 'Korumalı • izin verilen çıktı alanı dışına yazılmaz',
            icon: Icons.folder_outlined,
          ),
          const SizedBox(height: 12),
          const _SecurityCard(
            title: 'Güvenlik özeti',
            value: 'İzinsiz dış işlem ve otomatik ücretli AI kullanımı engellenir.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 12),
          _SecurityCard(
            title: 'Kayıtlı güvenlik olayları',
            value: '${widget.model.blockedActions} engellenen işlem • ${widget.model.pendingApprovals} bekleyen onay',
            icon: Icons.fact_check_outlined,
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF0A1722),
        child: ListTile(
          leading: Icon(icon, color: Colors.cyanAccent),
          title: Text(title, style: const TextStyle(color: Colors.white70)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(value, style: const TextStyle(color: Colors.white, height: 1.3)),
          ),
        ),
      );
}
