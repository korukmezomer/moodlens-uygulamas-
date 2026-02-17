# FER2013 Dataset ile Model Eğitimi Rehberi

Bu rehber, FER2013 dataset'i ile emotion detection modeli eğitmenize yardımcı olacaktır.

## 📋 Gereksinimler

1. **Python 3.8+** (Python 3.13+ TensorFlow ile uyumlu değil)
2. **TensorFlow 2.x**
3. **FER2013 Dataset** (fer2013.csv)
4. **Yeterli RAM** (en az 8GB önerilir)
5. **GPU** (opsiyonel ama önerilir - eğitim çok daha hızlı olur)

## 📥 Dataset İndirme

FER2013 dataset'ini şuradan indirebilirsiniz:
- **Kaggle:** https://www.kaggle.com/datasets/msambare/fer2013
- Dataset dosyası: `fer2013.csv`

## 🚀 Hızlı Başlangıç

### Adım 1: Python Ortamını Hazırlayın

```bash
# Virtual environment oluşturun (önerilir)
python3 -m venv emotion_env
source emotion_env/bin/activate  # Mac/Linux
# veya
emotion_env\Scripts\activate  # Windows

# Gerekli paketleri yükleyin
pip install tensorflow numpy pandas scikit-learn matplotlib
```

### Adım 2: Dataset'i Hazırlayın

```bash
# Dataset dosyasını proje klasörüne kopyalayın
cp ~/Downloads/fer2013.csv /Users/omerkorukmez/Desktop/mobil/mobil_aplication/
```

### Adım 3: Modeli Eğitin

```bash
cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication
python3 train_emotion_model.py
```

Script çalıştığında:
1. Dataset yolunu soracak (Enter'a basarsanız `fer2013.csv` kullanır)
2. Veriyi yükleyip işleyecek
3. Modeli eğitecek (birkaç saat sürebilir)
4. TFLite formatına dönüştürecek

### Adım 4: Modeli Kullanın

Eğitim tamamlandıktan sonra:

```bash
# Quantized modeli kullanın (daha küçük ve hızlı)
# assets/models/emotion_model_quant.tflite dosyası oluşturulacak

# Flutter uygulamasını çalıştırın
flutter clean
flutter pub get
flutter run
```

## 📊 Model Mimarisi

Eğitilen model Mini XCEPTION benzeri bir mimari kullanır:

- **Input:** 48x48 grayscale image
- **Output:** 7 emotion class probability scores
- **Layers:**
  - 3 Conv2D blokları (32, 64, 128 filters)
  - BatchNormalization
  - MaxPooling
  - Dropout
  - 2 Dense layers (512, 256 units)
  - Output layer (7 units, softmax)

## ⚙️ Eğitim Parametreleri

- **Epochs:** 100 (early stopping ile)
- **Batch Size:** 64
- **Optimizer:** Adam (learning_rate=0.001)
- **Loss:** Categorical Crossentropy
- **Callbacks:**
  - Model Checkpoint (en iyi modeli kaydet)
  - Early Stopping (patience=15)
  - Learning Rate Reduction (patience=5)

## 📈 Beklenen Performans

- **Test Accuracy:** ~60-70% (FER2013 test seti)
- **Model Boyutu:** 
  - Standart: ~2-3 MB
  - Quantized: ~1-1.5 MB

## 🎯 Emotion Sıralaması

Model FER2013 standart sıralamasını kullanır:
```
0: Angry
1: Disgust
2: Fear
3: Happy
4: Sad
5: Surprise
6: Neutral
```

Bu sıralama `emotion_detection_service.dart` dosyasında da kullanılmalıdır.

## ⚠️ Önemli Notlar

1. **Eğitim Süresi:** CPU'da birkaç saat, GPU'da 30-60 dakika sürebilir
2. **RAM Kullanımı:** Dataset yüklenirken ~4-6 GB RAM kullanılır
3. **Disk Alanı:** Model dosyaları ~5-10 MB yer kaplar
4. **Early Stopping:** Model 15 epoch boyunca iyileşmezse durur

## 🔧 Sorun Giderme

### Dataset bulunamadı hatası:
```bash
# Dataset dosyasının doğru yerde olduğundan emin olun
ls -lh fer2013.csv
```

### Memory hatası:
- Batch size'ı küçültün (64 → 32 veya 16)
- Dataset'in bir kısmını kullanın

### GPU kullanımı:
```python
# TensorFlow GPU kullanımını kontrol edin
import tensorflow as tf
print(tf.config.list_physical_devices('GPU'))
```

### Eğitim çok yavaş:
- GPU kullanın
- Batch size'ı artırın
- Daha basit bir model mimarisi kullanın

## 📚 Ek Kaynaklar

- **FER2013 Dataset:** https://www.kaggle.com/datasets/msambare/fer2013
- **TensorFlow Docs:** https://www.tensorflow.org/
- **Keras Docs:** https://keras.io/

## 💡 İpuçları

1. **İlk Eğitim:** Küçük bir epoch sayısıyla test edin (örn: 5 epoch)
2. **Model Checkpoint:** En iyi model otomatik kaydedilir
3. **Quantized Model:** Mobil için quantized model kullanın (daha küçük ve hızlı)
4. **Validation:** Validation accuracy'yi takip edin

## 🎉 Başarılı Eğitim Sonrası

Eğitim tamamlandıktan sonra:
1. `assets/models/emotion_model_quant.tflite` dosyasını kontrol edin
2. Flutter uygulamanızda modeli test edin
3. Emotion sıralamasının doğru olduğundan emin olun
4. Farklı emotion'lar için test yapın

---

**Not:** Eğitim sırasında model checkpoint'leri kaydedilir. Eğitim kesilirse, en iyi model `best_emotion_model.h5` dosyasından yüklenebilir.


