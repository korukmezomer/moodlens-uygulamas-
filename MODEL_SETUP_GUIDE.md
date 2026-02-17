# TFLite Emotion Detection Model Kurulum Rehberi

## ⚠️ ÖNEMLİ NOT: H5 Modeli Buldunuz Ama TFLite Yok mu?

**Çoğu kaynakta (GitHub, Hugging Face, Kaggle) sadece `.h5` veya `.hdf5` uzantılı modeller bulunur, `.tflite` uzantılı hazır modeller nadirdir.**

**Çözüm:** H5 modelini TFLite'a dönüştürmeniz gerekir. En kolay yöntem için **"Seçenek 1: Google Colab ile H5'ten TFLite'a Dönüştürme"** bölümüne bakın.

---

## Seçenek 1: Google Colab ile H5'ten TFLite'a Dönüştürme (ÖNERİLEN - En Kolay)

Bu yöntemle hiçbir şey yüklemeden modelinizi dönüştürebilirsiniz.

### Adım 1: Google Colab'ı Açın

1. Tarayıcınızda şu adresi açın: **https://colab.research.google.com/**
2. **"New notebook"** butonuna tıklayın

### Adım 2: Kodu Çalıştırın

`convert_h5_to_tflite_colab.py` dosyasındaki kodu hücrelere kopyalayın veya `H5_TO_TFLITE_GUIDE.md` dosyasındaki detaylı talimatları takip edin.

**Kısa özet:**
1. TensorFlow'u yükleyin: `!pip install tensorflow -q`
2. H5 model dosyanızı yükleyin (örnek: `_mini_XCEPTION.102-0.66.hdf5`)
3. Modeli TFLite'a dönüştürün
4. İndirilen `emotion_model.tflite` dosyasını projeye ekleyin

### Adım 3: Model Dosyasını Projeye Ekleyin

```bash
cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication
cp ~/Downloads/emotion_model.tflite assets/models/emotion_model.tflite
```

### Adım 4: Flutter Uygulamasını Çalıştırın

```bash
flutter clean
flutter pub get
flutter run
```

**Detaylı rehber için:** `H5_TO_TFLITE_GUIDE.md` dosyasına bakın.

---

## Seçenek 2: Hazır TFLite Modeli Arama (Nadiren Bulunur)

### Adım 1: Model Dosyasını İndirin

Aşağıdaki kaynaklardan birinden hazır model arayabilirsiniz (genellikle sadece H5 bulunur):

#### Seçenek A: GitHub'dan Hazır Model
1. Tarayıcınızda şu linke gidin:
   - https://github.com/omar178/Emotion-recognition
   - veya https://github.com/atulapra/Emotion-detection
   - veya https://github.com/search?q=fer2013+tflite+emotion

2. **Not:** Genellikle sadece `.h5` veya `.hdf5` dosyası bulunur. Bu durumda yukarıdaki "Seçenek 1" bölümünü kullanın.

#### Seçenek B: TensorFlow Hub'dan
1. https://tfhub.dev/ adresine gidin
2. "emotion detection" veya "FER2013" arayın
3. TFLite formatında model indirin

#### Seçenek C: Kaggle'dan
1. https://www.kaggle.com/datasets adresine gidin
2. "FER2013 emotion detection tflite" arayın
3. Model dosyasını indirin

### Adım 2: Model Dosyasını Projeye Ekleyin

1. İndirdiğiniz `.tflite` dosyasını bulun
2. Dosyayı şu klasöre kopyalayın:
   ```
   mobil_aplication/assets/models/emotion_model.tflite
   ```

3. Eğer klasör yoksa oluşturun:
   ```bash
   cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication
   mkdir -p assets/models
   ```

4. Dosyayı kopyalayın:
   ```bash
   # Örnek (dosyanızın yerine göre değiştirin):
   cp ~/Downloads/emotion_model.tflite assets/models/emotion_model.tflite
   ```

### Adım 3: Uygulamayı Yeniden Build Edin

```bash
cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication
flutter pub get
flutter clean
flutter run
```

---

## Seçenek 2: Kendi Modelinizi Eğitme (Gelişmiş)

### Gereksinimler
- Python 3.8+
- TensorFlow 2.x
- FER2013 dataset

### Adım 1: Python Ortamını Hazırlayın

```bash
# Virtual environment oluşturun
python3 -m venv emotion_env
source emotion_env/bin/activate  # Mac/Linux
# veya
emotion_env\Scripts\activate  # Windows

# Gerekli paketleri yükleyin
pip install tensorflow numpy pandas matplotlib
```

### Adım 2: FER2013 Dataset'ini İndirin

```bash
# Kaggle'dan dataset indirin
# https://www.kaggle.com/datasets/msambare/fer2013
```

### Adım 3: Model Eğitimi

