import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/security/secure_credential_store.dart';
import 'package:dest_os_ares/application/settings/ares_settings.dart';
import 'package:dest_os_ares/infrastructure/codegen/dynamic_ares_ai_gateway.dart';
import 'package:dest_os_ares/infrastructure/storage/json_file_store.dart';
import 'package:dest_os_ares/presentation/settings/ares_settings_screen.dart';

void main() {
  testWidgets('kayıtlı API anahtarı ekranda gerçek değeri göstermez',
      (tester) async {
    final temp = Directory.systemTemp.createTempSync('ares_settings_ui_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final credentials = InMemorySecureCredentialStore();
    final store = AresSettingsStore(
      store: JsonFileStore(directoryProvider: () async => temp),
      credentialStore: credentials,
    );

    await store.save(
      const AresSettings(
        freeBaseUrl: 'https://x.test/v1',
        freeModel: 'm1',
      ),
      apiKey: 'UI_SECRET_VALUE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AresSettingsScreen(
          store: store,
          gateway: DynamicAresAiGateway(settings: store),
        ),
      ),
    );

    expect(find.textContaining('API anahtarı güvenli depoda kayıtlı.'), findsOneWidget);
    expect(find.textContaining('UI_SECRET_VALUE'), findsNothing);
    expect(find.textContaining('••••••••'), findsOneWidget);
  });
}
