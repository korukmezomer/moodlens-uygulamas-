#!/usr/bin/env python3
"""
FER2013 Dataset ile Emotion Detection Model Eğitimi
Bu script FER2013 dataset'i ile emotion detection modeli eğitir ve TFLite'a dönüştürür.
"""

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, models, callbacks
import numpy as np
import pandas as pd
import os
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt

print("🎭 FER2013 Emotion Detection Model Eğitimi Başlatılıyor...")
print("=" * 60)
print("")

# Dataset yolu - kullanıcının dataset'ini buraya koyması gerekiyor
DATASET_PATH = input("FER2013 dataset dosyasının yolunu girin (fer2013.csv): ").strip()
if not DATASET_PATH:
    DATASET_PATH = "fer2013.csv"

if not os.path.exists(DATASET_PATH):
    print(f"❌ Hata: {DATASET_PATH} dosyası bulunamadı!")
    print("")
    print("FER2013 dataset'ini şuradan indirebilirsiniz:")
    print("https://www.kaggle.com/datasets/msambare/fer2013")
    print("")
    print("Dataset'i indirdikten sonra 'fer2013.csv' olarak kaydedin.")
    exit(1)

print(f"✅ Dataset bulundu: {DATASET_PATH}")
print("")

# Dataset'i yükle
print("📊 Dataset yükleniyor...")
df = pd.read_csv(DATASET_PATH)

print(f"   Toplam örnek sayısı: {len(df)}")
print(f"   Sütunlar: {df.columns.tolist()}")
print("")

# Emotion sınıfları (FER2013 standart sıralaması)
emotions = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']
print(f"   Emotion sınıfları: {emotions}")
print("")

# Veriyi işle
print("🔄 Veri işleniyor...")

# Pixel değerlerini parse et
def parse_pixels(pixel_str):
    return np.array([int(p) for p in pixel_str.split()])

# Train, validation, test split
train_df = df[df['Usage'] == 'Training']
val_df = df[df['Usage'] == 'PublicTest']
test_df = df[df['Usage'] == 'PrivateTest']

print(f"   Train: {len(train_df)} örnek")
print(f"   Validation: {len(val_df)} örnek")
print(f"   Test: {len(test_df)} örnek")
print("")

# Veriyi hazırla
print("📐 Veri hazırlanıyor...")

def prepare_data(df):
    pixels = np.array([parse_pixels(p) for p in df['pixels']])
    # 48x48 grayscale image'e reshape et
    images = pixels.reshape(-1, 48, 48, 1)
    # Normalize et (0-1 arası)
    images = images.astype('float32') / 255.0
    # Labels
    labels = keras.utils.to_categorical(df['emotion'].values, num_classes=7)
    return images, labels

X_train, y_train = prepare_data(train_df)
X_val, y_val = prepare_data(val_df)
X_test, y_test = prepare_data(test_df)

print(f"   Train shape: {X_train.shape}")
print(f"   Validation shape: {X_val.shape}")
print(f"   Test shape: {X_test.shape}")
print("")

# Model oluştur
print("🏗️  Model oluşturuluyor...")

# Mini XCEPTION benzeri model (hafif ve etkili)
def create_model():
    model = models.Sequential([
        # İlk blok
        layers.Conv2D(32, (3, 3), activation='relu', input_shape=(48, 48, 1)),
        layers.BatchNormalization(),
        layers.Conv2D(32, (3, 3), activation='relu'),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.25),
        
        # İkinci blok
        layers.Conv2D(64, (3, 3), activation='relu'),
        layers.BatchNormalization(),
        layers.Conv2D(64, (3, 3), activation='relu'),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.25),
        
        # Üçüncü blok
        layers.Conv2D(128, (3, 3), activation='relu'),
        layers.BatchNormalization(),
        layers.Conv2D(128, (3, 3), activation='relu'),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.25),
        
        # Dense layers
        layers.Flatten(),
        layers.Dense(512, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.5),
        layers.Dense(256, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.5),
        layers.Dense(7, activation='softmax')  # 7 emotion class
    ])
    
    return model

