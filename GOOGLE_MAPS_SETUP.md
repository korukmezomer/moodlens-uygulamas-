# Google Maps API Key Kurulumu

## Adım 1: Google Cloud Console'da API Key Oluşturma

1. [Google Cloud Console](https://console.cloud.google.com/)'a gidin
2. Yeni bir proje oluşturun veya mevcut projeyi seçin
3. **APIs & Services > Credentials** bölümüne gidin
4. **+ CREATE CREDENTIALS > API Key** seçin
5. API key'inizi kopyalayın

## Adım 2: Maps SDK'yı Etkinleştirme

1. **APIs & Services > Library** bölümüne gidin
2. "Maps SDK for Android" arayın ve etkinleştirin
3. "Maps SDK for iOS" (iOS için) etkinleştirin

## Adım 3: API Key'i AndroidManifest.xml'e Ekleme

`android/app/src/main/AndroidManifest.xml` dosyasında:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="BURAYA_API_KEY_INIZI_YAPISTIRIN" />
```

## Adım 4: API Key Kısıtlamaları (Önerilen)

Güvenlik için API key'inizi kısıtlayın:

1. **API restrictions**: Sadece "Maps SDK for Android" seçin
2. **Application restrictions**: Android uygulamaları için package name ve SHA-1 fingerprint ekleyin

### SHA-1 Fingerprint Alma:

```bash
# Debug keystore için
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore için (eğer varsa)
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

## Notlar

- API key ücretsizdir (belirli limitler dahilinde)
- Günlük 28,000 map load ücretsiz
- Aylık 100,000 map load ücretsiz
- Daha fazla bilgi: https://developers.google.com/maps/billing-and-pricing/pricing

