import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/voice/voice_command_parser.dart';

void main() {
  const parser = VoiceCommandParser();

  test('Türkçe navigasyon komutlarını toleranslı tanır', () {
    expect(parser.parse('Sohbet aç').type, VoiceCommandActionType.openChat);
    expect(parser.parse('ayarları ac').type, VoiceCommandActionType.openSettings);
    expect(parser.parse('Canlı operasyonu aç').type, VoiceCommandActionType.openLiveOperations);
    expect(parser.parse('DUR').type, VoiceCommandActionType.stop);
  });

  test('mobil üretim komutundan isteği ayırır', () {
    final action = parser.parse('Mobil uygulama üret, basit bir not uygulaması yap');
    expect(action.type, VoiceCommandActionType.mobileProduction);
    expect(action.request, 'basit bir not uygulaması yap');
  });

  test('bilinmeyen komut güvenli biçimde reddedilir', () {
    expect(parser.parse('Bambaşka bir şey söyle').type, VoiceCommandActionType.unknown);
  });
}
