import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/place_visit_model.dart';
import '../../models/recommendation_model.dart';
import '../../providers/auth_provider.dart';
import 'recommendation_map_screen.dart';

class UserVisitsScreen extends StatefulWidget {
  const UserVisitsScreen({super.key});

  @override
  State<UserVisitsScreen> createState() => _UserVisitsScreenState();
}

class _UserVisitsScreenState extends State<UserVisitsScreen> {
  final ApiService _apiService = ApiService();
  List<PlaceVisitModel> _visits = [];
  bool _isLoading = true;
  String? _error;
  
  // Pagination
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasNext = false;
  bool _hasPrevious = false;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits({int? page}) async {
    if (page != null) {
      setState(() => _currentPage = page);
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getUserVisitsPaginated(
        page: _currentPage,
        size: _pageSize,
      );
      
      setState(() {
        _visits = (response['content'] as List)
            .map((json) => PlaceVisitModel.fromJson(json))
            .toList();
        _totalPages = response['totalPages'] ?? 0;
        _totalElements = response['totalElements'] ?? 0;
        _currentPage = response['currentPage'] ?? 0;
        _hasNext = response['hasNext'] ?? false;
        _hasPrevious = response['hasPrevious'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Az önce';
          }
          return '${difference.inMinutes} dakika önce';
        }
        return '${difference.inHours} saat önce';
      } else if (difference.inDays == 1) {
        return 'Dün ${DateFormat('HH:mm').format(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(date);
      }
    } catch (e) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.place;
    final cat = category.toLowerCase();
    if (cat.contains('restoran') || cat.contains('cafe') || cat.contains('kafe')) {
      return Icons.restaurant;
    } else if (cat.contains('park') || cat.contains('bahçe')) {
      return Icons.park;
    } else if (cat.contains('müze') || cat.contains('galeri')) {
      return Icons.museum;
    } else if (cat.contains('sinema') || cat.contains('tiyatro')) {
      return Icons.movie;
    } else if (cat.contains('alışveriş') || cat.contains('market')) {
      return Icons.shopping_bag;
    } else if (cat.contains('spor') || cat.contains('fitness')) {
      return Icons.fitness_center;
    } else {
      return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Son Gezdiklerim',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadVisits(),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata: $_error',
                        style: GoogleFonts.inter(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadVisits(),
                        child: const Text('Yeniden Dene'),
                      ),
                    ],
                  ),
                )
              : _visits.isEmpty
                  ? _buildEmptyState(theme)
                  : Column(
                      children: [
                        // İstatistik Banner
                        _buildStatsBanner(theme, isDark),
                        
                        // Liste
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => _loadVisits(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _visits.length,
                              itemBuilder: (context, index) {
                                return _buildVisitCard(_visits[index], theme, isDark, authProvider);
                              },
                            ),
                          ),
                        ),
                        
                        // Pagination
                        _buildPagination(theme, isDark),
                      ],
                    ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.place_outlined,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz ziyaret yok',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mekanları ziyaret ederek geçmişinizi oluşturun',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toplam Ziyaret',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalElements',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sayfa ${_currentPage + 1}/$_totalPages',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(PlaceVisitModel visit, ThemeData theme, bool isDark, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1F2937),
                  const Color(0xFF111827),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPlaceDetailsFromVisit(visit, authProvider);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(visit.placeCategory),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.placeName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.titleLarge?.color,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (visit.placeCategory != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 14,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  visit.placeCategory!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Rating
                    if (visit.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber,
                              Colors.amber.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
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
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              visit.rating!.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info Row
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(visit.visitedAt),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    if (visit.visitCount != null && visit.visitCount! > 1) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.repeat_rounded,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${visit.visitCount} kez ziyaret',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
                if (visit.review != null && visit.review!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visit.review!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme, bool isDark) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937)
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Önceki Sayfa
          IconButton(
            onPressed: _hasPrevious
                ? () => _loadVisits(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _hasPrevious
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          
          // Sayfa Numaraları
          ...List.generate(
            _totalPages > 5 ? 5 : _totalPages,
            (index) {
              int pageNum;
              if (_totalPages <= 5) {
                pageNum = index;
              } else if (_currentPage < 3) {
                pageNum = index;
              } else if (_currentPage > _totalPages - 4) {
                pageNum = _totalPages - 5 + index;
              } else {
                pageNum = _currentPage - 2 + index;
              }
              
              final isCurrentPage = pageNum == _currentPage;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: isCurrentPage
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _loadVisits(page: pageNum),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${pageNum + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isCurrentPage
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCurrentPage
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 8),
          // Sonraki Sayfa
          IconButton(
            onPressed: _hasNext
                ? () => _loadVisits(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _hasNext
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPlaceDetailsFromVisit(PlaceVisitModel visit, AuthProvider authProvider) async {
    Map<String, dynamic>? details;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    final String finalPlaceId = visit.placeExternalId ?? '';

    if (finalPlaceId.isNotEmpty) {
      try {
        details = await _apiService.getPlaceDetails(finalPlaceId);
        debugPrint('✅ Place details alındı: ${details != null ? "Var" : "Yok"}');
        if (details != null) {
          debugPrint('📸 Photos: ${details['photos'] != null ? (details['photos'] as List).length : 0}');
          debugPrint('💬 Reviews: ${details['reviews'] != null ? (details['reviews'] as List).length : 0}');
        }
      } catch (e) {
        debugPrint('❌ Place details hatası: $e');
      }
    } else {
      debugPrint('⚠️ Place ID boş olduğundan detay alınamadı');
    }

    if (!context.mounted) return;
    Navigator.pop(context); // Loading dialog'u kapat

    if (details == null) {
      // Fallback data - visit'ten gelen bilgilerle modal göster
      details = {
        'name': visit.placeName,
        'category': visit.placeCategory ?? 'Mekan',
        'latitude': visit.latitude,
        'longitude': visit.longitude,
        'externalId': visit.placeExternalId,
        'rating': visit.rating?.toDouble(),
        'address': null,
        'tags': visit.placeCategory != null ? [visit.placeCategory!] : null,
        'phone': null,
        'website': null,
        'photos': null,
        'reviews': null,
        'isOpen': null,
        'userRatingsTotal': null,
      };
    } else {
      // API'den gelen detayları visit bilgileriyle birleştir
      details['name'] ??= visit.placeName;
      details['category'] ??= visit.placeCategory ?? 'Mekan';
      details['latitude'] ??= visit.latitude;
      details['longitude'] ??= visit.longitude;
      details['externalId'] = visit.placeExternalId;
      details['rating'] ??= visit.rating?.toDouble();
      
      if (details['tags'] == null && visit.placeCategory != null) {
        details['tags'] = [visit.placeCategory!];
      }
    }

    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlaceDetailsModalFromVisit(
        placeData: details!,
        placeId: finalPlaceId,
      ),
    );
  }
}

/// Mekan detay modal widget'ı (Visit'ten) - Kameradaki detaylı modal ile aynı
class _PlaceDetailsModalFromVisit extends StatefulWidget {
  final Map<String, dynamic> placeData;
  final String placeId;

  const _PlaceDetailsModalFromVisit({
    required this.placeData,
    required this.placeId,
  });

  @override
  State<_PlaceDetailsModalFromVisit> createState() => _PlaceDetailsModalFromVisitState();
}

class _PlaceDetailsModalFromVisitState extends State<_PlaceDetailsModalFromVisit> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey[300],
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
                              color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fotoğraflar',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F1B2E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${photos.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
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
                              final photoUrl = photo['url'] as String? ?? 
                                             (photo is Map ? photo['url'] as String? : null);
                              final photoRef = photo['photoReference'] as String? ?? 
                                            (photo is Map ? photo['photoReference'] as String? : null);
                              
                              String? finalUrl = photoUrl;
                              if ((finalUrl == null || finalUrl.isEmpty) && photoRef != null && photoRef.isNotEmpty) {
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
                                            color: isDark ? const Color(0xFF1F2937) : Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: isDark ? const Color(0xFF1F2937) : Colors.grey[200],
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: isDark ? Colors.white54 : Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
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

                  // Address
                  if (address != null && address.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.location_on_rounded,
                      iconColor: AppTheme.primaryColor,
                      title: 'Adres',
                      content: address,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ] else if (widget.placeData['latitude'] != null && widget.placeData['longitude'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.location_on_rounded,
                      iconColor: AppTheme.primaryColor,
                      title: 'Konum',
                      content: 'Enlem: ${widget.placeData['latitude']?.toStringAsFixed(6)}\nBoylam: ${widget.placeData['longitude']?.toStringAsFixed(6)}',
                      isDark: isDark,
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
                        color: isDark ? Colors.white : const Color(0xFF0F1B2E),
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ] else if (category.isNotEmpty && category != 'Mekan') ...[
                    Text(
                      'Kategoriler',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F1B2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Phone
                  if (phone != null && phone.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.phone_rounded,
                      iconColor: const Color(0xFF22C55E),
                      title: 'Telefon',
                      content: phone,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Website
                  if (website != null && website.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Web Sitesi',
                      content: website,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Reviews - Profesyonel tasarım
                  if (reviews != null && reviews.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.reviews_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yorumlar',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F1B2E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${reviews.length}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
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
                            colors: isDark
                                ? [
                                    const Color(0xFF1F2937),
                                    const Color(0xFF111827),
                                  ]
                                : [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[200]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                                          color: isDark ? Colors.white : const Color(0xFF0F1B2E),
                                        ),
                                      ),
                                      if (relativeTime != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          relativeTime,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.6)
                                                : const Color(0xFF64748B),
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
                                  color: isDark
                                      ? const Color(0xFF111827)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey[100]!,
                                  ),
                                ),
                                child: Text(
                                  reviewText,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : const Color(0xFF1E293B),
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
              color: isDark ? const Color(0xFF111827) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFF1E3A5F),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Kapat',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1E3A5F),
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
                      final recModel = RecommendationModel(
                        id: 0,
                        name: widget.placeData['name'] as String? ?? 'Mekan',
                        description: widget.placeData['description'] as String?,
                        latitude: (widget.placeData['latitude'] as num?)?.toDouble() ?? 0.0,
                        longitude: (widget.placeData['longitude'] as num?)?.toDouble() ?? 0.0,
                        address: widget.placeData['address'] as String?,
                        category: widget.placeData['category'] as String?,
                        tags: widget.placeData['tags'] != null
                            ? List<String>.from(widget.placeData['tags'] as List)
                            : null,
                        rating: widget.placeData['rating'] != null
                            ? (widget.placeData['rating'] as num).toDouble()
                            : null,
                        imageUrl: widget.placeData['imageUrl'] as String?,
                        website: widget.placeData['website'] as String?,
                        phone: widget.placeData['phone'] as String?,
                        externalId: widget.placeData['externalId'] as String? ?? widget.placeId,
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecommendationMapScreen(
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
    required bool isDark,
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
            colors: isDark
                ? [
                    const Color(0xFF1F2937),
                    const Color(0xFF111827),
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F1B2E),
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

