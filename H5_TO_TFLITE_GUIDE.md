# H5 Modelini TFLite'a Dönüştürme Rehberi

## 🎯 Problem

Hugging Face, GitHub ve diğer kaynaklarda genellikle `.h5` veya `.hdf5` uzantılı modeller bulunur, `.tflite` uzantılı hazır modeller nadirdir. Bu durumda H5 modelini TFLite'a dönüştürmeniz gerekir.

---

## ✅ Çözüm 1: Google Colab ile Dönüştürme (ÖNERİLEN - En Kolay)

Google Colab kullanarak hiçbir şey yüklemeden modelinizi dönüştürebilirsiniz.

### Adım 1: Google Colab'ı Açın

1. Tarayıcınızda şu adresi açın: **https://colab.research.google.com/**
2. **"New notebook"** butonuna tıklayın

### Adım 2: Kodu Kopyalayın ve Çalıştırın

Aşağıdaki kodu hücrelere kopyalayın ve sırayla çalıştırın:

#### Hücre 1: Kütüphaneleri Yükle
```python
!pip install tensorflow -q
print("✅ TensorFlow yüklendi")
```

#### Hücre 2: Gerekli İmportlar
```python
import tensorflow as tf
from google.colab import files
import os

print("🔄 H5 Modelini TFLite'a Dönüştürme")
print(f"TensorFlow versiyonu: {tf.__version__}")
```

#### Hücre 3: H5 Model Dosyasını Yükle
```python
# H5 model dosyasını yükle (örnek: ~/Downloads/Emotion-recognition-master/models/_mini_XCEPTION.102-0.66.hdf5)
print("📤 Lütfen H5/HDF5 model dosyanızı yükleyin...")
print("   (Dosya yükleme butonuna tıklayın ve model dosyanızı seçin)")
uploaded = files.upload()

# İlk yüklenen dosyayı al
h5_model_name = list(uploaded.keys())[0]
print(f"✅ Dosya yüklendi: {h5_model_name}")
print(f"   Dosya boyutu: {len(uploaded[h5_model_name]) / 1024 / 1024:.2f} MB")
```

#### Hücre 4: Modeli Yükle ve Bilgilerini Göster
```python
# Modeli yükle
print("📥 Model yükleniyor...")
try:
    model = tf.keras.models.load_model(h5_model_name)
    print(f"✅ Model yüklendi")
    print(f"   Input shape: {model.input_shape}")
    print(f"   Output shape: {model.output_shape}")
    print(f"   Toplam parametre sayısı: {model.count_params():,}")
except Exception as e:
    print(f"❌ Model yükleme hatası: {e}")
    print("   Model dosyası bozuk olabilir veya farklı bir format kullanıyor olabilir")
```

#### Hücre 5: TFLite'a Dönüştür
```python
# TFLite'a dönüştür
print("🔄 TFLite formatına dönüştürülüyor...")
try:
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Opsiyonel: Quantization ile optimize et (model boyutunu küçültür)
    # Bu satırı aktif ederseniz model daha küçük olur ama biraz daha az doğru olabilir
    # converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    tflite_model = converter.convert()
    
    # Kaydet
    output_name = 'emotion_model.tflite'
    with open(output_name, 'wb') as f:
        f.write(tflite_model)
    
    file_size = len(tflite_model) / 1024  # KB
    print(f"✅ Model kaydedildi: {output_name}")
    print(f"   Dosya boyutu: {file_size:.2f} KB ({file_size / 1024:.2f} MB)")
    print(f"   Orijinal model: {len(uploaded[h5_model_name]) / 1024 / 1024:.2f} MB")
    print(f"   Boyut azalması: {((1 - len(tflite_model) / len(uploaded[h5_model_name])) * 100):.1f}%")
except Exception as e:
    print(f"❌ Dönüştürme hatası: {e}")
```

