# TFLite Model Dosyası

Bu klasöre emotion detection için TFLite model dosyasını ekleyin.

## Model Gereksinimleri

- **Dosya adı**: `emotion_model.tflite`
- **Input format**: Grayscale image (48x48 veya 64x64)
- **Output format**: 7 emotion class için probability scores
  - angry
  - disgusted
  - fearful
  - happy
  - neutral
  - sad
  - surprised

## Model Nasıl Eklenir?

1. TFLite model dosyanızı hazırlayın veya indirin
2. Dosyayı `assets/models/emotion_model.tflite` olarak kaydedin
3. Uygulamayı yeniden build edin: `flutter pub get && flutter run`

## Model Önerileri

- FER2013 dataset'i ile eğitilmiş modeller
- MobileNet tabanlı lightweight modeller
- Quantized (int8) modeller daha hızlı çalışır

## Model Yoksa

Model dosyası yoksa, uygulama basit bir fallback detection kullanacaktır.
Gerçek emotion detection için model dosyası gereklidir.

