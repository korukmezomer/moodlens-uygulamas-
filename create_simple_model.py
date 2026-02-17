#!/usr/bin/env python3
"""
Basit TFLite Emotion Detection Model Oluşturucu
Bu script test amaçlı basit bir model oluşturur.
Gerçek detection için eğitilmiş model kullanmanız önerilir.
"""

import tensorflow as tf
import numpy as np

print("🎭 Basit TFLite Emotion Detection Model Oluşturuluyor...")
print("⚠️  Bu model sadece test amaçlıdır, gerçek detection yapmaz!")
print("")

# Basit bir model oluştur
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(48, 48, 1)),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(128, activation='relu'),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dense(7, activation='softmax')  # 7 emotion class
])

# Modeli compile et
model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

print("✅ Model oluşturuldu")
print(f"   Input shape: {model.input_shape}")
print(f"   Output shape: {model.output_shape}")
print("")

# Rastgele ağırlıklarla başlat (sadece test için)
# Gerçek kullanım için eğitilmiş ağırlıklar gerekli
print("📝 Model ağırlıkları başlatılıyor...")

# TFLite'ye çevir
print("🔄 TFLite formatına dönüştürülüyor...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Quantization ile optimize et (opsiyonel)
# converter.optimizations = [tf.lite.Optimize.DEFAULT]

tflite_model = converter.convert()

# Kaydet
output_path = 'assets/models/emotion_model.tflite'
with open(output_path, 'wb') as f:
    f.write(tflite_model)

file_size = len(tflite_model) / 1024  # KB
print(f"✅ Model kaydedildi: {output_path}")
print(f"   Dosya boyutu: {file_size:.2f} KB")
print("")
print("⚠️  UYARI: Bu model rastgele ağırlıklara sahiptir!")
print("   Gerçek emotion detection için eğitilmiş model kullanın.")
print("")
print("📚 Eğitilmiş model için:")
print("   1. FER2013 dataset ile model eğitin")
print("   2. Veya hazır eğitilmiş model indirin")
print("   3. MODEL_SETUP_GUIDE.md dosyasına bakın")

