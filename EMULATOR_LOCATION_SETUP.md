# Emülatör Konum Ayarlama Rehberi

Emülatörde uygulama yanlış konum gösteriyorsa (örneğin 37.4219983, -122.084), emülatörün konum ayarlarını değiştirmeniz gerekir.

## Android Studio Emülatörü

### Yöntem 1: Extended Controls (Önerilen)

1. Emülatör penceresinde sağ taraftaki **⋮** (üç nokta) butonuna tıklayın
2. **Location** sekmesine gidin
3. Haritada istediğiniz konumu seçin veya koordinatları manuel girin
4. **Set Location** butonuna tıklayın

### Yöntem 2: ADB Komutu

Terminal'de şu komutu çalıştırın:

```bash
# İstanbul koordinatları
adb emu geo fix 28.9784 41.0082

# Veya başka bir şehir
# Örnek: Ankara
adb emu geo fix 32.8597 39.9334
```

### Yöntem 3: GPS Simülasyonu

1. Emülatörde **Settings** > **Location** açın
2. **Mode** seçeneğini **High accuracy** yapın
3. Extended Controls'dan konum ayarlayın

## Fiziksel Cihaz

Fiziksel cihazda konum sorunu yaşıyorsanız:

1. Cihaz ayarlarından **Location Services** açık olduğundan emin olun
2. Uygulama izinlerinde **Location** izninin verildiğinden emin olun
3. **High accuracy** modunu kullanın

## Test

Konumun doğru ayarlandığını kontrol etmek için:

1. Uygulamada harita ekranına gidin
2. Sağ üstteki konum butonuna tıklayın
3. Harita doğru konuma gitmeli

## Yaygın Sorunlar

### Emülatör varsayılan konumu gösteriyor

- **Çözüm**: Extended Controls'dan konum ayarlayın veya ADB komutu kullanın

### Konum hiç alınamıyor

- **Çözüm**: 
  1. Emülatörü yeniden başlatın
  2. Location Services'in açık olduğundan emin olun
  3. Uygulama izinlerini kontrol edin

### Konum güncellenmiyor

- **Çözüm**: 
  1. Uygulamayı kapatıp açın
  2. Emülatörü yeniden başlatın
  3. ADB komutu ile konum ayarlayın

## Koordinat Örnekleri

```bash
# İstanbul
adb emu geo fix 28.9784 41.0082

# Ankara
adb emu geo fix 32.8597 39.9334

# İzmir
adb emu geo fix 27.1428 38.4237

# Bursa
adb emu geo fix 29.0610 40.1826
```

## Notlar

- Emülatör konumu uygulama kapatılıp açıldığında sıfırlanabilir
- Her seferinde konum ayarlamak yerine, Extended Controls'dan kalıcı bir konum seçebilirsiniz
- Fiziksel cihazda gerçek GPS konumu otomatik olarak alınır

