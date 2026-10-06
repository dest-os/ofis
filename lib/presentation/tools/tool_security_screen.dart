import 'package:flutter/material.dart';

import '../../application/tools/in_memory_tool_registry.dart';
import '../../application/tools/registered_tool_gateway.dart';
import '../../domain/tools/tool_definition.dart';
import '../../domain/tools/tool_kind.dart';
import '../../domain/tools/tool_request.dart';
import '../../domain/tools/tool_risk_level.dart';

class ToolSecurityScreen extends StatefulWidget {
  const ToolSecurityScreen({super.key});

  @override
  State<ToolSecurityScreen> createState() => _ToolSecurityScreenState();
}

class _ToolSecurityScreenState extends State<ToolSecurityScreen> {
  final _registry = InMemoryToolRegistry();
  late final _gateway = RegisteredToolGateway(registry: _registry);

  String _message = 'Araç güvenlik durumu hazır.';

  Future<void> _runDemo() async {
    try {
      await _registry.register(
        const ToolDefinition(
          id: 'demo-external-write',
          name: 'Demo Harici Yazma Aracı',
          description: 'Onay gerektiren örnek araç.',
          kind: ToolKind.restApi,
          riskLevel: ToolRiskLevel.high,
          externalWrite: true,
        ),
      );

      final decision = await _gateway.authorize(
        ToolRequest(
          id: 'tool-request-1',
          toolId: 'demo-external-write',
          action: 'write',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      if (!mounted) return;
      setState(() {
        _message =
            '${decision.type.name}: ${decision.reason}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARES • Araç & Güvenlik'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tool Gateway',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Araçlar doğrudan çalıştırılmaz; önce kayıt, risk ve izin kontrolünden geçer.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _runDemo,
            icon: const Icon(Icons.security_outlined),
            label: const Text('Güvenlik kontrolünü çalıştır'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_message),
            ),
          ),
        ],
      ),
    );
  }
}
