import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/emotion_detection_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'recommendation_map_screen.dart';
import 'user_home_screen.dart';
import '../../models/recommendation_model.dart';

class UserCameraScreen extends StatefulWidget {
  final VoidCallback? onPlacesTap;
  
  const UserCameraScreen({super.key, this.onPlacesTap});

  @override
  State<UserCameraScreen> createState() => _UserCameraScreenState();
}

class _UserCameraScreenState extends State<UserCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _isLoading = true;
  bool _isCapturing = false;
  XFile? _capturedImage;
  final EmotionDetectionService _emotionService = EmotionDetectionService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _emotionService.initialize();
  }

  @override
  void dispose() {
    _emotionService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Kamera iznini kontrol et
      var status = await Permission.camera.status;
      
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _isPermissionGranted = false;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isPermissionGranted = true;
        });
      }

      // Kameraları al
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        print('HATA: Hiç kamera bulunamadı!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      print('Bulunan kamera sayısı: ${_cameras!.length}');
      for (var cam in _cameras!) {
        print('Kamera: ${cam.name}, Lens: ${cam.lensDirection}');
      }

      // Ön kamerayı bul (selfie için)
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Ön kamera yoksa arka kamerayı kullan
      final camera = frontCamera ?? _cameras!.first;
      print('Seçilen kamera: ${camera.name}, Lens: ${camera.lensDirection}');

      // Eski controller'ı dispose et
      if (_controller != null) {
        await _controller!.dispose();
      }

      // Kamera controller'ı oluştur
      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // high yerine medium (daha hızlı)
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.jpeg 
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = _controller!.value.isInitialized;
          _isLoading = false;
        });
        
        if (!_controller!.value.isInitialized) {
          print('HATA: Kamera initialize edilemedi!');
        } else {
          print('Kamera başarıyla initialize edildi!');
        }
      }
    } catch (e, stackTrace) {
      print('Kamera başlatma hatası: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = false;
        });
        
        // Hata mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera başlatılamadı: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera hazır değil. Lütfen bekleyin...'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _controller!.takePicture();
      
      setState(() {
        _capturedImage = image;
        _isCapturing = false;
      });

      // Fotoğraf çekildi, şimdi işleme ekranına geçilebilir
      _showImagePreview(image);
    } catch (e) {
      print('Fotoğraf çekme hatası: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekilirken bir hata oluştu: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showImagePreview(XFile image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf Çekildi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              File(image.path),
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            const Text('Bu fotoğrafı kullanmak istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _capturedImage = null;
              });
            },
            child: const Text('Yeniden Çek'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Fotoğrafı işle ve duygu tespiti yap
              _processImage(image);
            },
            child: const Text('Kullan'),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(XFile image) async {
    try {
      // Kullanıcı giriş yapmış mı kontrol et
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen önce giriş yapın'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final apiService = ApiService();

      // Konum bilgisini al - Her zaman izin iste
      Position? position;
      try {
        print('📍 Konum izni kontrol ediliyor...');
        
        // Konum servisleri açık mı kontrol et
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('⚠️ Konum servisleri kapalı');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mekan önerileri için lütfen konum servislerini açın'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        
        // İzin kontrolü yap
        LocationPermission permission = await Geolocator.checkPermission();
        print('📍 Mevcut izin durumu: $permission');
        
        if (permission == LocationPermission.denied) {
          print('📍 Konum izni isteniyor...');
          // Kullanıcıya bilgi ver
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📍 Yakındaki mekanları görmek için konum izni verin'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
          permission = await Geolocator.requestPermission();
          print('📍 İzin sonucu: $permission');
        }
        
        if (permission == LocationPermission.deniedForever) {
          print('⚠️ Konum izni kalıcı olarak reddedildi');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Konum izni gerekli. Lütfen ayarlardan izin verin.'),
                action: SnackBarAction(
                  label: 'Ayarlar',
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
        
        if (permission == LocationPermission.whileInUse || 
            permission == LocationPermission.always) {
          print('📍 Konum alınıyor...');
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          print('✅ Konum alındı: ${position.latitude}, ${position.longitude}');
        } else {
          print('⚠️ Konum izni verilmedi');
        }
      } catch (e) {
        print('❌ Konum alınamadı: $e');
        // Konum olmadan devam et
      }

      // Fotoğrafı backend'e yükle
      print('Fotoğraf yükleniyor: ${image.path}');
      final photoResponse = await apiService.uploadPhoto(
        image.path,
        device: Platform.isAndroid ? 'Android' : 'iOS',
      );

      print('Photo Response: $photoResponse');
      print('Photo Response Type: ${photoResponse.runtimeType}');
      
      // Güvenli keys kontrolü
      if (photoResponse is Map) {
        print('Photo Response Keys: ${photoResponse.keys}');
      }

      // ID'yi güvenli bir şekilde al (int, num veya String olabilir)
      int? photoId;
      dynamic idValue;
      
      if (photoResponse is Map) {
        idValue = photoResponse['id'];
      } else {
        print('HATA: photoResponse bir Map değil!');
        throw Exception('Invalid photo response format');
      }
      print('ID Value: $idValue, Type: ${idValue?.runtimeType}');
      
      if (idValue == null) {
        print('UYARI: Photo ID null!');
      } else if (idValue is int) {
        photoId = idValue;
      } else if (idValue is num) {
        photoId = idValue.toInt();
      } else if (idValue is String) {
        photoId = int.tryParse(idValue);
      } else {
        print('HATA: Beklenmeyen ID tipi: ${idValue.runtimeType}');
      }
      
      print('Photo ID (final): $photoId');

      // TFLite model ile duygu tespiti yap
      print('🎭 Emotion detection başlatılıyor...');
      final emotionResult = await _emotionService.detectEmotion(image.path);
      
      final detectedEmotion = emotionResult['emotion'] as String? ?? 'neutral';
      final confidence = emotionResult['confidence'] as double? ?? 0.5;
      final allPredictions = emotionResult['allPredictions'] as Map<String, dynamic>?;
      
      print('🎭 Tespit edilen duygu: $detectedEmotion (${(confidence * 100).toStringAsFixed(1)}%)');

      // Emotion log oluştur
      final rawOutput = allPredictions != null
          ? jsonEncode(allPredictions)
          : '{"emotion": "$detectedEmotion", "confidence": $confidence}';

      // Emotion log oluştur (response'da recommendations dönecek)
      Map<String, dynamic> emotionLogResponse;
      if (position != null) {
        emotionLogResponse = await apiService.createEmotionLog(
          emotionKey: detectedEmotion,
          confidence: confidence,
          latitude: position.latitude,
          longitude: position.longitude,
          rawOutput: rawOutput,
          photoId: photoId,
        );
      } else {
        // Konum olmadan da emotion log oluştur (varsayılan koordinatlar)
        emotionLogResponse = await apiService.createEmotionLog(
          emotionKey: detectedEmotion,
          confidence: confidence,
          latitude: 0.0, // Varsayılan
          longitude: 0.0, // Varsayılan
          rawOutput: rawOutput,
          photoId: photoId,
        );
      }

      // Dialog'u kapat
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog
      }

      // Response'dan recommendations'ı kontrol et
      final recommendations = emotionLogResponse['recommendations'] as List?;
      final emotionLogId = emotionLogResponse['id'] as int?;
      
      print('🎭 Emotion log response: $emotionLogResponse');
      print('🎭 Recommendations count: ${recommendations?.length ?? 0}');
      print('🎭 Emotion log ID: $emotionLogId');

      // İsimsiz mekanları filtrele (ÇOK AGRESİF)
      List<dynamic>? filteredRecommendations;
      if (recommendations != null) {
        filteredRecommendations = recommendations.where((rec) {
          final name = rec['name'] as String?;
          // İsimsiz mekanları ve boş isimleri filtrele
          if (name == null || name.isEmpty || name.trim().isEmpty) return false;
          final nameLower = name.toLowerCase().trim();
          if (nameLower == 'isimsiz mekan' || 
              nameLower == 'unnamed place' ||
              nameLower == 'unnamed' ||
              nameLower == 'isimsiz' ||
              nameLower == 'bilinmeyen mekan' ||
              nameLower == 'unknown place' ||
              nameLower.length < 3 || // Çok kısa isimler
              nameLower == 'park' || // Çok genel isimler
              nameLower == 'mekan' ||
              nameLower == 'place') return false;
          return true;
        }).toList();
        print('🎭 Filtered recommendations count: ${filteredRecommendations.length}');
      }

      // Öneriler varsa modal göster, yoksa basit mesaj
      if (mounted) {
        if (filteredRecommendations != null && filteredRecommendations.isNotEmpty) {
          // Öneriler modal'ını göster
          _showRecommendationsModal(
            context,
            detectedEmotion,
            confidence,
            filteredRecommendations,
            position,
          );
        } else {
          // Öneri yoksa duygu sonucunu göster
          _showEmotionResultModal(
            context,
            detectedEmotion,
            confidence,
            position,
          );
        }
      }

      // Fotoğrafı temizle
      setState(() {
        _capturedImage = null;
      });

    } catch (e, stackTrace) {
      print('❌ Fotoğraf işleme hatası: $e');
      print('❌ StackTrace: $stackTrace');
      
      // Dialog'u kapat
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog
      }

      String errorMessage = 'Fotoğraf işlenirken hata oluştu';
      if (e.toString().contains('403') || e.toString().contains('401')) {
        errorMessage = 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
        // Kullanıcıyı login ekranına yönlendir
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          // Tema ayarını sıfırla
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          await themeProvider.resetTheme();
          // Login ekranına yönlendirme burada yapılabilir
        }
      } else {
        errorMessage = 'Fotoğraf işlenirken hata oluştu: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                Colors.black,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kamera hazırlanıyor...',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lütfen bekleyin',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isPermissionGranted) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                (route) => false,
              );
            },
          ),
          title: Text(
            'Kamera İzni',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                AppTheme.primaryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 70,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Kamera İzni Gerekli',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ruh halinizi tespit edebilmek için kameraya erişim izni vermeniz gerekmektedir.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      icon: const Icon(Icons.settings, color: Colors.white),
                      label: Text(
                        'Ayarlara Git',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                (route) => false,
              );
            },
          ),
          title: Text(
            'Kamera Hatası',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                AppTheme.errorRed.withOpacity(0.05),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: AppTheme.errorRed,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Kamera Başlatılamadı',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kamerayı başlatırken bir sorun oluştu.\nLütfen tekrar deneyin.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _initializeCamera();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Tekrar Dene',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Kamera controller'ın initialize olduğundan emin ol
    if (!_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                Colors.black,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kamera hazırlanıyor...',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera önizlemesi
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Üst gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Üst bar (AppBar yerine)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Ruh Halini Tespit Et',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flip_camera_ios, size: 20),
                      color: Colors.white,
                      onPressed: () {
                        // Kamera değiştirme özelliği eklenebilir
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Yüz tespiti guide overlay (orta kısım)
          Center(
            child: Container(
              width: 280,
              height: 360,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Köşe işaretleri
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 3),
                          left: BorderSide(color: Colors.white, width: 3),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 3),
                          right: BorderSide(color: Colors.white, width: 3),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 3),
                          left: BorderSide(color: Colors.white, width: 3),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 3),
                          right: BorderSide(color: Colors.white, width: 3),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Alt gradient overlay ve butonlar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Talimat metni
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.face_retouching_natural,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Yüzünüzü çerçeveye hizalayın',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Çek butonu ve çevresindeki tasarım
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dış halka (animasyonlu)
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          // Orta halka
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          // Ana çek butonu
                          GestureDetector(
                            onTap: _isCapturing ? null : _takePicture,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _isCapturing
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                color: _isCapturing ? Colors.grey.shade300 : null,
                                boxShadow: _isCapturing
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: _isCapturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(22),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt_rounded,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Alt bilgi metni
                      Text(
                        'Fotoğraf çekmek için butona dokunun',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Öneriler modal'ını göster
  void _showRecommendationsModal(
    BuildContext context,
    String emotion,
    double confidence,
    List recommendations,
    Position? position,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A5F),
                    Color(0xFF0F1B2E),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Emoji
                  Text(
                    _getEmotionEmoji(emotion),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  
                  // Duygu ve güven
                  Text(
                    'Duygu: ${_getEmotionDisplayName(emotion)}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Güven: ${(confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Öneri sayısı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${recommendations.length} mekan önerisi bulundu!',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Öneri listesi
            Expanded(
              child: recommendations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Uygun mekan bulunamadı',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lütfen daha sonra tekrar deneyin',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        final rec = recommendations[index];
                        final name = rec['name'] as String? ?? 'Mekan';
                        final category = rec['category'] as String? ?? 'Mekan';
                        final distance = rec['distance'] as num?;
                        final rating = rec['rating'] as num?;
                        final externalId = rec['externalId'] as String?;
                        final placeId = externalId ?? '';
                        
                        return GestureDetector(
                          onTap: () {
                            _showPlaceDetailsModal(context, placeId, rec);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1E3A5F).withOpacity(0.05),
                                  const Color(0xFF0F1B2E).withOpacity(0.03),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF1E3A5F).withOpacity(0.1),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F1B2E).withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Container - Koyu mavi gradient
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1E3A5F),
                                          Color(0xFF0F1B2E),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1E3A5F).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(category),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.inter(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F1B2E),
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E3A5F).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                category,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF1E3A5F),
                                                ),
                                              ),
                                            ),
                                            if (distance != null) ...[
                                              const SizedBox(width: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.place_outlined,
                                                    size: 14,
                                                    color: const Color(0xFF64748B),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${distance.toStringAsFixed(1)} km',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Rating - Koyu mavi ton
                                  if (rating != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF22C55E),
                                            Color(0xFF16A34A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF22C55E).withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Butonlar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Kapat',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Mekanlar sekmesine git
                        if (widget.onPlacesTap != null) {
                          widget.onPlacesTap!();
                        }
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Haritada Gör'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Duygu sonucu modal'ı (öneri yoksa)
  void _showEmotionResultModal(
    BuildContext context,
    String emotion,
    double confidence,
    Position? position,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Emoji
            Text(
              _getEmotionEmoji(emotion),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            
            // Duygu
            Text(
              'Duygu: ${_getEmotionDisplayName(emotion)}',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Güven
            Text(
              'Güven: ${(confidence * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Konum bilgisi
            if (position != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📍 ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Kapat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.onPlacesTap != null) {
                        widget.onPlacesTap!();
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Mekanlar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'mutlu':
        return '😊';
      case 'sad':
      case 'üzgün':
        return '😢';
      case 'angry':
      case 'kızgın':
        return '😠';
      case 'fearful':
      case 'fear':
      case 'korkmuş':
        return '😨';
      case 'disgusted':
      case 'disgust':
      case 'iğrenmiş':
        return '🤢';
      case 'surprised':
      case 'surprise':
      case 'şaşırmış':
        return '😲';
      case 'neutral':
      case 'nötr':
      default:
        return '😐';
    }
  }

  String _getEmotionDisplayName(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'Mutlu';
      case 'sad':
        return 'Üzgün';
      case 'angry':
        return 'Kızgın';
      case 'fearful':
      case 'fear':
        return 'Korkmuş';
      case 'disgusted':
      case 'disgust':
        return 'İğrenmiş';
      case 'surprised':
      case 'surprise':
        return 'Şaşırmış';
      case 'neutral':
      default:
        return 'Nötr';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kafe':
      case 'cafe':
        return Icons.coffee;
      case 'restoran':
      case 'restaurant':
        return Icons.restaurant;
      case 'park':
        return Icons.park;
      case 'müze':
      case 'museum':
        return Icons.museum;
      case 'sinema':
      case 'cinema':
        return Icons.movie;
      case 'tiyatro':
      case 'theatre':
        return Icons.theater_comedy;
      case 'bar':
        return Icons.local_bar;
      case 'spa':
        return Icons.spa;
      case 'spor salonu':
      case 'gym':
        return Icons.fitness_center;
      case 'kütüphane':
      case 'library':
        return Icons.local_library;
      case 'avm':
      case 'shopping_mall':
        return Icons.shopping_bag;
      default:
        return Icons.place;
    }
  }

  /// Mekan detay modalını gösterir
  Future<void> _showPlaceDetailsModal(
    BuildContext context,
    String placeId,
    Map<String, dynamic> placeData,
  ) async {
    final apiService = ApiService();
    Map<String, dynamic>? details;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // PlaceId'yi al (prefix'ler backend tarafından yönetiliyor)
    String finalPlaceId = placeId;
    if (finalPlaceId.isEmpty) {
      final externalId = placeData['externalId'] as String?;
      if (externalId != null && externalId.isNotEmpty) {
        finalPlaceId = externalId;
      }
    }

    try {
      if (finalPlaceId.isNotEmpty) {
        details = await apiService.getPlaceDetails(finalPlaceId);
      }
    } catch (e) {
      print('❌ Place details hatası: $e');
    }

    if (!context.mounted) return;
    Navigator.pop(context); // Loading dialog'u kapat

    // Fallback: Place data'dan göster
    details ??= placeData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlaceDetailsModal(
        placeData: details!,
        placeId: finalPlaceId,
      ),
    );
  }
}

/// Mekan detay modal widget'ı
class _PlaceDetailsModal extends StatefulWidget {
  final Map<String, dynamic> placeData;
  final String placeId;

  const _PlaceDetailsModal({
    required this.placeData,
    required this.placeId,
  });

  @override
  State<_PlaceDetailsModal> createState() => _PlaceDetailsModalState();
}

class _PlaceDetailsModalState extends State<_PlaceDetailsModal> {

  @override
  Widget build(BuildContext context) {
    final name = widget.placeData['name'] as String? ?? 'Mekan';
    final address = widget.placeData['address'] as String?;
    final rating = widget.placeData['rating'] as num?;
    final userRatingsTotal = widget.placeData['userRatingsTotal'] as int?;
    final phone = widget.placeData['phone'] as String?;
    final website = widget.placeData['website'] as String?;
    final isOpen = widget.placeData['isOpen'] as bool?;
    final photos = widget.placeData['photos'] as List<dynamic>?;
    final reviews = widget.placeData['reviews'] as List<dynamic>?;
    final category = widget.placeData['category'] as String? ?? 'Mekan';
    final tags = widget.placeData['tags'] as List<dynamic>?;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A5F),
                  Color(0xFF0F1B2E),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                if (rating != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (userRatingsTotal != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '($userRatingsTotal)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isOpen != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isOpen 
                                ? const Color(0xFF22C55E).withOpacity(0.2)
                                : const Color(0xFFEF4444).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOpen ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: isOpen ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOpen ? 'Açık' : 'Kapalı',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photos - Profesyonel tasarım
                  if (photos != null && photos.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: const Color(0xFF1E3A5F),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fotoğraflar',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F1B2E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A5F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${photos.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E3A5F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length > 10 ? 10 : photos.length,
                            itemBuilder: (context, index) {
                              final photo = photos[index];
                              // Backend'den gelen format: {url, photoReference, width, height}
                              final photoUrl = photo['url'] as String? ?? 
                                             (photo is Map ? photo['url'] as String? : null);
                              final photoRef = photo['photoReference'] as String? ?? 
                                            (photo is Map ? photo['photoReference'] as String? : null);
                              
                              // Eğer URL yoksa ama photoReference varsa, URL oluştur
                              String? finalUrl = photoUrl;
                              if ((finalUrl == null || finalUrl.isEmpty) && photoRef != null && photoRef.isNotEmpty) {
                                // Google Places Photo API URL'i oluştur
                                finalUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$photoRef&key=AIzaSyDiW6xaSH0iSg24H5QWKcaa_5ibyW2oeXY';
                              }
                              
                              if (finalUrl == null || finalUrl.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              return Container(
                                width: 280,
                                margin: EdgeInsets.only(
                                  right: index == (photos.length > 10 ? 9 : photos.length - 1) ? 0 : 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        finalUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: const Color(0xFF1E3A5F),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Gradient overlay (bottom)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 60,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.3),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Address - Profesyonel tasarım
                  if (address != null && address.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF1E3A5F),
                      title: 'Adres',
                      content: address,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Phone - Profesyonel tasarım
                  if (phone != null && phone.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.phone_rounded,
                      iconColor: const Color(0xFF22C55E),
                      title: 'Telefon',
                      content: phone,
                      onTap: () {
                        // TODO: Call functionality
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Website - Profesyonel tasarım
                  if (website != null && website.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Web Sitesi',
                      content: website,
                      onTap: () {
                        // TODO: Open website
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (tags != null && tags.isNotEmpty) ...[
                    Text(
                      'Kategoriler',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F1B2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A5F),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reviews - Profesyonel tasarım
                  if (reviews != null && reviews.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.reviews_rounded,
                          color: const Color(0xFF1E3A5F),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yorumlar',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F1B2E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${reviews.length}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A5F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...reviews.take(5).map((review) {
                      final authorName = review['authorName'] as String? ?? 'Anonim';
                      final reviewText = review['text'] as String? ?? '';
                      final reviewRating = review['rating'] as int?;
                      final relativeTime = review['relativeTimeDescription'] as String?;
                      final profilePhotoUrl = review['profilePhotoUrl'] as String?;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.grey[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Profile Photo
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1E3A5F),
                                        Color(0xFF0F1B2E),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1E3A5F).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            profilePhotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authorName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F1B2E),
                                        ),
                                      ),
                                      if (relativeTime != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          relativeTime,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (reviewRating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                                      ),
                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$reviewRating',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (reviewText.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[100]!,
                                  ),
                                ),
                                child: Text(
                                  reviewText,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF1E293B),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Kapat',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      // Tek mekanı RecommendationModel'e çevir
                      final placeJson = Map<String, dynamic>.from(widget.placeData);
                      final recModel = RecommendationModel.fromJson(placeJson);

                      // Harita ekranını bu mekanla aç
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecommendationMapScreen(
                            initialRecommendation: recModel,
                            initialRecommendations: [recModel],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Haritada Gör'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor,
                    iconColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F1B2E),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: iconColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
