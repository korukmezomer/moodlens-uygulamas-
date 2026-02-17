# MoodLens - Flutter Mobile Application

MoodLens, kameradan ruh hali tespit edip yakın ve uygun mekânlar/etkinlikler öneren mobil uygulama.

## Özellikler

- ✅ **Onboarding Ekranları**: İlk kullanım için tanıtım ekranları
- ✅ **Kimlik Doğrulama**: Kayıt ol ve giriş yap
- ✅ **Rol Bazlı Erişim**: Admin ve User rolleri
- ✅ **Admin Panel**: Dashboard, kullanıcı yönetimi, mekan yönetimi, analitik
- ✅ **User Dashboard**: Ana sayfa, kamera, geçmiş, profil
- ✅ **Modern UI**: Material Design 3 ile modern ve kullanıcı dostu arayüz

## Kurulum

### Gereksinimler

- Flutter SDK 3.10.1+
- Dart 3.0+
- Android Studio / VS Code
- Backend API çalışıyor olmalı (mobilbackend)

### Adımlar

1. **Paketleri yükle:**
```bash
cd mobil_aplication
flutter pub get
```

2. **API URL'ini yapılandır:**
`lib/config/app_config.dart` dosyasında `baseUrl` değerini backend'inizin adresine göre güncelleyin:
- Android Emulator: `http://10.0.2.2:8080/api/v1`
- iOS Simulator: `http://localhost:8080/api/v1`
- Gerçek Cihaz: `http://YOUR_IP:8080/api/v1`

3. **Uygulamayı çalıştır:**
```bash
flutter run
```

## Proje Yapısı

```
lib/
├── config/          # Uygulama yapılandırmaları
├── models/          # Veri modelleri
├── services/        # API servisleri
├── providers/       # State management (Provider)
├── screens/         # Ekranlar
│   ├── onboarding/  # Tanıtım ekranları
│   ├── auth/        # Giriş/Kayıt ekranları
│   ├── admin/       # Admin panel ekranları
│   └── user/        # Kullanıcı ekranları
├── theme/           # Tema yapılandırması
└── utils/           # Yardımcı fonksiyonlar
```

## Kullanım Akışı

1. **İlk Açılış**: Onboarding ekranları gösterilir
2. **Kayıt/Giriş**: Kullanıcı kayıt olur veya giriş yapar
3. **Rol Kontrolü**: 
   - **ADMIN** → Admin Panel'e yönlendirilir
   - **USER** → User Dashboard'a yönlendirilir

## Admin Panel Özellikleri

- Dashboard: İstatistikler ve son aktiviteler
- Kullanıcı Yönetimi: Kullanıcı listesi ve yönetimi
- Mekan Yönetimi: Mekan listesi ve yönetimi
- Analitik: Raporlar ve analizler

## User Dashboard Özellikleri

- Ana Sayfa: Öneriler ve hızlı erişim
- Kamera: Ruh hali tespiti için selfie çekme
- Geçmiş: Önceki emotion log'ları
- Profil: Kullanıcı bilgileri ve ayarlar

## Teknoloji Stack

- **Framework**: Flutter
- **State Management**: Provider
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences
- **UI**: Material Design 3
- **Fonts**: Google Fonts (Inter)

## Geliştirme Notları

- Backend API ile iletişim için `ApiService` kullanılır
- Authentication state `AuthProvider` ile yönetilir
- JWT token otomatik olarak header'a eklenir
- Onboarding durumu SharedPreferences'ta saklanır

## Lisans

Bu proje eğitim amaçlıdır.
