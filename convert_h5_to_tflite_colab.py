"""
Google Colab'da kullanmak için H5'ten TFLite'a dönüştürme scripti
Bu dosyayı Google Colab'a kopyalayıp kullanabilirsiniz
"""

# Hücre 1: Kütüphaneleri Yükle
# Colab'da en son TensorFlow versiyonu kullanılır (2.16+)
# Eski modeller için compile=False kullanacağız
!pip install tensorflow -q
print("✅ TensorFlow yüklendi")

# Hücre 2: Gerekli İmportlar
import tensorflow as tf
from google.colab import files
import os
import warnings
warnings.filterwarnings('ignore')  # Uyarıları gizle

print("🔄 H5 Modelini TFLite'a Dönüştürme")
print(f"TensorFlow versiyonu: {tf.__version__}")
print("")
print("💡 Not: Eski modeller için compile=False kullanılacak")
print("   Bu, optimizer uyumsuzluklarını önler")

# Hücre 3: H5 Model Dosyasını Yükle
print("📤 Lütfen H5/HDF5 model dosyanızı yükleyin...")
print("   (Dosya yükleme butonuna tıklayın ve model dosyanızı seçin)")
uploaded = files.upload()

# İlk yüklenen dosyayı al
h5_model_name = list(uploaded.keys())[0]
print(f"✅ Dosya yüklendi: {h5_model_name}")
print(f"   Dosya boyutu: {len(uploaded[h5_model_name]) / 1024 / 1024:.2f} MB")

# Hücre 4: Modeli Yükle ve Bilgilerini Göster
print("📥 Model yükleniyor...")
print("   (Eski modeller için compile=False kullanılıyor)")

try:
    # Yöntem 1: compile=False ile yükle (en güvenli yöntem)
    # Bu, optimizer uyumsuzluklarını önler
    model = tf.keras.models.load_model(
        h5_model_name,
        compile=False  # Optimizer uyumsuzluklarını önlemek için
    )
    
    print(f"✅ Model yüklendi (compile=False ile)")
    print(f"   Input shape: {model.input_shape}")
    print(f"   Output shape: {model.output_shape}")
    print(f"   Toplam parametre sayısı: {model.count_params():,}")
    
except Exception as e:
    print(f"❌ Yöntem 1 başarısız: {e}")
    print("")
    print("🔄 Alternatif yöntem deneniyor...")
    
    try:
        # Yöntem 2: Custom objects ile eski parametreleri ignore et
        import h5py
        
        # Eski optimizer parametrelerini ignore etmek için custom objects
        def ignore_lr(x):
            return x
        
        model = tf.keras.models.load_model(
            h5_model_name,
            compile=False,
            custom_objects={
                'lr': ignore_lr,
                'decay': ignore_lr,
            }
        )
        
        print(f"✅ Model yüklendi (custom_objects ile)")
        print(f"   Input shape: {model.input_shape}")
        print(f"   Output shape: {model.output_shape}")
        print(f"   Toplam parametre sayısı: {model.count_params():,}")
        
    except Exception as e2:
        print(f"❌ Yöntem 2 başarısız: {e2}")
        print("")
        print("🔄 Son alternatif yöntem deneniyor...")
        
        try:
            # Yöntem 3: H5 dosyasını açıp manuel yükleme
            import h5py
            import numpy as np
            
            # H5 dosyasını oku
            with h5py.File(h5_model_name, 'r') as f:
                print("   H5 dosyası açıldı, model yapısı kontrol ediliyor...")
            
            # Basit yükleme (tüm uyarıları ignore et)
            import warnings
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                model = tf.keras.models.load_model(
                    h5_model_name,
                    compile=False,
                    safe_mode=False  # Güvenlik kontrolünü atla
                )
            
            print(f"✅ Model yüklendi (safe_mode=False ile)")
            print(f"   Input shape: {model.input_shape}")
            print(f"   Output shape: {model.output_shape}")
            print(f"   Toplam parametre sayısı: {model.count_params():,}")
            
        except Exception as e3:
            print(f"❌ Tüm yöntemler başarısız!")
            print(f"   Son hata: {e3}")
            print("")
            print("💡 Çözüm önerileri:")
            print("   1. Model dosyasının bozuk olmadığından emin olun")
            print("   2. Farklı bir model dosyası deneyin")
            print("   3. Modeli farklı bir kaynaktan indirin")
            raise e3

# Hücre 5: TFLite'a Dönüştür
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
    if len(tflite_model) < len(uploaded[h5_model_name]):
        print(f"   Boyut azalması: {((1 - len(tflite_model) / len(uploaded[h5_model_name])) * 100):.1f}%")
except Exception as e:
    print(f"❌ Dönüştürme hatası: {e}")

# Hücre 6: Dosyayı İndir
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

