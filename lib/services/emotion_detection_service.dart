import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class EmotionDetectionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  
  // Emotion sınıfları - Kendi eğittiğiniz modelin sıralaması
  // Model eğitim scriptinizdeki sıralama:
  // emotions = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
  // 
  // Flutter'da backend ile uyumlu olması için isimleri düzeltiyoruz:
  // - 'disgust' -> 'disgusted'
  // - 'fear' -> 'fearful'  
  // - 'surprise' -> 'surprised'
  //
  // Sıralama: 0: angry, 1: disgust, 2: fear, 3: happy, 4: neutral, 5: sad, 6: surprise
  final List<String> _emotions = [
    'angry',      // Index 0
    'disgusted',  // Index 1 (model'de 'disgust')
    'fearful',    // Index 2 (model'de 'fear')
    'happy',      // Index 3
    'neutral',    // Index 4
    'sad',        // Index 5
    'surprised'   // Index 6 (model'de 'surprise')
  ];

  /// TFLite modelini yükle
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Model dosyasını assets'ten yükle
      // Not: Model dosyasını assets/models/ klasörüne eklemeniz gerekiyor
      // Örnek: assets/models/emotion_model.tflite
      
      // Önce model dosyasının var olup olmadığını kontrol et
      try {
        final modelPath = 'assets/models/emotion_model.tflite';
        await rootBundle.load(modelPath);
        
        // Modeli yükle
        _interpreter = await Interpreter.fromAsset(
          modelPath,
          options: InterpreterOptions()..threads = 4,
        );
        
        print('✅ TFLite model yüklendi');
        _isInitialized = true;
      } catch (e) {
        print('⚠️ Model dosyası bulunamadı: $e');
        print('⚠️ Lütfen emotion_model.tflite dosyasını assets/models/ klasörüne ekleyin');
        // Model yoksa servis çalışmaya devam eder ama basit detection kullanır
        _isInitialized = false;
      }
    } catch (e) {
      print('❌ TFLite model yükleme hatası: $e');
      _isInitialized = false;
    }
  }

  /// Yüz tespiti ve emotion detection yap
  Future<Map<String, dynamic>> detectEmotion(String imagePath) async {
    try {
      // 1. Yüz tespiti yap
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: false,
          enableLandmarks: true,
          enableTracking: false,
        ),
      );

      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print('⚠️ Yüz tespit edilemedi');
        return {
          'emotion': 'neutral',
          'confidence': 0.5,
          'error': 'No face detected'
        };
      }

      // İlk yüzü al
      final face = faces.first;
      print('✅ Yüz tespit edildi: ${face.boundingBox}');

      // 2. Yüzü kırp ve normalize et
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Image decode failed');
      }

      // Yüz bölgesini kırp (padding ekleyerek daha iyi sonuç için)
      final faceRect = face.boundingBox;
      final padding = 0.3; // %30 padding ekle (daha fazla context için)
      final paddingX = (faceRect.width * padding).toInt();
      final paddingY = (faceRect.height * padding).toInt();
      
      final cropX = ((faceRect.left - paddingX).clamp(0, image.width - 1)).toInt();
      final cropY = ((faceRect.top - paddingY).clamp(0, image.height - 1)).toInt();
      final cropWidth = ((faceRect.width + paddingX * 2).clamp(1, image.width - cropX)).toInt();
      final cropHeight = ((faceRect.height + paddingY * 2).clamp(1, image.height - cropY)).toInt();
      
      var croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );
      
      // Contrast ve brightness iyileştirmesi (daha iyi detection için)
      croppedImage = img.adjustColor(
        croppedImage,
        brightness: 1.1,  // %10 daha parlak
        contrast: 1.15,   // %15 daha kontrastlı
        saturation: 0.0,  // Grayscale için saturation yok
      );
      
      print('📸 Yüz kırpıldı: ${croppedImage.width}x${croppedImage.height}');

      // Model varsa TFLite ile detection yap
      if (_isInitialized && _interpreter != null) {
        return await _detectWithTFLite(croppedImage);
      } else {
        // Model yoksa basit rule-based detection
        return _detectWithRules(face);
      }
    } catch (e) {
      print('❌ Emotion detection hatası: $e');
      return {
        'emotion': 'neutral',
        'confidence': 0.5,
        'error': e.toString()
      };
    }
  }

  /// TFLite model ile emotion detection
  Future<Map<String, dynamic>> _detectWithTFLite(img.Image image) async {
    try {
      // Model input boyutunu al (genellikle 48x48 veya 64x64)
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];
      
      // Model output shape'ini kontrol et
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('📊 Model Input Shape: $inputShape');
      print('📊 Model Output Shape: $outputShape');

      // Resmi yeniden boyutlandır ve grayscale'e çevir
      final resized = img.copyResize(
        image,
        width: inputWidth,
        height: inputHeight,
      );
      
      // Grayscale'e çevir
      final grayscale = img.grayscale(resized);

      // Normalize et (0-1 arası)
      // Bazı modeller farklı normalizasyon bekleyebilir, burada 0-1 arası kullanıyoruz
      final inputList = <double>[];
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = grayscale.getPixel(x, y);
          // Grayscale için red kanalını kullan (grayscale'de tüm kanallar aynı)
          final value = pixel.r;
          // 0-1 arası normalize et (z-score normalization yerine min-max)
          final normalized = value / 255.0;
          inputList.add(normalized);
        }
      }
      
      print('📊 Input normalization: min=${inputList.reduce((a, b) => a < b ? a : b).toStringAsFixed(3)}, max=${inputList.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)}');
      
      // Reshape: [1, height, width, 1] formatına çevir
      final input = List.generate(
        1,
        (_) => List.generate(
          inputHeight,
          (h) => List.generate(
            inputWidth,
            (w) => [inputList[h * inputWidth + w]],
          ),
        ),
      );

      // Model çıktısı için buffer hazırla
      // Model output shape: [1, 7] (1 batch, 7 emotion classes)
      // Output shape'e göre dinamik olarak oluştur
      final outputBatchSize = outputShape[0];
      final outputClassCount = outputShape.length > 1 ? outputShape[1] : _emotions.length;
      
      final output = List.generate(
        outputBatchSize,
        (_) => List.filled(outputClassCount, 0.0),
      );

      // Inference yap
      _interpreter!.run(input, output);

      // En yüksek skorlu emotion'ı bul
      // output[0] = [1, 7] şeklindeki ilk batch, bu da 7 emotion score içerir
      final predictions = (output[0] as List).map((e) => e as double).toList();
      
      print('📊 Output predictions: $predictions');
      print('📊 Predictions count: ${predictions.length}, Emotions count: ${_emotions.length}');
      
      // Güvenlik kontrolü: predictions sayısı emotions sayısıyla eşleşmeli
      if (predictions.length != _emotions.length) {
        throw Exception('Model output count (${predictions.length}) does not match emotions count (${_emotions.length})');
      }
      
      // Tüm prediction skorlarını detaylı logla
      print('📊 Detaylı prediction skorları:');
      for (int i = 0; i < predictions.length; i++) {
        print('   Index $i (${_emotions[i]}): ${(predictions[i] * 100).toStringAsFixed(2)}%');
      }
      
      // En yüksek 3 skoru göster (debug için)
      final indexedPredictions = List.generate(
        predictions.length,
        (i) => {'index': i, 'emotion': _emotions[i], 'score': predictions[i]},
      );
      indexedPredictions.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      print('📊 En yüksek 3 skor:');
      for (int i = 0; i < 3 && i < indexedPredictions.length; i++) {
        final item = indexedPredictions[i];
        print('   ${i + 1}. Index ${item['index']} (${item['emotion']}): ${((item['score'] as double) * 100).toStringAsFixed(2)}%');
      }
      
      // En yüksek skorlu emotion'ı bul
      double maxScore = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxScore) {
          maxScore = predictions[i];
          maxIndex = i;
        }
      }

      // Her zaman en yüksek skorlu emotion'ı seç
      final detectedEmotion = _emotions[maxIndex];
      final confidence = maxScore;

      print('🎭 TFLite Detection: $detectedEmotion (${(confidence * 100).toStringAsFixed(1)}%) - Index: $maxIndex');
      
      // Düşük güven uyarısı (sadece bilgilendirme amaçlı, seçimi etkilemez)
      if (confidence < 0.40) {
        print('⚠️ UYARI: Düşük güven skoru tespit edildi (${(confidence * 100).toStringAsFixed(1)}%). Model yeniden eğitilmeli veya daha kaliteli model kullanılmalı.');
      }

      return {
        'emotion': detectedEmotion,
        'confidence': confidence,
        'isLowConfidence': confidence < 0.40, // Sadece bilgilendirme amaçlı
        'allPredictions': Map.fromIterables(
          _emotions,
          predictions.map((p) => p.toDouble()),
        ),
      };
    } catch (e) {
      print('❌ TFLite inference hatası: $e');
      return {
        'emotion': 'neutral',
        'confidence': 0.5,
        'error': e.toString()
      };
    }
  }

  /// Basit rule-based detection (model yoksa)
  Map<String, dynamic> _detectWithRules(Face face) {
    // Basit kurallar: Yüz özelliklerine göre tahmin
    // Bu sadece placeholder - gerçek detection için model gerekli
    
    // Şimdilik rastgele bir emotion döndür (test için)
    // Gerçek uygulamada model gerekli!
    
    print('⚠️ TFLite model yok, basit detection kullanılıyor');
    
    return {
      'emotion': 'neutral',
      'confidence': 0.6,
      'note': 'Model not loaded - using fallback'
    };
  }

  /// Servisi temizle
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}


