import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminPlacesScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const AdminPlacesScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminPlacesScreen> createState() => _AdminPlacesScreenState();
}

class _AdminPlacesScreenState extends State<AdminPlacesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _editorChoicePlaces = [];
  bool _isLoading = false;
  bool _isLoadingEditorChoice = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadEditorChoicePlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        print('❌ Konum alınamadı: $e');
      }
    }
  }

  Future<void> _searchPlaces() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen arama terimi girin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _apiService.adminSearchPlaces(
        _searchController.text.trim(),
        latitude: _currentPosition?.latitude ?? 38.3554,
        longitude: _currentPosition?.longitude ?? 38.3095,
        radius: 10000,
      );
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama hatası: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadEditorChoicePlaces() async {
    setState(() {
      _isLoadingEditorChoice = true;
    });

    try {
      final places = await _apiService.adminGetEditorChoicePlaces();
      setState(() {
        _editorChoicePlaces = places;
        _isLoadingEditorChoice = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEditorChoice = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Editör seçimi mekanlar yüklenirken hata: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleEditorChoice(String placeId, bool currentStatus) async {
    try {
      final success = await _apiService.adminToggleEditorChoice(placeId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentStatus 
                  ? 'Editör seçiminden kaldırıldı' 
                  : 'Editör seçimi olarak eklendi'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
        _loadEditorChoicePlaces();
        // Search results'ı da güncelle
        setState(() {
          _searchResults = _searchResults.map((place) {
            if (place['placeId'] == placeId) {
              place['isEditorChoice'] = !currentStatus;
            }
            return place;
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                        ),
              child: const Icon(
                Icons.location_city_rounded,
                          color: Colors.white,
                size: 22,
                        ),
                      ),
            const SizedBox(width: 14),
                            Text(
              'Mekanlar',
                              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2328),
                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
      body: Column(
        children: [
          // Search Section - Modern Style
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                  width: 1,
              ),
            ),
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: 8),
                  // Arama kutusu
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Mekan ara (örn: Kafe, Restoran, Park)',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                          ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                                  ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                            ),
                            ),
                            filled: true,
                          fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
                            hintStyle: GoogleFonts.inter(
                            color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF1F2328),
                          ),
                          onChanged: (value) => setState(() {}),
                          onSubmitted: (_) => _searchPlaces(),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ElevatedButton.icon(
                          onPressed: _isLoading ? null : _searchPlaces,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                          : const Icon(Icons.search_rounded, size: 20),
                      label: const Text('Ara'),
                          style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
            ),
          ),
          // Tab bar
          DefaultTabController(
            length: 2,
            initialIndex: widget.initialTabIndex,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: const [
                      Tab(text: 'Arama Sonuçları'),
                      Tab(text: 'Editör Seçimi'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Arama sonuçları
                        _searchResults.isEmpty && !_isLoading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Arama yapın',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final place = _searchResults[index];
                                  final isEditorChoice = place['isEditorChoice'] == true;
                                  return _buildPlaceCard(
                                    place: place,
                                    isEditorChoice: isEditorChoice,
                                    onToggle: () => _toggleEditorChoice(
                                      place['placeId'],
                                      isEditorChoice,
                                    ),
                                  );
                                },
                              ),

                        // Editör seçimi mekanlar
                        _isLoadingEditorChoice
                            ? const Center(child: CircularProgressIndicator())
                            : _editorChoicePlaces.isEmpty
                                ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                                          Icons.star_border,
              size: 64,
                                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
                                          'Henüz editör seçimi mekan yok',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: theme.textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadEditorChoicePlaces,
                                    child: ListView.builder(
                                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                                      itemCount: _editorChoicePlaces.length,
                                      itemBuilder: (context, index) {
                                        final place = _editorChoicePlaces[index];
                                        return _buildPlaceCard(
                                          place: {
                                            'placeId': place['externalId']?.toString().replaceFirst('google_', '') ?? '',
                                            'name': place['name'] ?? 'Mekan',
                                            'address': place['address'] ?? '',
                                            'rating': place['rating'],
                                            'latitude': place['latitude'],
                                            'longitude': place['longitude'],
                                            'isEditorChoice': true,
                                          },
                                          isEditorChoice: true,
                                          onToggle: () => _toggleEditorChoice(
                                            place['externalId']?.toString().replaceFirst('google_', '') ?? '',
                                            true,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard({
    required Map<String, dynamic> place,
    required bool isEditorChoice,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditorChoice
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8)),
          width: isEditorChoice ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isEditorChoice
                          ? [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)]
                          : [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (isEditorChoice ? AppTheme.primaryColor : const Color(0xFF10B981))
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isEditorChoice ? Icons.star_rounded : Icons.place_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place['name'] ?? 'Mekan',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.titleLarge?.color,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEditorChoice)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Editör Seçimi',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (place['address'] != null && (place['address'] as String).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place['address'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (place['rating'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
            Text(
                              (place['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Toggle button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    isEditorChoice ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isEditorChoice ? AppTheme.primaryColor : theme.textTheme.bodyMedium?.color,
                      size: 26,
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
}
