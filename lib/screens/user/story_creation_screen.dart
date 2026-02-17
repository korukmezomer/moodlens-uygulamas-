import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class StoryCreationScreen extends StatefulWidget {
  const StoryCreationScreen({super.key});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  
  File? _selectedImage;
  String? _caption;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _textEditorController = TextEditingController();
  bool _isCaptionVisible = false;
  Color _textColor = Colors.white;
  double _textSize = 24.0;
  bool _isTextEditing = false;
  
  // Drawing
  List<DrawingPoint> _points = [];
  Color _drawingColor = Colors.white;
  double _strokeWidth = 4.0;
  bool _isDrawingMode = false;
  bool _isDrawing = false;
  
  // Stickers
  bool _isStickerMode = false;
  final List<String> _stickers = ['😀', '😍', '😂', '😎', '🤔', '😢', '❤️', '🔥', '👍', '👏', '🎉', '💯'];
  List<StickerItem> _placedStickers = [];
  StickerItem? _selectedSticker;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _startCamera(_cameras!.first);
      }
    } catch (e) {
      debugPrint('Kamera başlatılamadı: $e');
    }
  }
  
  Future<void> _startCamera(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Kamera initialize hatası: $e');
    }
  }
  
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    setState(() {
      _isCameraInitialized = false;
    });
    
    await _cameraController?.dispose();
    _isFrontCamera = !_isFrontCamera;
    
    final camera = _isFrontCamera ? _cameras!.last : _cameras!.first;
    await _startCamera(camera);
  }
  
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Flash hatası: $e');
    }
  }
  
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      final XFile photo = await _cameraController!.takePicture();
      if (mounted) {
        setState(() {
          _selectedImage = File(photo.path);
          _isCapturing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekilemedi: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galeriden seçilemedi: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  /// Tüm katmanları (fotoğraf + çizim + metin + emoji) tek bir görüntüye birleştir
  Future<File?> _mergeLayers() async {
    if (_selectedImage == null) return null;

    try {
      // Ekran boyutunu al (build method'undan önce sakla)
      final screenSize = MediaQuery.of(context).size;
      
      // Base image'i yükle
      final imageBytes = await _selectedImage!.readAsBytes();
      img.Image? baseImage = img.decodeImage(imageBytes);
      if (baseImage == null) return null;

      // Canvas boyutlarını al (ekran boyutuna göre değil, gerçek görüntü boyutuna göre)
      final width = baseImage.width;
      final height = baseImage.height;
      final scaleX = width / screenSize.width;
      final scaleY = height / screenSize.height;

      // Yeni canvas oluştur
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      // 1. Base image'i çiz
      final imageCodec = await ui.instantiateImageCodec(imageBytes);
      final frame = await imageCodec.getNextFrame();
      final baseImageUi = frame.image;
      canvas.drawImageRect(
        baseImageUi,
        Rect.fromLTWH(0, 0, baseImageUi.width.toDouble(), baseImageUi.height.toDouble()),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint(),
      );
      baseImageUi.dispose();

      // 2. Çizimleri çiz
      if (_points.isNotEmpty) {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < _points.length - 1; i++) {
          if (_points[i].isEnd || _points[i + 1].isEnd) continue;
          if (_points[i].color == null || _points[i].strokeWidth == null) continue;

          paint.color = _points[i].color!;
          paint.strokeWidth = (_points[i].strokeWidth! * scaleX).clamp(1, 50);

          final startPoint = Offset(
            _points[i].point.dx * scaleX,
            _points[i].point.dy * scaleY,
          );
          final endPoint = Offset(
            _points[i + 1].point.dx * scaleX,
            _points[i + 1].point.dy * scaleY,
          );

          canvas.drawLine(startPoint, endPoint, paint);
        }
      }

      // 3. Metin çiz
      if (_isCaptionVisible && _caption != null && _caption!.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: _caption!,
            style: GoogleFonts.inter(
              fontSize: _textSize * scaleX,
              fontWeight: FontWeight.w600,
              color: _textColor,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 8 * scaleX,
                  offset: Offset(0, 2 * scaleY),
                ),
              ],
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: width * 0.9);
        final textOffset = Offset(
          (width - textPainter.width) / 2,
          height * 0.85, // Bottom'a yakın konum
        );
        textPainter.paint(canvas, textOffset);
      }

      // 4. Emoji/Sticker'ları çiz
      for (final sticker in _placedStickers) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: sticker.emoji,
            style: TextStyle(
              fontSize: 60 * scaleX, // Sticker boyutu
              fontFamily: 'Apple Color Emoji', // Emoji font desteği için
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        final stickerOffset = Offset(
          (sticker.position.dx * scaleX) - (textPainter.width / 2),
          (sticker.position.dy * scaleY) - (textPainter.height / 2),
        );
        textPainter.paint(canvas, stickerOffset);
      }

      // Canvas'ı görüntüye dönüştür
      final picture = recorder.endRecording();
      final mergedImageUi = await picture.toImage(width, height);
      final byteData = await mergedImageUi.toByteData(format: ui.ImageByteFormat.png);
      
      // Memory temizliği
      picture.dispose();
      
      if (byteData == null) {
        mergedImageUi.dispose();
        return null;
      }

      // Geçici dosyaya kaydet (orijinal dosyanın bulunduğu dizinde)
      final originalDir = _selectedImage!.parent;
      final tempFile = File('${originalDir.path}/story_merged_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      // Memory temizliği
      mergedImageUi.dispose();

      return tempFile;
    } catch (e) {
      debugPrint('Katman birleştirme hatası: $e');
      return null;
    }
  }

  Future<void> _shareStory() async {
    if (_selectedImage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // Tüm katmanları birleştir
      File? mergedImage = await _mergeLayers();
      
      // Eğer birleştirme başarısız olursa, orijinal görüntüyü kullan
      final imageToShare = mergedImage ?? _selectedImage!;

      await _apiService.createStory(imageToShare, caption: _caption);
      
      if (mounted) {
        Navigator.pop(context); // Loading dialog
        Navigator.pop(context, true); // Story creation screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story paylaşıldı'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }

      // Geçici dosyayı temizle
      if (mergedImage != null && mergedImage.existsSync()) {
        try {
          await mergedImage.delete();
        } catch (e) {
          debugPrint('Geçici dosya silinemedi: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Story paylaşılamadı: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    _captionController.dispose();
    _textEditorController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview or Selected Image
            if (_selectedImage == null)
              _isCameraInitialized && _cameraController != null
                  ? SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: CameraPreview(_cameraController!),
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
            else
              GestureDetector(
                onPanStart: (details) {
                  if (_isDrawingMode) {
                  setState(() {
                    _isDrawing = true;
                    _points.add(DrawingPoint(
                      point: details.localPosition,
                      color: _drawingColor,
                      strokeWidth: _strokeWidth,
                    ));
                  });
                  } else if (_isStickerMode && _selectedSticker != null) {
                    // Move sticker
                    setState(() {
                      _selectedSticker!.position = details.localPosition;
                    });
                  }
                },
                onPanUpdate: (details) {
                  if (_isDrawingMode && _isDrawing) {
                    setState(() {
                      _points.add(DrawingPoint(
                        point: details.localPosition,
                        color: _drawingColor,
                        strokeWidth: _strokeWidth,
                      ));
                    });
                  } else if (_isStickerMode && _selectedSticker != null) {
                    setState(() {
                      _selectedSticker!.position = details.localPosition;
                    });
                  }
                },
                onPanEnd: (details) {
                  if (_isDrawingMode) {
                  setState(() {
                    _isDrawing = false;
                    _points.add(DrawingPoint(
                      point: Offset.zero,
                      color: _drawingColor,
                      strokeWidth: _strokeWidth,
                      isEnd: true,
                    ));
                  });
                  }
                },
                onTap: () {
                  if (_isStickerMode) {
                    setState(() {
                      _selectedSticker = null;
                    });
                  }
                },
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Drawing layer
                    if (_isDrawingMode)
                    CustomPaint(
                      painter: DrawingPainter(_points),
                      child: Container(),
                    ),
                    // Text overlay
                    if (_isCaptionVisible && _caption != null && _caption!.isNotEmpty)
                      Positioned(
                        bottom: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: Text(
                              _caption!,
                              style: GoogleFonts.inter(
                              fontSize: _textSize,
                                fontWeight: FontWeight.w600,
                              color: _textColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              ),
                              textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    // Stickers
                    ..._placedStickers.map((sticker) => Positioned(
                      left: sticker.position.dx - 30,
                      top: sticker.position.dy - 30,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSticker = sticker;
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: _selectedSticker == sticker
                              ? BoxDecoration(
                                  border: Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: Center(
                            child: Text(
                              sticker.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (_selectedImage == null) ...[
                      IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleFlash,
                      ),
                      if (_cameras != null && _cameras!.length > 1)
                        IconButton(
                          icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 28),
                          onPressed: _switchCamera,
                        ),
                    ] else ...[
                      // Drawing tools
                      if (_isDrawingMode)
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.undo_rounded, color: Colors.white, size: 24),
                            onPressed: () {
                              setState(() {
                                if (_points.isNotEmpty) {
                                  _points.clear();
                                }
                              });
                            },
                          ),
                          PopupMenuButton<Color>(
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _drawingColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                            itemBuilder: (context) => [
                              _buildColorOption(Colors.white),
                              _buildColorOption(Colors.black),
                              _buildColorOption(Colors.red),
                              _buildColorOption(Colors.blue),
                              _buildColorOption(Colors.green),
                              _buildColorOption(Colors.yellow),
                              _buildColorOption(Colors.purple),
                              _buildColorOption(Colors.pink),
                            ],
                            onSelected: (color) {
                              setState(() {
                                _drawingColor = color;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Text Editor (Instagram style)
            if (_isTextEditing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                  child: Column(
                    children: [
                      // Top bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isTextEditing = false;
                                  _textEditorController.clear();
                                });
                              },
                              child: const Text(
                                'İptal',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _caption = _textEditorController.text.trim();
                                  _isCaptionVisible = _caption!.isNotEmpty;
                                  _isTextEditing = false;
                                  if (_caption!.isEmpty) {
                                    _caption = null;
                                  }
                                });
                              },
                              child: const Text(
                                'Tamam',
                                style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Text input
                      Expanded(
                        child: Center(
                          child: TextField(
                            controller: _textEditorController,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: _textSize,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Yazı ekle...',
                              hintStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            maxLines: null,
                            expands: true,
                          ),
                        ),
                      ),
                      // Color picker
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildTextColorOption(Colors.white),
                            _buildTextColorOption(Colors.black),
                            _buildTextColorOption(Colors.red),
                            _buildTextColorOption(Colors.blue),
                            _buildTextColorOption(Colors.green),
                            _buildTextColorOption(Colors.yellow),
                            _buildTextColorOption(Colors.purple),
                            _buildTextColorOption(Colors.pink),
                            _buildTextColorOption(Colors.orange),
                            _buildTextColorOption(Colors.cyan),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Sticker picker (Instagram style) - Above bottom controls
            if (_isStickerMode)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 180, // Above bottom buttons
                left: 0,
                right: 0,
                child: Material(
                  elevation: 20,
                  color: Colors.transparent,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Sticker list
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _stickers.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _placedStickers.add(StickerItem(
                                      emoji: _stickers[index],
                                      position: Offset(
                                        MediaQuery.of(context).size.width / 2,
                                        MediaQuery.of(context).size.height / 2,
                                      ),
                                    ));
                                  });
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _stickers[index],
                                      style: const TextStyle(fontSize: 42),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                ),
              ),
            ),
            
            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedImage == null) ...[
                      // Camera controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery button
                          GestureDetector(
                            onTap: _pickFromGallery,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              ),
                              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                          // Capture button
                          GestureDetector(
                            onTap: _isCapturing ? null : _capturePhoto,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: _isCapturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          // Placeholder for symmetry
                          const SizedBox(width: 50),
                        ],
                      ),
                    ] else ...[
                      // Edit controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Text button
                          _buildBottomButton(
                            icon: Icons.text_fields_rounded,
                            label: 'Yazı',
                            isActive: _isTextEditing,
                            onTap: () {
                              setState(() {
                                _isTextEditing = !_isTextEditing;
                                _isDrawingMode = false;
                                _isStickerMode = false;
                                if (_isTextEditing) {
                                  _textEditorController.text = _caption ?? '';
                              }
                              });
                            },
                          ),
                          // Drawing button
                          _buildBottomButton(
                            icon: Icons.edit_rounded,
                            label: 'Çiz',
                            isActive: _isDrawingMode,
                            onTap: () {
                              setState(() {
                                _isDrawingMode = !_isDrawingMode;
                                _isTextEditing = false;
                                _isStickerMode = false;
                              });
                            },
                          ),
                          // Sticker button
                          _buildBottomButton(
                            icon: Icons.emoji_emotions_rounded,
                            label: 'Sticker',
                            isActive: _isStickerMode,
                            onTap: () {
                              setState(() {
                                _isStickerMode = !_isStickerMode;
                                _isTextEditing = false;
                                _isDrawingMode = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _shareStory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Paylaş',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  PopupMenuItem<Color> _buildColorOption(Color color) {
    return PopupMenuItem<Color>(
      value: color,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 1),
        ),
      ),
    );
  }
  
  Widget _buildTextColorOption(Color color) {
    final isSelected = _textColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _textColor = color;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }
  
  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                width: isActive ? 2.5 : 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DrawingPoint {
  final Offset point;
  final Color? color;
  final double? strokeWidth;
  final bool isEnd;
  
  DrawingPoint({
    required this.point,
    this.color,
    this.strokeWidth,
    this.isEnd = false,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  
  DrawingPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].isEnd) continue;
      if (points[i + 1].isEnd) continue;
      if (points[i].color == null || points[i].strokeWidth == null) continue;
      
      final paint = Paint()
        ..color = points[i].color!
        ..strokeWidth = points[i].strokeWidth!
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(points[i].point, points[i + 1].point, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StickerItem {
  final String emoji;
  Offset position;
  
  StickerItem({
    required this.emoji,
    required this.position,
  });
}