#### Hücre 6: Dosyayı İndir
```python
# Dosyayı indir
print("📥 Model dosyası indiriliyor...")
files.download(output_name)
print("✅ İndirme tamamlandı!")
print("")
print("📝 Sonraki adımlar:")
print("   1. İndirilen emotion_model.tflite dosyasını bulun")
print("   2. Dosyayı projeye kopyalayın:")
print("      cp ~/Downloads/emotion_model.tflite assets/models/emotion_model.tflite")
print("   3. Flutter uygulamasını çalıştırın:")
print("      flutter clean && flutter pub get && flutter run")
```

### Adım 3: Model Dosyasını Projeye Ekleyin

İndirilen dosyayı projeye kopyalayın:

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

---

## ✅ Çözüm 2: Yerel Python ile Dönüştürme (Python 3.8-3.12)

Eğer Python 3.8-3.12 yüklüyse, yerel olarak da dönüştürebilirsiniz.

### Adım 1: Virtual Environment Oluşturun

```bash
cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication
python3 -m venv venv_convert
source venv_convert/bin/activate
```

### Adım 2: TensorFlow Yükleyin

```bash
pip install tensorflow
```

### Adım 3: Dönüştürme Scriptini Çalıştırın

Aşağıdaki Python scriptini oluşturun:

```python
# convert_h5_to_tflite.py
import tensorflow as tf
import os
import sys

# Model dosyası yolu
h5_model_path = os.path.expanduser("~/Downloads/Emotion-recognition-master/models/_mini_XCEPTION.102-0.66.hdf5")
output_path = "assets/models/emotion_model.tflite"

if not os.path.exists(h5_model_path):
    print(f"❌ Model dosyası bulunamadı: {h5_model_path}")
    sys.exit(1)

print("📥 Model yükleniyor...")
model = tf.keras.models.load_model(h5_model_path)

print("🔄 TFLite'a dönüştürülüyor...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, 'wb') as f:
    f.write(tflite_model)

print(f"✅ Model kaydedildi: {output_path}")
```

Scripti çalıştırın:

```bash
python3 convert_h5_to_tflite.py
```

**Not:** Python 3.13+ TensorFlow ile uyumlu değildir. Bu durumda Google Colab kullanın.

---

## ✅ Çözüm 3: Online Dönüştürme Araçları

Bazı online araçlar H5'i TFLite'a dönüştürebilir, ancak güvenlik nedeniyle önerilmez (model dosyanızı yüklemeniz gerekir).

---

## 📝 Hangi H5 Modelini Kullanmalıyım?

İndirdiğiniz `Emotion-recognition-master` klasöründeki model:

```
~/Downloads/Emotion-recognition-master/models/_mini_XCEPTION.102-0.66.hdf5
```

Bu model FER2013 dataset'i ile eğitilmiş ve 7 emotion class'ı destekliyor:
- angry, disgusted, fearful, happy, neutral, sad, surprised

Bu modeli kullanabilirsiniz!

---

## 🔧 Sorun Giderme

### Model yüklenmiyor
- Model dosyasının bozuk olmadığından emin olun
- TensorFlow versiyonunu kontrol edin: `tf.__version__`
- Model dosyasının tam yolunu kontrol edin

### Dönüştürme hatası
- Model custom layer'lar içeriyorsa, bunları TFLite'a dönüştürmek zor olabilir
- Bu durumda alternatif bir model deneyin

### Model çok büyük
- Quantization kullanın: `converter.optimizations = [tf.lite.Optimize.DEFAULT]`
- Bu model boyutunu küçültür ama biraz daha az doğru olabilir

---

## ✅ Önerilen Yöntem

**Google Colab kullanın** çünkü:
- ✅ Hiçbir şey yüklemenize gerek yok
- ✅ Python versiyonu sorunu yok
- ✅ Ücretsiz ve hızlı
- ✅ Her yerden erişilebilir

---

## 🚀 Hızlı Başlangıç

1. **Google Colab'ı açın:** https://colab.research.google.com/
2. **Yukarıdaki kodu kopyalayın**
3. **H5 modelinizi yükleyin**
4. **TFLite dosyasını indirin**
5. **Projeye ekleyin ve çalıştırın**

Bu kadar! 🎉






