model = create_model()

# Modeli compile et
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

print("✅ Model oluşturuldu")
print(f"   Toplam parametre sayısı: {model.count_params():,}")
print("")

# Model özeti
model.summary()
print("")

# Callbacks
print("📝 Callbacks ayarlanıyor...")

# Model checkpoint
checkpoint_path = "best_emotion_model.h5"
checkpoint = callbacks.ModelCheckpoint(
    checkpoint_path,
    monitor='val_accuracy',
    save_best_only=True,
    mode='max',
    verbose=1
)

# Early stopping
early_stopping = callbacks.EarlyStopping(
    monitor='val_accuracy',
    patience=15,
    restore_best_weights=True,
    verbose=1
)

# Learning rate reduction
lr_reduction = callbacks.ReduceLROnPlateau(
    monitor='val_loss',
    factor=0.5,
    patience=5,
    min_lr=0.00001,
    verbose=1
)

callbacks_list = [checkpoint, early_stopping, lr_reduction]

print("✅ Callbacks hazır")
print("")

# Model eğitimi
print("🚀 Model eğitimi başlatılıyor...")
print("   Bu işlem birkaç saat sürebilir...")
print("")

EPOCHS = 100
BATCH_SIZE = 64

history = model.fit(
    X_train, y_train,
    batch_size=BATCH_SIZE,
    epochs=EPOCHS,
    validation_data=(X_val, y_val),
    callbacks=callbacks_list,
    verbose=1
)

print("")
print("✅ Model eğitimi tamamlandı!")
print("")

# Test seti ile değerlendirme
print("📊 Test seti ile değerlendirme...")
test_loss, test_accuracy = model.evaluate(X_test, y_test, verbose=0)
print(f"   Test Accuracy: {test_accuracy * 100:.2f}%")
print(f"   Test Loss: {test_loss:.4f}")
print("")

# En iyi modeli yükle
print("📥 En iyi model yükleniyor...")
model.load_weights(checkpoint_path)
print("✅ En iyi model yüklendi")
print("")

# TFLite'a dönüştür
print("🔄 TFLite formatına dönüştürülüyor...")

# Standart TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Kaydet
output_path = 'assets/models/emotion_model.tflite'
os.makedirs('assets/models', exist_ok=True)

with open(output_path, 'wb') as f:
    f.write(tflite_model)

file_size = len(tflite_model) / (1024 * 1024)  # MB
print(f"✅ TFLite model kaydedildi: {output_path}")
print(f"   Dosya boyutu: {file_size:.2f} MB")
print("")

# Quantized model (daha küçük ve hızlı)
print("🔄 Quantized TFLite model oluşturuluyor...")
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_quant_model = converter.convert()

quant_output_path = 'assets/models/emotion_model_quant.tflite'
with open(quant_output_path, 'wb') as f:
    f.write(tflite_quant_model)

quant_file_size = len(tflite_quant_model) / (1024 * 1024)  # MB
print(f"✅ Quantized TFLite model kaydedildi: {quant_output_path}")
print(f"   Dosya boyutu: {quant_file_size:.2f} MB")
print("")

# Özet
print("=" * 60)
print("🎉 Model eğitimi başarıyla tamamlandı!")
print("")
print("📁 Oluşturulan dosyalar:")
print(f"   1. {checkpoint_path} - En iyi H5 model")
print(f"   2. {output_path} - TFLite model")
print(f"   3. {quant_output_path} - Quantized TFLite model (önerilen)")
print("")
print("📊 Model Performansı:")
print(f"   Test Accuracy: {test_accuracy * 100:.2f}%")
print("")
print("🚀 Sonraki Adımlar:")
print("   1. Quantized modeli kullanın (daha küçük ve hızlı)")
print("   2. Modeli Flutter uygulamanıza ekleyin")
print("   3. Emotion sıralamasını kontrol edin: {emotions}")
print("   4. flutter clean && flutter pub get && flutter run")
print("")
print("✅ Tamamlandı!")


