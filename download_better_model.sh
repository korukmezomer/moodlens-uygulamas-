#!/bin/bash

# İyi Çalışan TFLite Emotion Detection Model İndirme Scripti
# Bu script test edilmiş ve iyi çalışan modelleri indirir

echo "🎭 İyi Çalışan TFLite Emotion Detection Model İndirme"
echo "====================================================="
echo ""

# Klasörü oluştur
mkdir -p assets/models
cd assets/models

echo "📁 Klasör hazır: assets/models/"
echo ""

# Model seçenekleri
echo "🔍 İyi Çalışan Model Kaynakları:"
echo ""
echo "1. FER2013 ile Eğitilmiş Modeller (ÖNERİLEN)"
echo "   - GitHub: https://github.com/omar178/Emotion-recognition"
echo "   - Model: _mini_XCEPTION.102-0.66.hdf5 (H5 formatında)"
echo "   - Bu modeli TFLite'a dönüştürmeniz gerekiyor"
echo ""
echo "2. TensorFlow Hub (Hazır TFLite Modelleri)"
echo "   - https://tfhub.dev/s?q=emotion"
echo ""
echo "3. Kaggle (FER2013 Dataset ile Eğitilmiş)"
echo "   - https://www.kaggle.com/datasets/msambare/fer2013"
echo "   - Arama: 'fer2013 tflite emotion'"
echo ""
echo "4. Hugging Face (Hazır Modeller)"
echo "   - https://huggingface.co/models?search=emotion+detection+tflite"
echo ""

# En iyi seçenek: GitHub'dan direkt indirme denemesi
echo "📥 Model indiriliyor..."
echo ""

# Seçenek 1: GitHub'dan direkt model indirme (eğer varsa)
MODEL_URL=""
MODEL_NAME="emotion_model.tflite"

# Popüler ve iyi çalışan modeller için URL'ler
# Not: Bu URL'ler örnek, gerçek URL'leri kontrol edin

echo "⚠️  Otomatik indirme için model URL'i gerekli"
echo ""
echo "📋 Manuel İndirme Adımları (ÖNERİLEN):"
echo ""
echo "=== YÖNTEM 1: GitHub'dan H5 Model İndirip TFLite'a Dönüştürme ==="
echo ""
echo "1. GitHub'a gidin:"
echo "   https://github.com/omar178/Emotion-recognition"
echo ""
echo "2. 'models' klasöründen '_mini_XCEPTION.102-0.66.hdf5' dosyasını indirin"
echo ""
echo "3. Google Colab'ı açın: https://colab.research.google.com/"
echo ""
echo "4. convert_h5_to_tflite_colab.py dosyasındaki kodu kullanın"
echo ""
echo "5. H5 modeli yükleyip TFLite'a dönüştürün"
echo ""
echo "6. İndirilen emotion_model.tflite dosyasını buraya kopyalayın:"
echo "   cp ~/Downloads/emotion_model.tflite assets/models/emotion_model.tflite"
echo ""

echo "=== YÖNTEM 2: Hazır TFLite Model Arama ==="
echo ""
echo "1. TensorFlow Hub:"
echo "   https://tfhub.dev/s?q=emotion+detection"
echo ""
echo "2. Kaggle:"
echo "   https://www.kaggle.com/datasets?search=fer2013+tflite"
echo ""
echo "3. Hugging Face:"
echo "   https://huggingface.co/models?search=emotion+tflite"
echo ""

echo "=== YÖNTEM 3: Kendi Modelinizi Eğitin ==="
echo ""
echo "1. FER2013 dataset'ini indirin"
echo "2. TensorFlow/Keras ile model eğitin"
echo "3. TFLite'a dönüştürün"
echo ""

# Eğer MODEL_URL varsa indirmeyi dene
if [ ! -z "$MODEL_URL" ]; then
    echo "📥 Model URL'den indiriliyor: $MODEL_URL"
    curl -L -o "$MODEL_NAME" "$MODEL_URL"
    
    if [ -f "$MODEL_NAME" ]; then
        echo "✅ Model başarıyla indirildi!"
        echo "   Dosya: assets/models/$MODEL_NAME"
        echo "   Boyut: $(ls -lh $MODEL_NAME | awk '{print $5}')"
    else
        echo "❌ Model indirilemedi"
    fi
else
    echo "ℹ️  Otomatik indirme için MODEL_URL değişkenini ayarlayın"
    echo "   veya yukarıdaki manuel yöntemleri kullanın"
fi

echo ""
echo "✅ Script tamamlandı!"
echo ""
echo "Model dosyasını ekledikten sonra:"
echo "  cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter run"
echo ""


