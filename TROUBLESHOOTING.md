# Sorun Giderme Rehberi

## 1. 403 Forbidden Hatası

### Sorun
Backend API'ye istek yaparken `403 Forbidden` hatası alıyorsunuz.

### Nedenler
1. **JWT Token geçersiz veya süresi dolmuş**: Token'ın süresi dolmuş olabilir
2. **Token formatı yanlış**: Token düzgün gönderilmiyor olabilir
3. **Backend authentication hatası**: JWT filter token'ı parse edemiyor olabilir

### Çözüm

#### Frontend (Flutter)
- Uygulama artık 403 hatası aldığında boş liste döndürüyor (kullanıcıyı rahatsız etmiyor)
- 401 hatası aldığında otomatik olarak auth data temizleniyor

#### Backend (Spring Boot)
- JWT filter artık token hatalarını daha iyi handle ediyor
- Geçersiz token durumunda 401 (Unauthorized) döndürüyor

#### Manuel Çözüm
1. Uygulamadan çıkış yapın
2. Tekrar giriş yapın (yeni token alınacak)
3. Eğer sorun devam ederse, backend loglarını kontrol edin

## 2. Google Maps Timeout Hatası

### Sorun
Google Maps yüklenmiyor, timeout hatası alıyorsunuz veya "beige background" görüyorsunuz.

### Nedenler
1. **Billing aktif değil**: Google Maps API kullanımı için billing hesabı gerekli
2. **API key yanlış yapılandırılmış**: API key doğru değil veya kısıtlamaları yanlış
3. **Maps SDK for Android etkin değil**: API etkinleştirilmemiş
4. **SHA-1 fingerprint eksik**: API key kısıtlamalarında SHA-1 eklenmemiş

### Çözüm

Detaylı adımlar için `GOOGLE_MAPS_BILLING_FIX.md` dosyasına bakın.

#### Hızlı Çözüm
1. [Google Cloud Console](https://console.cloud.google.com/) → Billing → Billing hesabı ekleyin
2. APIs & Services → Library → "Maps SDK for Android" → Enable
3. APIs & Services → Credentials → API key'inizi düzenleyin:
   - API restrictions: "Maps SDK for Android" ekleyin
   - Application restrictions: Android app ekleyin (package name + SHA-1)
4. Uygulamayı yeniden derleyin: `flutter clean && flutter pub get && flutter run`

#### SHA-1 Fingerprint Alma
```bash
# Debug keystore için
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

## 3. Öneriler Yüklenmiyor

### Sorun
Ana sayfada veya harita ekranında öneriler görünmüyor.

### Nedenler
1. **Backend'de öneri yok**: Henüz emotion log oluşturulmamış
2. **403/401 hatası**: Authentication sorunu
3. **Backend çalışmıyor**: Backend servisi down

### Çözüm
1. Önce bir fotoğraf çekin ve emotion log oluşturun
2. Backend loglarını kontrol edin
3. API endpoint'lerini test edin (Postman/curl ile)

## 4. Konum Alınamıyor

### Sorun
Uygulama mevcut konumunuzu alamıyor.

### Çözüm
1. Cihazınızda konum servislerinin açık olduğundan emin olun
2. Uygulama izinlerinde konum izninin verildiğinden emin olun
3. Android emülatör kullanıyorsanız, emülatör ayarlarından konum ayarlayın

## 5. Model Duygu Tespiti Yapmıyor

### Sorun
Model duyguları yanlış tespit ediyor veya hiç tespit etmiyor.

### Çözüm
1. Model dosyasının doğru yerde olduğundan emin olun: `assets/models/emotion_model_quant.tflite`
2. `pubspec.yaml` dosyasında asset'lerin tanımlı olduğundan emin olun
3. Model input/output shape'lerinin doğru olduğundan emin olun
4. Yeni bir model eğitmeyi deneyin (daha fazla veri ile)

## Genel İpuçları

1. **Logları kontrol edin**: Flutter ve backend loglarını düzenli olarak kontrol edin
2. **Token'ı kontrol edin**: Token'ın geçerli olduğundan emin olun
3. **Backend'i kontrol edin**: Backend servisinin çalıştığından emin olun
4. **Network bağlantısını kontrol edin**: İnternet bağlantınızın aktif olduğundan emin olun

## Yardım

Sorun devam ederse:
1. Flutter loglarını kontrol edin: `flutter run` çıktısına bakın
2. Backend loglarını kontrol edin: Spring Boot console çıktısına bakın
3. API endpoint'lerini test edin: Postman veya curl ile

