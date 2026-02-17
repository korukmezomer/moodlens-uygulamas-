import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/recommendation_model.dart';
import 'user_home_screen.dart';

class RecommendationMapScreen extends StatefulWidget {
  final RecommendationModel? initialRecommendation;
  final List<RecommendationModel>? initialRecommendations;
  
  const RecommendationMapScreen({
    super.key, 
    this.initialRecommendation,
    this.initialRecommendations,
  });

  @override
  State<RecommendationMapScreen> createState() => _RecommendationMapScreenState();
}

class _RecommendationMapScreenState extends State<RecommendationMapScreen> {
  final ApiService _apiService = ApiService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<RecommendationModel> _recommendations = [];
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  RecommendationModel? _selectedRecommendation;
  Map<String, bool> _favoriteStatus = {}; // placeExternalId -> isFavorite
  Map<String, bool> _favoriteLoading = {}; // placeExternalId -> isLoading

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      // Konum izni al
      await _getCurrentLocation();
      
      // Önerileri yükle
      if (widget.initialRecommendations != null && widget.initialRecommendations!.isNotEmpty) {
        _recommendations = widget.initialRecommendations!;
        _updateMarkers();
        print('✅ ${_recommendations.length} öneri yüklendi (initialRecommendations)');
      } else {
      await _loadRecommendations();
      }

