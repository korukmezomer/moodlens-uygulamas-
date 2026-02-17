# Google Maps API Key Düzeltme Adımları

## Mevcut Durum
- ✅ Billing hesabı aktif
- ✅ Android uygulama kısıtlaması eklenmiş
- ✅ SHA-1 fingerprint eklenmiş: `8D:95:92:85:BD:5A:DD:B1:97:A3:8B:5C:3D:9D:3E:5E:BC:17:D2:49`
- ✅ Paket adı: `com.example.mobil_aplication`
- ❌ **API kısıtlamaları "Anahtarı kısıtlamayın" seçili** - Bu değiştirilmeli!

## Yapılması Gerekenler

### Adım 1: API Kısıtlamalarını Değiştirin

1. Google Cloud Console'da API key'inizi düzenleyin
2. **"API kısıtlamaları"** bölümünde:
   - ❌ **"Anahtarı kısıtlamayın"** seçeneğini **KALDIRIN**
   - ✅ **"Kısıtla anahtarı"** seçeneğini seçin
   - ✅ Açılan listeden **"Maps SDK for Android"** seçeneğini ekleyin
   - ✅ (Opsiyonel) **"Maps SDK for iOS"** ekleyin (gelecekte iOS için)
   - ✅ (Opsiyonel) **"Geocoding API"** ekleyin
   - ✅ (Opsiyonel) **"Places API"** ekleyin

### Adım 2: Maps SDK for Android API'sini Etkinleştirin

1. Google Cloud Console'da sol menüden **"APIs & Services" > "Library"** seçeneğine gidin
2. Arama kutusuna **"Maps SDK for Android"** yazın
3. **"Maps SDK for Android"** sonucuna tıklayın
4. **"Enable"** (Etkinleştir) butonuna tıklayın
5. Aynı şekilde **"Maps SDK for iOS"** API'sini de etkinleştirin (gelecekte iOS için)

### Adım 3: Değişiklikleri Kaydedin

1. API key düzenleme sayfasına geri dönün
2. **"Kaydetmek"** (Save) butonuna tıklayın
3. **Not:** Ayarların geçerli olması 5 dakikaya kadar sürebilir

### Adım 4: Uygulamayı Test Edin

1. 5 dakika bekleyin
2. Uygulamayı yeniden başlatın:
   ```bash
   cd mobil_aplication
   flutter clean
   flutter pub get
   flutter run
   ```

## Kontrol Listesi

- [ ] API kısıtlamalarında "Kısıtla anahtarı" seçili
- [ ] "Maps SDK for Android" API'si eklendi
- [ ] Maps SDK for Android API'si Library'de etkinleştirildi
- [ ] Değişiklikler kaydedildi
- [ ] 5 dakika beklendi
- [ ] Uygulama yeniden başlatıldı

## Beklenen Sonuç

Değişikliklerden sonra:
- ✅ Harita tile'ları yüklenecek
- ✅ Harita düzgün görünecek (bej renk yerine normal harita)
- ✅ Marker'lar görünecek
- ✅ Konumunuz haritada gösterilecek

## Sorun Devam Ederse

1. **API key'in doğru olduğundan emin olun:**
   - `AndroidManifest.xml` dosyasında: `AIzaSyDiW6xaSH0iSg24H5QWKcaa_5ibyW2oeXY`

2. **Billing hesabının aktif olduğundan emin olun:**
   - Google Cloud Console > Billing
   - Billing hesabı bağlı ve aktif mi?

3. **API'lerin etkin olduğundan emin olun:**
   - APIs & Services > Library
   - "Maps SDK for Android" etkin mi?

4. **SHA-1 fingerprint'i kontrol edin:**
   - Debug keystore SHA-1: `8D:95:92:85:BD:5A:DD:B1:97:A3:8B:5C:3D:9D:3E:5E:BC:17:D2:49`
   - Google Cloud Console'da bu fingerprint ekli mi?

5. **Paket adını kontrol edin:**
   - Paket adı: `com.example.mobil_aplication`
   - Google Cloud Console'da bu paket adı ekli mi?

## Önemli Notlar

- API kısıtlamaları olmadan API key güvenli değildir
- "Anahtarı kısıtlamayın" seçeneği production için önerilmez
- Her API için ayrı ayrı etkinleştirme gerekebilir
- Değişikliklerin yayılması 5 dakikaya kadar sürebilir
- Billing hesabı aktif olsa bile API'lerin etkinleştirilmesi gerekir

