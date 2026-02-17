#!/bin/bash

# TFLite Emotion Detection Model İndirme Scripti
# Bu script model dosyasını indirip doğru yere kopyalar

echo "🎭 TFLite Emotion Detection Model İndirme"
echo "=========================================="
echo ""

# Klasörü oluştur
mkdir -p assets/models
cd assets/models

echo "📁 Klasör hazır: assets/models/"
echo ""

# Model dosyasını indir
echo "📥 Model dosyası indiriliyor..."
echo ""

# Seçenek 1: GitHub'dan örnek model (eğer varsa)
# wget veya curl ile indirebilirsiniz

echo "⚠️  Manuel İndirme Gerekli"
echo ""
echo "Lütfen aşağıdaki adımları takip edin:"
echo ""
echo "1. Tarayıcınızda şu linklere gidin:"
echo "   - https://github.com/search?q=fer2013+tflite"
echo "   - https://www.kaggle.com/datasets?search=fer2013"
echo "   - https://tfhub.dev/"
echo ""
echo "2. '.tflite' uzantılı emotion detection modeli indirin"
echo ""
echo "3. İndirdiğiniz dosyayı şu komutla kopyalayın:"
echo "   cp ~/Downloads/emotion_model.tflite assets/models/emotion_model.tflite"
echo ""
echo "4. Dosyanın doğru yerde olduğunu kontrol edin:"
echo "   ls -lh assets/models/emotion_model.tflite"
echo ""

# Alternatif: Eğer bir URL varsa direkt indirebiliriz
# Örnek (gerçek URL'yi değiştirin):
# if [ -z "$MODEL_URL" ]; then
#     echo "Model URL'i belirtilmedi"
# else
#     echo "Model indiriliyor: $MODEL_URL"
#     curl -L -o emotion_model.tflite "$MODEL_URL"
#     echo "✅ Model indirildi!"
# fi

echo "✅ Script tamamlandı!"
echo ""
echo "Model dosyasını ekledikten sonra:"
echo "  cd /Users/omerkorukmez/Desktop/mobil/mobil_aplication"
echo "  flutter pub get"
echo "  flutter run"

