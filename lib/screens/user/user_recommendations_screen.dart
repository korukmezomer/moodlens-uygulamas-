import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/recommendation_model.dart';
import '../../models/place_visit_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/app_config.dart';
import 'recommendation_map_screen.dart';
import 'user_visits_screen.dart';
import 'user_profile_screen.dart';
import 'user_profile_view_screen.dart';
import 'user_messages_screen.dart';
import 'story_creation_screen.dart';
import 'package:image_picker/image_picker.dart';

class UserRecommendationsScreen extends StatefulWidget {
  final VoidCallback? onCameraTap;
  final VoidCallback? onPlacesTap;
  final VoidCallback? onHistoryTap;
  
  const UserRecommendationsScreen({
    super.key, 
    this.onCameraTap,
    this.onPlacesTap,
    this.onHistoryTap,
  });

  @override
  State<UserRecommendationsScreen> createState() => _UserRecommendationsScreenState();
}

class _UserRecommendationsScreenState extends State<UserRecommendationsScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  List<PlaceVisitModel> _recentVisits = [];
  List<dynamic> _stories = [];
  List<dynamic> _myStories = [];
  bool _isLoading = true;
  bool _isLoadingStories = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadStories();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Son gittiği yerleri yükle (en son 5)
      final visitsJson = await _apiService.getUserVisits();
      final visits = visitsJson
          .map((json) => PlaceVisitModel.fromJson(json))
          .take(5)
          .toList();
      
      setState(() {
        _recentVisits = visits;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Veri yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStories() async {
    setState(() => _isLoadingStories = true);
    try {
      final stories = await _apiService.getFriendsStories();
      final myStories = await _apiService.getMyStories();
      setState(() {
        _stories = stories;
        _myStories = myStories;
        _isLoadingStories = false;
      });
    } catch (e) {
      debugPrint('❌ Story yüklenirken hata: $e');
      setState(() => _isLoadingStories = false);
    }
  }

  Future<void> _createStory() async {
    // Instagram mantığı: Her zaman yeni story paylaşabilirsiniz
    // Eğer kendi story'si varsa, önce görüntüleme ekranına git
    if (_myStories.isNotEmpty) {
      final myStory = _myStories[0];
      await _viewMyStory(myStory);
    } else {
      // Story yoksa, direkt oluşturma ekranına git
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StoryCreationScreen(),
        ),
      );
      
      // Story paylaşıldıysa stories'i yenile
      if (result == true) {
        await _loadStories();
      }
    }
  }

  Future<void> _viewMyStory(Map<String, dynamic> story) async {
    final storyId = story['id'] as int? ?? 0;
    final userId = story['userId'] as int? ?? story['user']?['id'] as int? ?? 0;

    // Kendi tüm story'lerini al (Instagram mantığı)
    List<dynamic> myStories = List.from(_myStories);
    
    // Tarihe göre sırala (en yeni önce)
    myStories.sort((a, b) {
      final aCreated = a['createdAt'] as String? ?? '';
      final bCreated = b['createdAt'] as String? ?? '';
      return bCreated.compareTo(aCreated);
    });

    // Tıklanan story'nin index'ini bul
    int initialIndex = myStories.indexWhere((s) => (s['id'] as int? ?? 0) == storyId);
    if (initialIndex == -1) initialIndex = 0;

    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black,
        builder: (context) => _StoryViewer(
          stories: myStories,
          initialIndex: initialIndex,
          userId: userId,
          isOwnStory: true, // Kendi story'si olduğunu belirt
          onStoryDeleted: () {
            // Story silindikten sonra listeyi yenile
            _loadData();
          },
          onStoryClosed: () {
            // Story viewer'dan çıkıldığında listeyi yenile
            _loadStories();
          },
        ),
      );
    }
  }

  Future<void> _viewStory(Map<String, dynamic> story) async {
    final storyId = story['id'] as int? ?? 0;
    final userId = story['userId'] as int? ?? story['user']?['id'] as int? ?? 0;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isOwnStory = currentUser?.userId == userId;

    // Kullanıcının tüm story'lerini al (Instagram mantığı)
    List<dynamic> userStories = [];
    try {
      // Önce mevcut story'leri kontrol et
      final allStories = _stories + _myStories;
      userStories = allStories.where((s) {
        final sUserId = s['userId'] as int? ?? s['user']?['id'] as int? ?? 0;
        return sUserId == userId;
      }).toList();
      
      // Tarihe göre sırala (en yeni önce)
      userStories.sort((a, b) {
        final aCreated = a['createdAt'] as String? ?? '';
        final bCreated = b['createdAt'] as String? ?? '';
        return bCreated.compareTo(aCreated);
      });
      
      // Tıklanan story'nin index'ini bul
      int initialIndex = userStories.indexWhere((s) => (s['id'] as int? ?? 0) == storyId);
      if (initialIndex == -1) initialIndex = 0;
      
      // İlk story'yi görüntüleme olarak işaretle (sadece kendi story'si değilse)
      if (!isOwnStory && userStories.isNotEmpty) {
      try {
        await _apiService.viewStory(storyId);
      } catch (e) {
        // Hata olsa bile devam et
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black,
        builder: (context) => _StoryViewer(
            stories: userStories,
            initialIndex: initialIndex,
          userId: userId,
          isOwnStory: isOwnStory,
            onStoryDeleted: () {
              // Story silindikten sonra listeyi yenile
              _loadData();
            },
            onStoryClosed: () {
              // Story viewer'dan çıkıldığında listeyi yenile (kırmızı border kaybolsun)
              _loadStories();
            },
          ),
        );
      }
    } catch (e) {
      // Hata durumunda tek story göster
      if (mounted) {
        showDialog(
          context: context,
          barrierColor: Colors.black,
          builder: (context) => _StoryViewer(
            stories: [story],
            initialIndex: 0,
            userId: userId,
            isOwnStory: isOwnStory,
        ),
      );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Stories Section
                  SliverToBoxAdapter(
                    child: _buildStoriesSection(isDark, user),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Modern User Card with gradient
                          _buildUserCard(user, isDark),
                          
                          const SizedBox(height: 32),
                          
                          // Premium Main Action Button
                          _buildMainActionButton(isDark),
                          
                          const SizedBox(height: 32),
                          
                          // Quick Actions Grid
                          _buildQuickActionsGrid(isDark),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  
                  // Son Gittiği Yerler Section
                  if (_recentVisits.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildRecentVisitsSection(isDark),
                    ),
                  
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserProfileScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E3A5F),
                      const Color(0xFF0F1B2E),
                      const Color(0xFF1E3A5F),
                    ]
                  : [
                      const Color(0xFF1E3A5F),
                      const Color(0xFF0F1B2E),
                      const Color(0xFF2D3748),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with gradient - kırmızı çerçeve eğer story varsa
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _myStories.isNotEmpty
                      ? LinearGradient(
                          colors: [
                            Colors.red,
                            const Color(0xFFEC4899),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                  border: Border.all(
                    color: _myStories.isNotEmpty
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (user?.username ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş geldin,',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.username ?? 'Kullanıcı',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MOOD LENS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
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
  }

  Widget _buildMainActionButton(bool isDark) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.85),
            AppTheme.primaryColor.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onCameraTap,
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Duygu Analizi Yap',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.2,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fotoğrafını çek, ruh halini tespit et\nve sana özel mekan önerileri al',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Başla',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
  }

  Widget _buildQuickActionsGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Erişim',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F1B2E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.map_rounded,
                title: 'Harita',
                subtitle: 'Mekanları keşfet',
                color: const Color(0xFF3B82F6),
                onTap: widget.onPlacesTap,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.history_rounded,
                title: 'Geçmiş',
                subtitle: 'Ziyaretlerin',
                color: const Color(0xFF10B981),
                onTap: widget.onHistoryTap,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F1B2E),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentVisitsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937)
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Gittiğin Yerler',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F1B2E),
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserVisitsScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    'Tümünü Gör',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste
          SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _recentVisits.length,
              itemBuilder: (context, index) {
                final visit = _recentVisits[index];
                return _buildVisitCard(visit, isDark);
              },
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVisitCard(PlaceVisitModel visit, bool isDark) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPlaceDetailsFromVisit(visit);
          },
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF111827),
                  const Color(0xFF1F2937),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        border: Border.all(
          color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey[200]!,
          width: 1.5,
        ),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                  // Görsel alanı (placeholder veya gradient)
                    Container(
                    height: 140,
                    width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.9),
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Kategori ikonu (ortada, büyük)
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                      ),
                      child: Icon(
                        _getCategoryIcon(visit.placeCategory ?? 'Mekan'),
                        color: Colors.white,
                              size: 32,
                      ),
                    ),
                        ),
                        // Rating badge (sağ üst)
                    if (visit.rating != null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                                    visit.rating!.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                      letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                          ),
                        // Gradient overlay (alt)
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
                                  isDark
                                      ? const Color(0xFF1F2937).withValues(alpha: 0.95)
                                      : Colors.white.withValues(alpha: 0.95),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // İçerik alanı
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                // Mekan Adı
                Text(
                  visit.placeName,
                  style: GoogleFonts.inter(
                            fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F1B2E),
                            height: 1.2,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                        // Kategori ve Tarih
                        Row(
                          children: [
                            // Kategori badge
                if (visit.placeCategory != null)
                              Flexible(
                                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor.withValues(alpha: 0.2),
                                        AppTheme.primaryColor.withValues(alpha: 0.15),
                                      ],
                                    ),
                      borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(visit.placeCategory!),
                                        size: 12,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                    child: Text(
                      visit.placeCategory!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                                            fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                                            letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Tarih bilgisi
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[100]!,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                                size: 13,
                      color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                              Text(
                        _formatVisitDate(visit.visitedAt),
                        style: GoogleFonts.inter(
                                  fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                                      ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF64748B),
                                  letterSpacing: -0.2,
                        ),
                              ),
                            ],
                      ),
                    ),
                  ],
                    ),
                ),
              ],
              ),
            ),
          ),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} dakika önce';
        }
        return '${difference.inHours} saat önce';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatVisitDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Bugün';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showPlaceDetailsFromVisit(PlaceVisitModel visit) async {
    Map<String, dynamic>? details;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      ),
    );

    // PlaceId'yi al ve formatla
    String finalPlaceId = visit.placeExternalId ?? '';
    
    // place_0_ prefix'ini kaldır (backend'de handle ediliyor ama frontend'de de kaldıralım)
    if (finalPlaceId.startsWith('place_0_')) {
      finalPlaceId = finalPlaceId.replaceFirst('place_0_', '');
    }

    try {
      if (finalPlaceId.isNotEmpty) {
        // Backend'e orijinal formatı gönder (backend prefix'leri handle ediyor)
        details = await _apiService.getPlaceDetails(visit.placeExternalId ?? finalPlaceId);
        debugPrint('✅ Place details alındı: ${details != null ? "Var" : "Yok"}');
        debugPrint('🔍 Place ID: ${visit.placeExternalId} -> Processed: $finalPlaceId');
        if (details != null) {
          debugPrint('📸 Photos: ${details['photos'] != null ? (details['photos'] as List).length : 0}');
          debugPrint('💬 Reviews: ${details['reviews'] != null ? (details['reviews'] as List).length : 0}');
        }
      }
    } catch (e) {
      debugPrint('❌ Place details hatası: $e');
    }

    if (!context.mounted) return;
    Navigator.pop(context); // Loading dialog'u kapat

    // Fallback: Visit model'den göster - API'den veri gelmediyse (kamera ekranındaki mantık gibi)
    if (details == null) {
      // Category'yi tag olarak hazırla
      List<String>? tagsList;
      if (visit.placeCategory != null && visit.placeCategory!.isNotEmpty) {
        tagsList = [visit.placeCategory!];
      }
      
      details = {
        'name': visit.placeName.isNotEmpty ? visit.placeName : 'Mekan',
        'category': visit.placeCategory ?? 'Mekan',
        'latitude': visit.latitude,
        'longitude': visit.longitude,
        'externalId': finalPlaceId,
        'rating': visit.rating?.toDouble(),
        'address': null, // API'den gelmediyse null bırak, modal içinde koordinat gösterilecek
        'tags': tagsList,
        'phone': null,
        'website': null,
        'photos': null,
        'reviews': null,
        'isOpen': null,
        'userRatingsTotal': null,
      };
      debugPrint('📋 Fallback data oluşturuldu:');
      debugPrint('   Name: ${details['name']}');
      debugPrint('   Category: ${details['category']}');
      debugPrint('   Tags: ${details['tags']}');
      debugPrint('   Rating: ${details['rating']}');
      debugPrint('   Lat: ${details['latitude']}, Lng: ${details['longitude']}');
    } else {
      // API'den veri geldi, eksik alanları visit model'den doldur
      details['name'] ??= visit.placeName.isNotEmpty ? visit.placeName : 'Mekan';
      details['category'] ??= visit.placeCategory ?? 'Mekan';
      details['latitude'] ??= visit.latitude;
      details['longitude'] ??= visit.longitude;
      details['externalId'] = finalPlaceId;
      details['rating'] ??= visit.rating?.toDouble();
      
      // tags yoksa category'den oluştur
      if (details['tags'] == null && visit.placeCategory != null && visit.placeCategory!.isNotEmpty) {
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

  Widget _buildStoriesSection(bool isDark, UserModel? user) {
    if (_isLoadingStories) {
      return const SizedBox.shrink();
    }

    // Story'leri kullanıcıya göre grupla
    Map<int, List<dynamic>> storiesByUser = {};
    for (var story in _stories) {
      final userId = story['userId'] as int? ?? story['user']?['id'] as int? ?? 0;
      if (!storiesByUser.containsKey(userId)) {
        storiesByUser[userId] = [];
      }
      storiesByUser[userId]!.add(story);
    }

    final uniqueUsers = storiesByUser.keys.toList();
    final currentUserId = user?.userId ?? 0; // Closure dışında tanımla

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: uniqueUsers.length + 1, // +1 for "Add Story" button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Add Story Button - kendi story'si varsa kırmızı çerçeve, profil fotoğrafı göster
            final hasMyStory = _myStories.isNotEmpty;
            final userProfilePicture = user?.profilePictureUrl;
            final username = user?.username ?? 'Kullanıcı';
            return Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _createStory,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Instagram gibi: Kendi story'si için gradient border
                        gradient: hasMyStory
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFE1306C), // Instagram kırmızısı
                                  const Color(0xFFF77737), // Turuncu
                                  const Color(0xFFFCAF45), // Sarı
                                  const Color(0xFFFFDC80), // Açık sarı
                                ],
                              )
                            : null,
                        color: hasMyStory ? null : Colors.transparent,
                      ),
                      padding: EdgeInsets.all(hasMyStory ? 2.5 : 0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                      ),
                        padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        ),
                          child: Stack(
                            children: [
                              // Profil fotoğrafı veya avatar
                              userProfilePicture != null && userProfilePicture.isNotEmpty
                                  ? ClipOval(
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: Image.network(
                                        userProfilePicture.startsWith('http')
                                            ? userProfilePicture
                                            : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$userProfilePicture',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                                style: GoogleFonts.inter(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                              // + ikonu (sağ alt köşe)
                              Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                                child: const Icon(
                          Icons.add_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hikayen',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }

          final userId = uniqueUsers[index - 1];
          final userStories = storiesByUser[userId]!;
          final firstStory = userStories[0];
          final storyUser = firstStory['user'] as Map<String, dynamic>? ?? {};
          // Username'i hem story['username'] hem de story['user']['username'] şeklinde kontrol et
          final username = firstStory['username'] as String? ?? 
                          storyUser['username'] as String? ?? 
                          'Kullanıcı';
          final profilePictureUrl = storyUser['profilePictureUrl'] as String? ?? 
                                   firstStory['profilePictureUrl'] as String?;
          final imageUrl = firstStory['imageUrl'] as String? ?? '';
          final storyUserId = firstStory['userId'] as int? ?? storyUser['id'] as int? ?? 0;
          
          // Instagram mantığı: Kendi story'si kırmızı border olmamalı
          final isOwnStory = storyUserId == currentUserId;
          
          // Check if any story is viewed (sadece başkalarının story'leri için)
          // Instagram mantığı: Eğer tüm story'ler görüldüyse border yok
          bool hasUnviewedStory = !isOwnStory && userStories.any((s) {
            // Backend'den gelen hasViewed bilgisini kontrol et
            final hasViewed = s['hasViewed'] as bool? ?? false;
            return !hasViewed;
          });

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _viewStory(firstStory),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Instagram gibi: Görülmemiş story'ler için gradient border
                      gradient: hasUnviewedStory
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFE1306C), // Instagram kırmızısı
                                const Color(0xFFF77737), // Turuncu
                                const Color(0xFFFCAF45), // Sarı
                                const Color(0xFFFFDC80), // Açık sarı
                              ],
                            )
                          : null,
                      color: hasUnviewedStory ? null : Colors.transparent,
                    ),
                    padding: EdgeInsets.all(hasUnviewedStory ? 2.5 : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                    ),
                      padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      ),
                      child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                          ? ClipOval(
                              child: SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                              child: Image.network(
                                profilePictureUrl.startsWith('http')
                                    ? profilePictureUrl
                                    : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                    child: Text(
                                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                              child: Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  username,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Mekan detay modal widget'ı (Visit'ten)
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
    final latitude = widget.placeData['latitude'] as num?;
    final longitude = widget.placeData['longitude'] as num?;
    
    debugPrint('🔍 Modal build - Name: $name, Category: $category, Rating: $rating');
    debugPrint('🔍 Modal build - Address: $address, Lat: $latitude, Lng: $longitude');
    debugPrint('🔍 Modal build - Photos: ${photos?.length ?? 0}, Reviews: ${reviews?.length ?? 0}, Tags: ${tags?.length ?? 0}');
    debugPrint('🔍 Modal build - Phone: $phone, Website: $website');
    debugPrint('🔍 Modal build - Widget placeData keys: ${widget.placeData.keys.toList()}');

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
                mainAxisSize: MainAxisSize.min,
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
                  ] else if (latitude != null && longitude != null) ...[
                    // Koordinat bilgisi göster
                    _buildInfoCard(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF1E3A5F),
                      title: 'Konum',
                      content: 'Enlem: ${latitude.toStringAsFixed(6)}\nBoylam: ${longitude.toStringAsFixed(6)}',
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
                  ] else if (category.isNotEmpty) ...[
                    // Tags yoksa category göster
                    Text(
                      'Kategori',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F1B2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A5F),
                        ),
                      ),
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
                      // externalId'yi ekle
                      if (widget.placeId.isNotEmpty) {
                        placeJson['externalId'] = widget.placeId;
                      }
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
                color: Colors.grey[400],
                size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryViewer extends StatefulWidget {
  final List<dynamic> stories; // Birden fazla story desteği
  final int initialIndex; // Başlangıç story index'i
  final int userId;
  final bool isOwnStory;
  final VoidCallback? onStoryDeleted;
  final VoidCallback? onStoryClosed;

  const _StoryViewer({
    required this.stories,
    this.initialIndex = 0,
    required this.userId,
    this.isOwnStory = false,
    this.onStoryDeleted,
    this.onStoryClosed,
  });

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _commentsScrollController = ScrollController();
  late final PageController _pageController;
  
  int _currentStoryIndex = 0;
  List<dynamic> _comments = [];
  bool _isLoadingComments = false;
  bool _showComments = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoadingLike = false;
  bool _isTyping = false;
  List<dynamic> _storyMessages = []; // Story mesajları
  bool _isLoadingStoryMessages = false;
  List<dynamic> _viewers = [];
  int _viewCount = 0;
  bool _isLoadingViewers = false;
  bool _showViewers = false;
  
  // Progress bar'lar için (her story için bir tane)
  List<AnimationController> _progressControllers = [];
  List<Animation<double>> _progressAnimations = [];
  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Her story için progress controller oluştur
    for (int i = 0; i < widget.stories.length; i++) {
      final controller = AnimationController(
        duration: _storyDuration,
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);
      _progressControllers.add(controller);
      _progressAnimations.add(animation);
    }
    
    // İlk story'yi yükle
    _loadCurrentStoryData();
    _startCurrentStoryProgress();
    
    // Mesaj input focus listener
    _messageController.addListener(() {
      final wasTyping = _isTyping;
      _isTyping = _messageController.text.isNotEmpty;
      if (wasTyping != _isTyping) {
        if (_isTyping) {
          _pauseCurrentProgress();
        } else {
          _resumeCurrentProgress();
        }
      }
    });
  }
  
  void _loadCurrentStoryData() {
    final currentStory = widget.stories[_currentStoryIndex];
    final storyId = currentStory['id'] as int? ?? 0;
    
    // Story görüntülendiğinde viewStory API'sini çağır (sadece kendi story'si değilse)
    if (!widget.isOwnStory && storyId > 0) {
      _apiService.viewStory(storyId).catchError((e) {
        // Hata olsa bile devam et
      });
    }
    
    _loadComments(storyId);
    _loadLikeInfo(storyId);
    if (widget.isOwnStory) {
      _loadViewers(storyId);
      _loadStoryMessages(storyId);
    }
  }
  
  void _startCurrentStoryProgress() {
    if (_currentStoryIndex < _progressControllers.length) {
      // Önceki story'lerin progress'ini tamamla
      for (int i = 0; i < _currentStoryIndex; i++) {
        if (_progressControllers[i].value < 1.0) {
          _progressControllers[i].value = 1.0;
        }
        _progressControllers[i].stop();
      }
      
      // Sonraki story'lerin progress'ini sıfırla
      for (int i = _currentStoryIndex + 1; i < _progressControllers.length; i++) {
        _progressControllers[i].value = 0.0;
        _progressControllers[i].stop();
      }
      
      // Şu anki story'nin progress'ini başlat
      final controller = _progressControllers[_currentStoryIndex];
      controller.reset();
      controller.forward();
      
      // Listener'ı temizle ve yeniden ekle
      controller.removeStatusListener(_progressStatusListener);
      controller.addStatusListener(_progressStatusListener);
    }
  }
  
  void _progressStatusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }
  
  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      _currentStoryIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _closeStoryViewer();
    }
  }
  
  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _currentStoryIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _closeStoryViewer();
    }
  }
  
  void _closeStoryViewer() {
    if (mounted) {
        Navigator.pop(context);
      // Story viewer'dan çıkıldığında callback çağır
      if (widget.onStoryClosed != null) {
        widget.onStoryClosed!();
      }
    }
  }
  
  void _pauseCurrentProgress() {
    if (_currentStoryIndex < _progressControllers.length) {
      _progressControllers[_currentStoryIndex].stop();
    }
  }
  
  void _resumeCurrentProgress() {
    if (_currentStoryIndex < _progressControllers.length) {
      final controller = _progressControllers[_currentStoryIndex];
      if (!controller.isAnimating && controller.value < 1.0) {
        controller.forward();
      }
    }
  }
  
  @override
  void dispose() {
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _commentController.dispose();
    _messageController.dispose();
    _commentsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeInfo(int storyId) async {
    try {
      if (storyId > 0) {
        final isLiked = await _apiService.checkStoryLike(storyId);
        final likeCount = await _apiService.getStoryLikeCount(storyId);
        setState(() {
          _isLiked = isLiked;
          _likeCount = likeCount;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadViewers(int storyId) async {
    if (storyId > 0) {
      setState(() => _isLoadingViewers = true);
      try {
        final viewers = await _apiService.getStoryViewers(storyId);
        setState(() {
          _viewers = viewers;
          _viewCount = viewers.length;
          _isLoadingViewers = false;
        });
      } catch (e) {
        setState(() => _isLoadingViewers = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;
    
    final currentStory = widget.stories[_currentStoryIndex];
    final storyId = currentStory['id'] as int? ?? 0;
    
    setState(() => _isLoadingLike = true);
    try {
      if (storyId > 0) {
        if (_isLiked) {
          await _apiService.unlikeStory(storyId);
          setState(() {
            _isLiked = false;
            _likeCount = _likeCount > 0 ? _likeCount - 1 : 0;
          });
        } else {
          await _apiService.likeStory(storyId);
          setState(() {
            _isLiked = true;
            _likeCount = _likeCount + 1;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isLoadingLike = false);
    }
  }

  Future<void> _loadStoryMessages(int storyId) async {
    if (_isLoadingStoryMessages) return;
    
    setState(() => _isLoadingStoryMessages = true);
    try {
      if (storyId > 0) {
        final messages = await _apiService.getStoryMessages(storyId);
        if (mounted) {
          setState(() {
            _storyMessages = messages;
            _isLoadingStoryMessages = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Story mesajları yüklenirken hata: $e');
      if (mounted) {
        setState(() => _isLoadingStoryMessages = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentStory = widget.stories[_currentStoryIndex];
    final storyId = currentStory['id'] as int? ?? 0;
    final content = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _isTyping = false;
    });
    _resumeCurrentProgress();

    try {
      // Story'ye özel mesaj gönder
      await _apiService.sendStoryMessage(storyId, content);
      
      // Story sahibi ise mesajları yeniden yükle
      if (widget.isOwnStory) {
        _loadStoryMessages(storyId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mesaj gönderildi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadComments(int storyId) async {
    setState(() => _isLoadingComments = true);
    try {
      if (storyId > 0) {
        final comments = await _apiService.getStoryComments(storyId);
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      } else {
        setState(() => _isLoadingComments = false);
      }
    } catch (e) {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final currentStory = widget.stories[_currentStoryIndex];
    final storyId = currentStory['id'] as int? ?? 0;
    final content = _commentController.text.trim();
    _commentController.clear();
    _pauseCurrentProgress();

    try {
      if (storyId > 0) {
        await _apiService.addStoryComment(storyId, content);
        await _loadComments(storyId);
        if (_commentsScrollController.hasClients) {
          _commentsScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenemedi: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      _resumeCurrentProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text('Story bulunamadı', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    
    final currentStory = widget.stories[_currentStoryIndex];
    final storyId = currentStory['id'] as int? ?? 0;
    final storyUser = currentStory['user'] as Map<String, dynamic>? ?? {};
    final username = storyUser['username'] as String? ?? 
                   currentStory['username'] as String? ?? 
                   'Kullanıcı';
    final profilePictureUrl = storyUser['profilePictureUrl'] as String?;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Image - PageView ile birden fazla story
          PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: (index) {
              // Önceki story'nin progress'ini durdur
              if (_currentStoryIndex < _progressControllers.length) {
                _progressControllers[_currentStoryIndex].stop();
              }
              
              setState(() {
                _currentStoryIndex = index;
              });
              
              _loadCurrentStoryData();
              _startCurrentStoryProgress();
            },
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              final imageUrl = story['imageUrl'] as String? ?? '';
              
              return GestureDetector(
                // Instagram gibi: dokunduğunda duraklat, bıraktığında devam et
                onTapDown: (_) => _pauseCurrentProgress(),
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final tapX = details.globalPosition.dx;
                  
                  // Sol yarı - önceki story, sağ yarı - sonraki story
                  if (tapX < screenWidth / 2) {
                    _previousStory();
                  } else {
                    _nextStory();
                  }
                  _resumeCurrentProgress();
                },
                onTapCancel: () => _resumeCurrentProgress(),
                // Uzun basma ile de duraklat
                onLongPressStart: (_) => _pauseCurrentProgress(),
                onLongPressEnd: (_) => _resumeCurrentProgress(),
                onLongPressCancel: () => _resumeCurrentProgress(),
                child: SizedBox.expand(
                  child: imageUrl.isNotEmpty
                ? Image.network(
                          imageUrl.startsWith('http')
                              ? imageUrl
                              : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$imageUrl',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                ),
              );
            },
          ),
          // Progress bars (Instagram style - her story için bir tane) - EN ÜSTTE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(widget.stories.length, (index) {
                    final isCompleted = index < _currentStoryIndex;
                    
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(
                          right: index < widget.stories.length - 1 ? 2 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        child: Stack(
                          children: [
                            // Progress fill
                            AnimatedBuilder(
                              animation: _progressAnimations[index],
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: isCompleted 
                                      ? 1.0 
                                      : _progressAnimations[index].value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                    ),
                  ),
          ),
          // Top bar with user info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 48, // Progress bar için yer bırak
                bottom: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => _closeStoryViewer(),
                  ),
                  const SizedBox(width: 8),
                  // User info
                  Expanded(
                      child: GestureDetector(
                      onTap: () {
                        _closeStoryViewer();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileViewScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          // Profile picture
                          ClipOval(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                  ? Image.network(
                                      profilePictureUrl.startsWith('http')
                                          ? profilePictureUrl
                                          : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Username
                          Expanded(
                            child: Text(
                              username,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Kendi story'si ise silme butonu, değilse info butonu
                  if (widget.isOwnStory)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                      color: Colors.white,
                      onSelected: (value) async {
                        if (value == 'add') {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoryCreationScreen(),
                            ),
                          );
                          if (result == true && widget.onStoryDeleted != null) {
                            widget.onStoryDeleted!();
                          }
                        } else if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'Hikayeyi Sil',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                'Bu hikayeyi silmek istediğinize emin misiniz?',
                                style: GoogleFonts.inter(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(
                                    'İptal',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'Sil',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.errorRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            try {
                              final currentStory = widget.stories[_currentStoryIndex];
                              final currentStoryId = currentStory['id'] as int? ?? 0;
                              await _apiService.deleteStory(currentStoryId);
                              if (mounted) {
                                // Story'yi listeden kaldır
                                final newStories = List<dynamic>.from(widget.stories);
                                newStories.removeAt(_currentStoryIndex);
                                
                                if (newStories.isEmpty) {
                                  Navigator.pop(context);
                                  if (widget.onStoryDeleted != null) {
                                    widget.onStoryDeleted!();
                                  }
                                } else {
                                  // Yeni index'i ayarla
                                  if (_currentStoryIndex >= newStories.length) {
                                    _currentStoryIndex = newStories.length - 1;
                                  }
                                  // State'i güncelle
                                  setState(() {
                                    // Stories listesi güncellenemez çünkü final
                                    // Bu durumda pop yapıp yeniden açmak daha iyi
                                  });
                                  Navigator.pop(context);
                                  if (widget.onStoryDeleted != null) {
                                    widget.onStoryDeleted!();
                                  }
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hikaye silindi'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hikaye silinemedi: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'add',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Yeni Hikaye Ekle',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Hikayeyi Sil',
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileViewScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Comments section (Instagram style)
          if (_showComments)
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final isDark = themeProvider.isDarkMode;
                return Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.black.withValues(alpha: 0.95)
                          : Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Comments header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Yorumlar',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                            onPressed: () {
                              setState(() => _showComments = false);
                            },
                          ),
                        ],
                      ),
                    ),
                        Divider(
                          color: isDark 
                              ? Colors.white24 
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                    // Comments list
                    Expanded(
                      child: _isLoadingComments
                          ? Center(
                              child: CircularProgressIndicator(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            )
                          : _comments.isEmpty
                              ? Center(
                                  child: Text(
                                    'Henüz yorum yok',
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _commentsScrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = _comments[index];
                                    final username = comment['username'] as String? ?? 'Kullanıcı';
                                    final content = comment['content'] as String? ?? '';
                                    final profilePictureUrl = comment['profilePictureUrl'] as String?;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                                ? NetworkImage(
                                                    profilePictureUrl.startsWith('http')
                                                        ? profilePictureUrl
                                                        : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
                                                  ) as ImageProvider?
                                                : null,
                                            backgroundColor: AppTheme.primaryColor,
                                            child: profilePictureUrl == null || profilePictureUrl.isEmpty
                                                ? Text(
                                                    username[0].toUpperCase(),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  username,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  content,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: isDark ? Colors.white70 : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    // Comment input
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final isDarkInput = themeProvider.isDarkMode;
                        return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                            color: isDarkInput ? Colors.black : Colors.white,
                        border: Border(
                              top: BorderSide(
                                color: isDarkInput 
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                                  style: GoogleFonts.inter(
                                    color: isDarkInput ? Colors.white : Colors.black,
                                  ),
                              decoration: InputDecoration(
                                hintText: 'Yorum yaz...',
                                    hintStyle: GoogleFonts.inter(
                                      color: isDarkInput 
                                          ? Colors.white54 
                                          : Colors.black54,
                                    ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _addComment(),
                                  onTap: () => _pauseCurrentProgress(),
                              onChanged: (text) {
                                if (text.isNotEmpty) {
                                      _pauseCurrentProgress();
                                } else {
                                      _resumeCurrentProgress();
                                }
                              },
                            ),
                          ),
                          IconButton(
                                icon: Icon(
                                  Icons.send_rounded,
                                  color: isDarkInput ? Colors.white : Colors.black,
                                ),
                            onPressed: _addComment,
                          ),
                        ],
                      ),
                        );
                      },
                    ),
                  ],
                ),
              ),
                );
              },
            ),
          // Right side actions (Instagram style - like, comment buttons)
          if (!_showComments)
            Positioned(
              right: 12,
              bottom: 140, // Mesaj input'un üstünde
              child: Column(
                mainAxisSize: MainAxisSize.min,
                  children: [
                    // Like button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                          size: 32,
                      ),
                      onPressed: _isLoadingLike ? null : _toggleLike,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                    ),
                      const SizedBox(height: 4),
                    Text(
                      '$_likeCount',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ],
                    ),
                  const SizedBox(height: 24),
                    // Comment button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    IconButton(
                        icon: const Icon(
                        Icons.comment_outlined,
                        color: Colors.white,
                          size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _showComments = true;
                            _pauseCurrentProgress();
                        });
                      },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                    ),
                      const SizedBox(height: 4),
                    Text(
                      '${_comments.length}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      ),
                    ],
                    ),
                    // View count (only for own story)
                    if (widget.isOwnStory) ...[
                    const SizedBox(height: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      IconButton(
                          icon: const Icon(
                          Icons.remove_red_eye_rounded,
                          color: Colors.white,
                            size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _showViewers = !_showViewers;
                            if (_showViewers) {
                                _pauseCurrentProgress();
                            } else {
                                _resumeCurrentProgress();
                            }
                          });
                        },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                      ),
                        const SizedBox(height: 4),
                      Text(
                        '$_viewCount',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    ),
                  ],
                ],
              ),
            ),
          // Caption (Instagram style - bottom left, above message input)
          if (!_showComments)
            Builder(
              builder: (context) {
                final currentStory = widget.stories[_currentStoryIndex];
                final caption = currentStory['caption'] as String?;
                if (caption != null && caption.isNotEmpty) {
                  return Positioned(
                    left: 12,
                    bottom: 100, // Mesaj input'un üstünde
                    right: 80, // Sağ taraftaki butonlar için yer bırak
                        child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                          ),
                          child: Text(
                                caption,
                            style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                              color: Colors.white,
                                  height: 1.4,
                                  letterSpacing: -0.2,
                            ),
                                maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
          // Story mesajları (Instagram style - story'nin altında)
          if (widget.isOwnStory && _storyMessages.isNotEmpty && !_showComments)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
                        child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _storyMessages.map((message) {
                      final senderUsername = message['senderUsername'] as String? ?? 'Kullanıcı';
                      final content = message['content'] as String? ?? '';
                      final senderProfilePictureUrl = message['senderProfilePictureUrl'] as String?;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              Colors.white.withValues(alpha: 0.9),
                            ],
                          ),
                            borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: senderProfilePictureUrl != null && senderProfilePictureUrl.isNotEmpty
                                  ? NetworkImage(
                                      senderProfilePictureUrl.startsWith('http')
                                          ? senderProfilePictureUrl
                                          : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$senderProfilePictureUrl',
                                    ) as ImageProvider?
                                  : null,
                              backgroundColor: AppTheme.primaryColor,
                              child: senderProfilePictureUrl == null || senderProfilePictureUrl.isEmpty
                                  ? Text(
                                      senderUsername.isNotEmpty ? senderUsername[0].toUpperCase() : 'U',
                            style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderUsername,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                          ),
                                  const SizedBox(height: 2),
                                  Text(
                                    content,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                        ),
                      ),
                  ],
                ),
              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          // Message input (Instagram style - bottom with profile picture)
          if (!_showComments && !widget.isOwnStory)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
                child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  top: 12,
                ),
                  decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final currentUser = authProvider.user;
                    final currentUserProfilePicture = currentUser?.profilePictureUrl;
                    final currentUsername = currentUser?.username ?? 'Kullanıcı';
                    
                    return Row(
                      children: [
                        // Profile picture
                        ClipOval(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: currentUserProfilePicture != null && currentUserProfilePicture.isNotEmpty
                                ? Image.network(
                                    currentUserProfilePicture.startsWith('http')
                                        ? currentUserProfilePicture
                                        : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$currentUserProfilePicture',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
              child: Center(
                                          child: Text(
                                            currentUsername.isNotEmpty ? currentUsername[0].toUpperCase() : 'U',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        currentUsername.isNotEmpty ? currentUsername[0].toUpperCase() : 'U',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Message input
                        Expanded(
                          child: Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              final isDark = themeProvider.isDarkMode;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.black.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                                        style: GoogleFonts.inter(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontSize: 15,
                                        ),
                          decoration: InputDecoration(
                                          hintText: 'Send message...',
                                          hintStyle: GoogleFonts.inter(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.6)
                                                : Colors.black.withValues(alpha: 0.6),
                                            fontSize: 15,
                                          ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                                          isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                                        onTap: () => _pauseCurrentProgress(),
                                        onChanged: (text) {
                                          setState(() {
                                            _isTyping = text.isNotEmpty;
                                          });
                                          if (text.isNotEmpty) {
                                            _pauseCurrentProgress();
                                          } else {
                                            _resumeCurrentProgress();
                                          }
                                        },
                        ),
                      ),
                                    if (_isTyping)
                      IconButton(
                                        icon: Icon(
                                          Icons.send_rounded,
                                          color: isDark ? Colors.white : Colors.black,
                                          size: 20,
                                        ),
                        onPressed: _sendMessage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          // Viewers list (only for own story)
          if (_showViewers && widget.isOwnStory)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Viewers header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Görüntüleyenler',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$_viewCount',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _showViewers = false;
                                _resumeCurrentProgress();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    // Viewers list
                    Expanded(
                      child: _isLoadingViewers
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : _viewers.isEmpty
                              ? Center(
                                  child: Text(
                                    'Henüz görüntüleyen yok',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _viewers.length,
                                  itemBuilder: (context, index) {
                                    final viewer = _viewers[index];
                                    final viewerUser = viewer['viewer'] as Map<String, dynamic>? ?? viewer;
                                    final username = viewerUser['username'] as String? ?? 'Kullanıcı';
                                    final profilePictureUrl = viewerUser['profilePictureUrl'] as String?;
                                    final viewedAt = viewer['viewedAt'] as String?;
                                    
                                    String timeAgo = '';
                                    if (viewedAt != null) {
                                      try {
                                        final date = DateTime.parse(viewedAt);
                                        final now = DateTime.now();
                                        final difference = now.difference(date);
                                        
                                        if (difference.inMinutes < 1) {
                                          timeAgo = 'Az önce';
                                        } else if (difference.inMinutes < 60) {
                                          timeAgo = '${difference.inMinutes} dakika önce';
                                        } else if (difference.inHours < 24) {
                                          timeAgo = '${difference.inHours} saat önce';
                                        } else {
                                          timeAgo = '${difference.inDays} gün önce';
                                        }
                                      } catch (e) {
                                        timeAgo = viewedAt;
                                      }
                                    }
                                    
                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppTheme.primaryColor,
                                        backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                            ? NetworkImage(
                                                profilePictureUrl.startsWith('http')
                                                    ? profilePictureUrl
                                                    : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
                                              ) as ImageProvider?
                                            : null,
                                        child: profilePictureUrl == null || profilePictureUrl.isEmpty
                                            ? Text(
                                                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        username,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: timeAgo.isNotEmpty
                                          ? Text(
                                              timeAgo,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.white70,
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        final viewerId = viewerUser['id'] as int?;
                                        if (viewerId != null) {
                                          Navigator.pop(context); // Story viewer'ı kapat
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserProfileViewScreen(userId: viewerId),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
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
}
