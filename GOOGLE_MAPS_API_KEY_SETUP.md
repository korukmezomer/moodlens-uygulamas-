# Google Maps API Key Kurulum Rehberi

## Mevcut Durum

API key'iniz: `AIzaSyDiW6xaSH0iSg24H5QWKcaa_5ibyW2oeXY`

Görüntüden görüldüğü üzere:
- ✅ Android uygulama kısıtlaması eklenmiş (Paket adı: `com.example.mobil_...`)
- ✅ SHA-1 fingerprint eklenmiş
- ❌ **API kısıtlamaları "Anahtarı kısıtlamayın" seçili** - Bu değiştirilmeli!

## Yapılması Gerekenler

### 1. API Kısıtlamalarını Ayarlayın

1. Google Cloud Console'da API key'inizi düzenleyin
2. **"API kısıtlamaları"** bölümünde:
   - ❌ "Anahtarı kısıtlamayın" seçeneğini **KALDIRIN**
   - ✅ **"Kısıtla anahtarı"** seçeneğini seçin
   - ✅ **"Maps SDK for Android"** API'sini ekleyin
   - ✅ **"Maps SDK for iOS"** API'sini ekleyin (gelecekte iOS için)
   - ✅ **"Geocoding API"** ekleyin (opsiyonel, adres çözümleme için)
   - ✅ **"Places API"** ekleyin (opsiyonel, mekan arama için)

### 2. Maps SDK for Android API'sini Etkinleştirin

1. Google Cloud Console'da **"APIs & Services" > "Library"** sayfasına gidin
2. **"Maps SDK for Android"** arayın
3. **"Enable"** butonuna tıklayın
4. Aynı şekilde **"Maps SDK for iOS"** API'sini de etkinleştirin

### 3. SHA-1 Fingerprint'i Kontrol Edin

Görüntüde görünen fingerprint: `8D:95:92:85:BD:5A:DD:B1:97:A3:8B:5C:3D:...`

Bu fingerprint'in doğru olduğundan emin olun. Eğer emin değilseniz, debug keystore için:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

### 4. Paket Adını Kontrol Edin

Görüntüde görünen paket adı: `com.example.mobil_...`

Tam paket adının `com.example.mobil_aplication` olduğundan emin olun.

### 5. Değişiklikleri Kaydedin

1. **"Kaydetmek"** (Save) butonuna tıklayın
2. **Not:** Ayarların geçerli olması 5 dakikaya kadar sürebilir
3. Uygulamayı yeniden başlatın

## Kontrol Listesi

- [ ] API kısıtlamalarında "Kısıtla anahtarı" seçili
- [ ] "Maps SDK for Android" API'si eklendi
- [ ] Maps SDK for Android API'si etkinleştirildi (Library'de)
- [ ] Android uygulama kısıtlaması doğru paket adı ile eklenmiş
- [ ] SHA-1 fingerprint doğru eklenmiş
- [ ] Değişiklikler kaydedildi
- [ ] 5 dakika beklendi
- [ ] Uygulama yeniden başlatıldı

## Test

Uygulamayı yeniden çalıştırın:

```bash
cd mobil_aplication
flutter clean
flutter pub get
flutter run
```

Artık harita tile'ları yüklenmeli ve harita düzgün görünmeli.

## Sorun Devam Ederse

1. **API key'in doğru olduğundan emin olun:**
   - `AndroidManifest.xml` dosyasında API key doğru mu?
   - Google Cloud Console'da API key'in adı doğru mu?

2. **Billing hesabının aktif olduğundan emin olun:**
   - Google Cloud Console > Billing
   - Billing hesabı bağlı mı?

3. **API'lerin etkin olduğundan emin olun:**
   - APIs & Services > Library
   - "Maps SDK for Android" etkin mi?

4. **SHA-1 fingerprint'i kontrol edin:**
   - Debug keystore için: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1`
   - Release keystore için: Release keystore'unuzun SHA-1'ini alın

5. **Paket adını kontrol edin:**
   - `android/app/build.gradle` dosyasında `applicationId` doğru mu?
   - Google Cloud Console'daki paket adı ile eşleşiyor mu?

## Önemli Notlar

- API kısıtlamaları olmadan API key güvenli değildir
- "Anahtarı kısıtlamayın" seçeneği production için önerilmez
- Her API için ayrı ayrı etkinleştirme gerekebilir
- Değişikliklerin yayılması 5 dakikaya kadar sürebilir