Aşağıdaki Python script'ini kullanarak model eğitebilirsiniz:

```python
import tensorflow as tf
import numpy as np
from tensorflow import keras
from tensorflow.keras import layers

# Model oluştur
model = keras.Sequential([
    layers.Conv2D(32, (3, 3), activation='relu', input_shape=(48, 48, 1)),
    layers.MaxPooling2D(2, 2),
    layers.Conv2D(64, (3, 3), activation='relu'),
    layers.MaxPooling2D(2, 2),
    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D(2, 2),
    layers.Flatten(),
    layers.Dense(512, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(7, activation='softmax')  # 7 emotion class
])

model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# Dataset yükle ve eğit (FER2013)
# ... dataset loading code ...

# Modeli eğit
model.fit(train_images, train_labels, epochs=50, validation_split=0.2)

# TFLite'ye çevir
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Kaydet
with open('emotion_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

### Adım 4: Modeli Optimize Edin (Opsiyonel)

```python
# Quantization ile model boyutunu küçültün
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_quant_model = converter.convert()

with open('emotion_model_quant.tflite', 'wb') as f:
    f.write(tflite_quant_model)
```

---

## Seçenek 3: Hızlı Test İçin Basit Model (Geçici)

Model dosyası olmadan test etmek için, basit bir placeholder model oluşturabilirsiniz:

```python
import tensorflow as tf
import numpy as np

# Basit bir placeholder model oluştur
model = tf.keras.Sequential([
    tf.keras.layers.Flatten(input_shape=(48, 48, 1)),
    tf.keras.layers.Dense(7, activation='softmax')
])

# Rastgele ağırlıklarla başlat (sadece test için)
model.compile(optimizer='adam', loss='categorical_crossentropy')

# TFLite'ye çevir
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('emotion_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

**Not:** Bu model gerçek detection yapmaz, sadece uygulamanın çalıştığını test etmek içindir.

---

## Model Dosyasını Kontrol Etme

Model dosyasının doğru yerde olduğunu kontrol edin:

```bash
cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication
ls -lh assets/models/
```

Çıktı şöyle olmalı:
```
emotion_model.tflite
```

---

## Sorun Giderme

### Model yüklenmiyor
- Dosya adının tam olarak `emotion_model.tflite` olduğundan emin olun
- `pubspec.yaml`'da assets tanımlı olduğundan emin olun
- `flutter clean && flutter pub get` çalıştırın

### Model format hatası
- Model dosyasının `.tflite` uzantılı olduğundan emin olun
- Model input shape'inin (48, 48, 1) veya (64, 64, 1) olduğundan emin olun
- Model output'unun 7 class için olduğundan emin olun

### Model çok büyük
- Quantized (int8) model kullanın
- Model boyutu genellikle 1-5 MB arası olmalıdır

---

## Önerilen Model Kaynakları

1. **GitHub Repositories:**
   - https://github.com/omar178/Emotion-recognition
   - https://github.com/atulapra/Emotion-detection

2. **Kaggle:**
   - https://www.kaggle.com/datasets/msambare/fer2013
   - https://www.kaggle.com/models (TFLite modelleri)

3. **TensorFlow Hub:**
   - https://tfhub.dev/

4. **Hugging Face:**
   - https://huggingface.co/models (TFLite modelleri)

---

## Hızlı Başlangıç (En Kolay Yol)

### Yöntem 1: H5 Modelini TFLite'a Dönüştürme (ÖNERİLEN)

**Not:** Çoğu kaynakta sadece `.h5` dosyası bulunur, `.tflite` nadirdir.

1. **Google Colab'ı açın:** https://colab.research.google.com/
2. **`convert_h5_to_tflite_colab.py` dosyasındaki kodu kopyalayın**
3. **H5 modelinizi yükleyin** (örnek: `_mini_XCEPTION.102-0.66.hdf5`)
4. **TFLite dosyasını indirin**
5. **Dosyayı projeye ekleyin:**
   ```bash
   cp ~/Downloads/emotion_model.tflite assets/models/emotion_model.tflite
   ```
6. **Flutter uygulamasını çalıştırın:**
   ```bash
   flutter clean && flutter pub get && flutter run
   ```

**Detaylı rehber için:** `H5_TO_TFLITE_GUIDE.md` dosyasına bakın.

### Yöntem 2: Hazır TFLite Modeli Arama (Nadiren Bulunur)

1. GitHub'da "FER2013 tflite emotion" arayın
2. **Not:** Genellikle sadece `.h5` dosyası bulunur, bu durumda Yöntem 1'i kullanın
3. Eğer `.tflite` dosyası bulursanız, dosyayı `assets/models/emotion_model.tflite` olarak kaydedin
4. `flutter run` yapın

Bu kadar! 🚀

