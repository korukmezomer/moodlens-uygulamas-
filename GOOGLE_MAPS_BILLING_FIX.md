# Google Maps Billing Sorunu Çözümü

Google Maps SDK timeout hatası alıyorsanız, bu genellikle API key'iniz için **billing (faturalandırma)** aktif olmadığı anlamına gelir.

## Sorun

Loglarda şu hataları görüyorsanız:
```
I/m140.bsj: Request m140.iwe failed with Status bwy{errorCode=REQUEST_TIMEOUT...
W/m140.blq: Failed client parameters RPC response...
```

Bu, Google Maps API'nin çalışması için gerekli servislerin yüklenemediği anlamına gelir.

## Çözüm Adımları

### 1. Google Cloud Console'a Giriş Yapın

1. [Google Cloud Console](https://console.cloud.google.com/) adresine gidin
2. API key'inizin bağlı olduğu projeyi seçin

### 2. Billing Hesabı Ekleyin

1. Sol menüden **"Billing"** (Faturalandırma) seçeneğine tıklayın
2. Eğer henüz bir billing hesabı yoksa, **"Link a billing account"** butonuna tıklayın
3. Yeni bir billing hesabı oluşturun veya mevcut bir hesabı bağlayın
4. Kredi kartı bilgilerinizi girin (Google Maps için ücretsiz kredi verilir)

### 3. Maps SDK for Android API'sini Etkinleştirin

1. Sol menüden **"APIs & Services" > "Library"** seçeneğine gidin
2. **"Maps SDK for Android"** arayın ve tıklayın
3. **"Enable"** butonuna tıklayın

### 4. API Key Kısıtlamalarını Kontrol Edin

1. **"APIs & Services" > "Credentials"** sayfasına gidin
2. API key'inize tıklayın
3. **"API restrictions"** bölümünde:
   - **"Restrict key"** seçeneğini işaretleyin
   - **"Maps SDK for Android"** seçeneğini ekleyin
4. **"Application restrictions"** bölümünde:
   - **"Android apps"** seçeneğini seçin
   - Package name: `com.example.mobil_aplication` ekleyin
   - SHA-1 fingerprint'inizi ekleyin (debug keystore için)

### 5. SHA-1 Fingerprint'i Alın

Debug keystore için:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

Release keystore için (production):
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

### 6. Uygulamayı Yeniden Derleyin

```bash
cd mobil_aplication
flutter clean
flutter pub get
flutter run
```

## Ücretsiz Kullanım Limitleri

Google Maps Platform ücretsiz kredi verir:
- **$200 aylık kredi** (her ay yenilenir)
- İlk 28,000 harita yüklemesi ücretsiz
- İlk 100,000 dinamik harita isteği ücretsiz

Çoğu küçük uygulama için bu limitler yeterlidir.

## Alternatif Çözüm (Test Amaçlı)

Eğer sadece test ediyorsanız ve billing eklemek istemiyorsanız:

1. **OpenStreetMap** kullanabilirsiniz (ücretsiz, açık kaynak)
2. **Mapbox** kullanabilirsiniz (ücretsiz tier mevcut)

Ancak Google Maps'in performansı ve özellikleri genellikle daha iyidir.

## Sorun Devam Ederse

1. API key'in doğru olduğundan emin olun (`AndroidManifest.xml` içinde)
2. SHA-1 fingerprint'in doğru eklendiğinden emin olun
3. Billing hesabının aktif olduğundan emin olun
4. Maps SDK for Android API'sinin etkin olduğundan emin olun
5. Birkaç dakika bekleyin (API değişikliklerinin yayılması zaman alabilir)

## Yardım

Daha fazla bilgi için:
- [Google Maps Platform Pricing](https://mapsplatform.google.com/pricing/)
- [Maps SDK for Android Setup](https://developers.google.com/maps/documentation/android-sdk/start)

