import 'dart:io';

class AppConfig {
  // Android emulator için özel IP: 10.0.2.2
  // iOS simulator ve desktop için: localhost
  // Gerçek cihaz için: Mac'inizin yerel IP adresi (ör: 192.168.1.x)
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator için
      return 'http://10.0.2.2:8080/api/v1';
    } else if (Platform.isIOS) {
      // iOS simulator için
      return 'http://localhost:8080/api/v1';
    } else {
      // Desktop/Web için
      return 'http://localhost:8080/api/v1';
    }
  }
  
  static const String appName = 'MoodLens';
  static const String appVersion = '1.0.0';
}

