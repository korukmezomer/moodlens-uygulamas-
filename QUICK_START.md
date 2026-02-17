# 🚀 Hızlı Başlangıç - TFLite Model Ekleme

## En Kolay Yol (3 Adım)

### 1️⃣ Model Dosyasını İndirin

**Seçenek A: GitHub'dan (Önerilen)**
```bash
# Tarayıcınızda şu linke gidin:
# https://github.com/search?q=fer2013+tflite+emotion

# Veya direkt indirme linki (örnek):
# wget https://github.com/[repo]/emotion_model.tflite
```

**Seçenek B: Test Modeli Oluşturun (Hızlı Test)**
```bash
cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication

# Python 3 ve TensorFlow gerekli
python3 create_simple_model.py
```

### 2️⃣ Dosyayı Doğru Yere Koyun

```bash
# Model dosyanızı şu klasöre kopyalayın:
cp ~/Downloads/emotion_model.tflite assets/models/emotion_model.tflite

# Veya Finder'da:
# 1. İndirdiğiniz emotion_model.tflite dosyasını bulun
# 2. mobil_aplication/assets/models/ klasörüne sürükleyin
```

### 3️⃣ Uygulamayı Çalıştırın

```bash
cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication
flutter pub get
flutter run
```

## ✅ Kontrol

Model dosyasının doğru yerde olduğunu kontrol edin:

```bash
ls -lh assets/models/emotion_model.tflite
```

Çıktı şöyle olmalı:
```
-rw-r--r--  1 user  staff  45K Dec 12 22:30 assets/models/emotion_model.tflite
```

## 📚 Detaylı Rehber

Daha detaylı bilgi için `MODEL_SETUP_GUIDE.md` dosyasına bakın.

## 🔗 Önerilen Model Kaynakları

1. **GitHub:**
   - https://github.com/search?q=fer2013+tflite
   - https://github.com/omar178/Emotion-recognition

2. **Kaggle:**
   - https://www.kaggle.com/datasets/msambare/fer2013

3. **TensorFlow Hub:**
   - https://tfhub.dev/

## ⚠️ Önemli Notlar

- Model dosyası `.tflite` uzantılı olmalı
- Dosya adı tam olarak `emotion_model.tflite` olmalı
- Model input: (48, 48, 1) veya (64, 64, 1) grayscale image
- Model output: 7 emotion class için probability scores

## 🆘 Sorun mu Yaşıyorsunuz?

1. Model dosyasının doğru yerde olduğundan emin olun
2. `flutter clean && flutter pub get` çalıştırın
3. Uygulamayı yeniden build edin
4. Konsolda model yükleme loglarını kontrol edin

