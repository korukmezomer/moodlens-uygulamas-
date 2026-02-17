# Google Maps API Key Düzeltme Rehberi

## Sorun
Google Maps haritası bej ekran olarak kalıyor ve "Authorization failure" hatası alıyorsunuz.

## Çözüm Adımları

### 1. Google Cloud Console'a Gidin
https://console.cloud.google.com/apis/credentials

### 2. API Key'inizi Bulun
API Key: `AIzaSyDiW6xaSH0iSg24H5QWKcaa_5ibyW2oeXY`

### 3. API Key'i Düzenleyin
1. API key'inize tıklayın
2. **Application restrictions** bölümünde:
   - **Android apps** seçin
   - **+ Add an item** butonuna tıklayın
   - Şu bilgileri ekleyin:
     - **Package name:** `com.example.mobil_aplication`
     - **SHA-1 certificate fingerprint:** `8D:95:92:85:BD:5A:DD:B1:97:A3:8B:5C:3D:9D:3E:5E:BC:17:D2:49`

### 4. Maps SDK'yı Etkinleştirin
1. **APIs & Services > Library** bölümüne gidin
2. "Maps SDK for Android" arayın
3. **ENABLE** butonuna tıklayın

### 5. API Restrictions (Opsiyonel ama Önerilen)
**API restrictions** bölümünde:
- **Restrict key** seçin
- Sadece şunları seçin:
  - ✅ Maps SDK for Android
  - ✅ Maps SDK for iOS (eğer iOS da kullanacaksanız)

### 6. Değişiklikleri Kaydedin
**SAVE** butonuna tıklayın

### 7. Bekleyin
API key değişiklikleri 5-10 dakika içinde aktif olur.

### 8. Uygulamayı Yeniden Başlatın
```bash
flutter clean
flutter pub get
flutter run
```

## Notlar
- SHA-1 fingerprint debug keystore için: `8D:95:92:85:BD:5A:DD:B1:97:A3:8B:5C:3D:9D:3E:5E:BC:17:D2:49`
- Release build için farklı bir SHA-1 fingerprint gerekir
- API key değişiklikleri hemen aktif olmayabilir, birkaç dakika bekleyin