      // Initial recommendation varsa seç
      if (widget.initialRecommendation != null) {
        _selectedRecommendation = widget.initialRecommendation;
        _moveToLocation(
          widget.initialRecommendation!.latitude,
          widget.initialRecommendation!.longitude,
        );
        // Favori durumunu kontrol et
        _checkFavorite(widget.initialRecommendation!);
      }
    } catch (e) {
      print('❌ Harita başlatma hatası: $e');
      _setDefaultLocation();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Konum servisleri kontrol
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        _setDefaultLocation();
        return;
      }

      // İzin kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        _setDefaultLocation();
        return;
      }

      if (permission == LocationPermission.denied) {
        _setDefaultLocation();
        return;
      }

      // Konum al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() => _currentPosition = position);
        _updateMarkers();
      }
      
      print('✅ Konum alındı: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Konum alınamadı: $e');
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _currentPosition = Position(
        latitude: 41.0082,
        longitude: 28.9784,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    });
  }

  void _showLocationServiceDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppTheme.warningYellow),
            const SizedBox(width: 12),
            Text('Konum Kapalı', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Yakındaki mekanları görmek için konum servislerini açın.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ayarları Aç', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: AppTheme.errorRed),
            const SizedBox(width: 12),
            Text('İzin Gerekli', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Konum izni olmadan yakındaki mekanları gösteremiyoruz. Lütfen ayarlardan izin verin.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ayarları Aç', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecommendations() async {
    try {
      // Önce editör seçimi mekanları yükle
      final editorChoiceData = await _apiService.getEditorChoicePlaces();
      List<RecommendationModel> editorChoicePlaces = [];
      
      if (editorChoiceData.isNotEmpty) {
        editorChoiceData.forEach((json) {
          try {
            // PlaceResponse formatını RecommendationModel'e çevir
            // Backend'den gelen Place entity'sinde externalId var, onu kullan
            String? externalId;
            if (json['externalId'] != null) {
              externalId = json['externalId'].toString();
            } else if (json['id'] != null) {
              // Eğer externalId yoksa, veritabanından almak gerekir
              // Şimdilik place_0_ formatını kullan
              externalId = 'place_0_${json['id']}';
            }
            
            final rec = RecommendationModel(
              id: json['id'] ?? 0,
              name: json['name'] ?? 'Mekan',
              description: json['description'],
              latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
              address: json['address'],
              category: json['tags'] != null && (json['tags'] as List).isNotEmpty 
                  ? (json['tags'] as List)[0].toString() 
                  : null,
              tags: json['tags'] != null 
                  ? (json['tags'] as List).map((e) => e.toString()).toList()
                  : null,
              rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
              externalId: externalId,
            );
            editorChoicePlaces.add(rec);
          } catch (e) {
            print('⚠️ Editör seçimi mekan parse hatası: $e');
          }
        });
      }
      
      // Eğer editör seçimi mekanlar varsa onları kullan, yoksa eski yöntemi kullan
      if (editorChoicePlaces.isNotEmpty) {
        setState(() {
          _recommendations = editorChoicePlaces;
        });
        _updateMarkers();
        print('✅ ${_recommendations.length} editör seçimi mekan yüklendi');
      } else {
        // Fallback: Son önerileri yükle
        final data = await _apiService.getRecentRecommendations(limit: 30);
        final filtered = data
            .map((json) => RecommendationModel.fromJson(json))
            .where((rec) {
              if (rec.name.isEmpty || rec.name.trim().isEmpty) return false;
              final nameLower = rec.name.toLowerCase().trim();
              if (nameLower == 'isimsiz mekan' || 
                  nameLower == 'unnamed place' ||
                  nameLower == 'unnamed' ||
                  nameLower == 'isimsiz' ||
                  nameLower == 'bilinmeyen mekan' ||
                  nameLower == 'unknown place' ||
                  nameLower.length < 3 ||
                  nameLower == 'park' ||
                  nameLower == 'mekan' ||
                  nameLower == 'place') return false;
              return true;
            })
            .toList();
        setState(() {
          _recommendations = filtered;
        });
        _updateMarkers();
        print('✅ ${_recommendations.length} öneri yüklendi (filtrelenmiş)');
      }
    } catch (e) {
      print('❌ Öneriler yüklenirken hata: $e');
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};
    final Set<Circle> circles = {};

    // Mevcut konum
    if (_currentPosition != null) {
      circles.add(
        Circle(
          circleId: const CircleId('current_location_accuracy'),
          center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          radius: _currentPosition!.accuracy > 0 ? _currentPosition!.accuracy : 50,
          fillColor: AppTheme.primaryColor.withOpacity(0.1),
          strokeColor: AppTheme.primaryColor.withOpacity(0.3),
          strokeWidth: 1,
        ),
      );
    }

    // Öneri marker'ları
    for (var rec in _recommendations) {
      final isSelected = _selectedRecommendation?.id == rec.id;
      markers.add(
        Marker(
          markerId: MarkerId('rec_${rec.id}'),
          position: LatLng(rec.latitude, rec.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: rec.name,
            snippet: rec.category ?? 'Mekan',
          ),
          onTap: () => _selectRecommendation(rec),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  void _selectRecommendation(RecommendationModel rec) {
    setState(() => _selectedRecommendation = rec);
    _updateMarkers();
    _moveToLocation(rec.latitude, rec.longitude);
    _checkFavorite(rec); // Favori durumunu kontrol et
  }

  void _moveToLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
    );
  }

  Future<void> _openInGoogleMaps(RecommendationModel rec) async {
    // Uygulama içi rota ve süre gösterimi
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alınamadı, rota çizilemiyor', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }

    final userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final placeLatLng = LatLng(rec.latitude, rec.longitude);

    // Düz bir çizgi ile temel rota çiz (yol ağı yerine kuş uçuşu, ama görsel olarak yeterli)
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: AppTheme.primaryColor,
          width: 5,
          points: [userLatLng, placeLatLng],
        ),
      };
    });

    // Kamerayı her iki noktayı da görecek şekilde ayarla
    final southwest = LatLng(
      userLatLng.latitude < placeLatLng.latitude ? userLatLng.latitude : placeLatLng.latitude,
      userLatLng.longitude < placeLatLng.longitude ? userLatLng.longitude : placeLatLng.longitude,
    );
    final northeast = LatLng(
      userLatLng.latitude > placeLatLng.latitude ? userLatLng.latitude : placeLatLng.latitude,
      userLatLng.longitude > placeLatLng.longitude ? userLatLng.longitude : placeLatLng.longitude,
    );

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        80,
      ),
    );

    // Mesafe (backend'den geliyorsa onu kullan, yoksa hesapla)
    double distanceKm = rec.distance ??
        (Geolocator.distanceBetween(
              userLatLng.latitude,
              userLatLng.longitude,
              placeLatLng.latitude,
              placeLatLng.longitude,
            ) /
            1000.0);

    // Basit süre tahmini
    final drivingMinutes = (distanceKm / 40 * 60).round(); // ort. 40 km/s
    final walkingMinutes = (distanceKm / 4.5 * 60).round(); // ort. 4.5 km/s

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.place, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.directions_car, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Arabayla yaklaşık $drivingMinutes dk',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.directions_walk, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Yürüyerek yaklaşık $walkingMinutes dk',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Süreler tahmini olarak hesaplanmıştır.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: null, // Drawer'ı kapat
      body: _isLoading
          ? _buildLoadingView()
          : Stack(
              children: [
                // Harita
                _buildMap(),
                
                // Üst bar
                _buildTopBar(),
                
                // Seçili mekan kartı
                if (_selectedRecommendation != null)
                  _buildSelectedPlaceCard(),
                
                // Alt mekan listesi
                if (_recommendations.isNotEmpty && _selectedRecommendation == null)
                  _buildPlacesList(),
                
                // Konum butonu
                _buildLocationButton(),
                
                // Zoom butonları
                _buildZoomControls(),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Harita yükleniyor...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(41.0082, 28.9784),
        zoom: 14,
      ),
      markers: _markers,
      circles: _circles,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentPosition != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _moveToLocation(_currentPosition!.latitude, _currentPosition!.longitude);
          });
        }
      },
      onTap: (_) {
        setState(() => _selectedRecommendation = null);
        _updateMarkers();
      },
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF1F2937) : Colors.white,
              (isDark ? const Color(0xFF1F2937) : Colors.white).withOpacity(0),
            ],
          ),
        ),
        child: Row(
          children: [
            // Geri butonu
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  // Ana sayfaya geri dön
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Başlık
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.explore, color: AppTheme.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Keşfet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_recommendations.length} mekan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      right: 16,
      bottom: _selectedRecommendation != null ? 220 : (_recommendations.isNotEmpty ? 200 : 100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.my_location, color: AppTheme.primaryColor),
          onPressed: () async {
            await _getCurrentLocation();
            if (_currentPosition != null) {
              _moveToLocation(_currentPosition!.latitude, _currentPosition!.longitude);
            }
          },
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    // Konum butonunun üstüne yerleştir
    final locationButtonBottom = _selectedRecommendation != null 
        ? 220 
        : (_recommendations.isNotEmpty ? 200 : 100);
    
    return Positioned(
      right: 16,
      bottom: locationButtonBottom + 60, // Konum butonunun üstüne
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom In butonu
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (_mapController != null) {
                    await _mapController!.animateCamera(
                      CameraUpdate.zoomIn(),
                    );
                  }
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.add,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Divider
            Container(
              width: 48,
              height: 1,
              color: Colors.grey.shade200,
            ),
            
            // Zoom Out butonu
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (_mapController != null) {
                    await _mapController!.animateCamera(
                      CameraUpdate.zoomOut(),
                    );
                  }
                },
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.remove,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPlaceCard() {
    final rec = _selectedRecommendation!;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                // Kategori ikonu
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.travelGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(rec.category ?? 'Mekan'),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // İsim ve kategori
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rec.category ?? 'Mekan',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          if (rec.distance != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.place, size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 2),
                            Text(
                              '${rec.distance!.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Rating
                if (rec.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 18, color: AppTheme.successGreen),
                        const SizedBox(width: 4),
                        Text(
                          rec.rating!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Kapat butonu
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textLight),
                  onPressed: () {
                    setState(() => _selectedRecommendation = null);
                    _updateMarkers();
                  },
                ),
              ],
            ),
            
            // Adres
            if (rec.address != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec.address!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Butonlar
            Row(
              children: [
                // Favorite butonu
                Container(
                  decoration: BoxDecoration(
                    color: (_favoriteStatus[_getPlaceExternalId(rec)] ?? false)
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _favoriteLoading[_getPlaceExternalId(rec)] == true
                        ? null
                        : () => _toggleFavorite(rec),
                    icon: _favoriteLoading[_getPlaceExternalId(rec)] == true
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            (_favoriteStatus[_getPlaceExternalId(rec)] ?? false)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: (_favoriteStatus[_getPlaceExternalId(rec)] ?? false)
                                ? Colors.red
                                : Colors.grey[600],
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Gittim butonu
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAsVisited(rec),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'Gittim',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      side: BorderSide(color: AppTheme.successGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Yol tarifi butonu - GİT
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _openInGoogleMaps(rec),
                    icon: const Icon(Icons.directions, size: 20),
                    label: Text(
                      'Yol Tarifi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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

  Widget _buildPlacesList() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.9),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Editör Seçimi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final rec = _recommendations[index];
                  return GestureDetector(
                    onTap: () => _selectRecommendation(rec),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12, bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(rec.category ?? 'Mekan'),
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const Spacer(),
                              if (rec.rating != null)
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      rec.rating!.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rec.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rec.category ?? 'Mekan',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const Spacer(),
                          if (rec.distance != null)
                            Text(
                              '${rec.distance!.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
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
      ),
    );
  }

  void _showPlaceDetails(RecommendationModel rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İsim
                    Text(
                      rec.name,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bilgiler
                    _buildInfoRow(Icons.category, rec.category ?? 'Mekan'),
                    if (rec.address != null)
                      _buildInfoRow(Icons.location_on, rec.address!),
                    if (rec.distance != null)
                      _buildInfoRow(Icons.directions_walk, '${rec.distance!.toStringAsFixed(1)} km uzaklıkta'),
                    if (rec.rating != null)
                      _buildInfoRow(Icons.star, '${rec.rating!.toStringAsFixed(1)} puan'),
                    if (rec.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        rec.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Git butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openInGoogleMaps(rec);
                        },
                        icon: const Icon(Icons.directions),
                        label: Text(
                          'Yol Tarifi Al',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _markAsVisited(RecommendationModel rec) async {
    try {
      await _apiService.recordPlaceVisit(
        placeExternalId: _getPlaceExternalId(rec),
        placeName: rec.name,
        placeCategory: rec.category,
        latitude: rec.latitude,
        longitude: rec.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${rec.name} ziyaret edildi olarak işaretlendi!',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Ziyaret kaydedilemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt yapılamadı', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _getPlaceExternalId(RecommendationModel rec) {
    // RecommendationModel'den externalId al veya oluştur
    if (rec.externalId != null && rec.externalId!.isNotEmpty) {
      String externalId = rec.externalId!.trim();
      // Prefix'leri kaldır (google_, place_0_ vb.) - backend'e gönderilirken tutarlı format kullan
      externalId = externalId.replaceFirst('google_', '');
      externalId = externalId.replaceFirst('place_0_', '');
      return externalId;
    }
    // Fallback: ID'den oluştur
    return 'place_${rec.id}_${rec.name.hashCode}';
  }

  Future<void> _checkFavorite(RecommendationModel rec) async {
    final placeId = _getPlaceExternalId(rec);
    if (placeId.isEmpty) return;
    
    debugPrint('🔍 Harita _checkFavorite: placeId = $placeId (rec.externalId=${rec.externalId})');
    
    try {
      final isFav = await _apiService.isFavorite(placeId);
      debugPrint('✅ Harita _checkFavorite: isFavorite = $isFav for placeId = $placeId');
      setState(() {
        _favoriteStatus[placeId] = isFav;
      });
    } catch (e) {
      debugPrint('❌ Harita _checkFavorite hatası: $e');
      // Silent fail - hata durumunda false varsay
      setState(() {
        _favoriteStatus[placeId] = false;
      });
    }
  }

  Future<void> _toggleFavorite(RecommendationModel rec) async {
    final placeId = _getPlaceExternalId(rec);
    if (placeId.isEmpty) return;

    debugPrint('🔄 Harita _toggleFavorite: placeId = $placeId, current status = ${_favoriteStatus[placeId]}');

    setState(() {
      _favoriteLoading[placeId] = true;
    });

    try {
      final currentStatus = _favoriteStatus[placeId] ?? false;
      
      if (currentStatus) {
        debugPrint('🗑️ Harita: Favoriden çıkarılıyor...');
        final success = await _apiService.removeFavorite(placeId);
        debugPrint('✅ Harita removeFavorite: success = $success');
        if (success) {
          // Favori durumunu tekrar kontrol et (güvenlik için)
          await _checkFavorite(rec);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mekan favorilerden çıkarıldı'),
                backgroundColor: AppTheme.successGreen,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Başarısız olursa tekrar kontrol et
          await _checkFavorite(rec);
        }
      } else {
        debugPrint('➕ Harita: Favorilere ekleniyor...');
        final success = await _apiService.addFavorite(
          placeExternalId: placeId,
          placeName: rec.name,
          placeCategory: rec.category,
          latitude: rec.latitude,
          longitude: rec.longitude,
          address: rec.address,
          rating: rec.rating,
          imageUrl: rec.imageUrl,
        );
        debugPrint('✅ Harita addFavorite: success = $success, placeExternalId = $placeId');
        if (success) {
          // Favori durumunu tekrar kontrol et (güvenlik için)
          await _checkFavorite(rec);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mekan favorilere eklendi'),
                backgroundColor: AppTheme.successGreen,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Başarısız olursa tekrar kontrol et
          await _checkFavorite(rec);
        }
      }
    } catch (e) {
      debugPrint('❌ Harita _toggleFavorite hatası: $e');
      // Hata durumunda da favori durumunu kontrol et
      await _checkFavorite(rec);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _favoriteLoading[placeId] = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
