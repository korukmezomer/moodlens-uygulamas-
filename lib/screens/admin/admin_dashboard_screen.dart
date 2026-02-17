import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'admin_users_screen.dart';
import 'admin_places_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_stories_screen.dart';
import 'admin_emotion_logs_screen.dart';
import 'admin_recommendations_screen.dart';
import 'admin_favorites_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _apiService.adminGetDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final number = value is int ? value : (value as num).toInt();
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Bilinmiyor';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Az önce';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} dakika önce';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} saat önce';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return DateFormat('dd MMM yyyy', 'tr_TR').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'USER_REGISTERED':
        return Icons.person_add_rounded;
      case 'PLACE_ADDED':
        return Icons.add_location_rounded;
      case 'EMOTION_LOGGED':
        return Icons.face_rounded;
      case 'RECOMMENDATION_CREATED':
        return Icons.recommend_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
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
                        Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
              'Hata: $_error',
              style: GoogleFonts.inter(
                            color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF1F2328),
              ),
              textAlign: TextAlign.center,
                        ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStats,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
                )
              : _stats == null
                  ? Center(
                      child: Text(
                        'Veri bulunamadı',
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                      ),
                    )
                  : RefreshIndicator(
      onRefresh: _loadStats,
                      color: AppTheme.primaryColor,
                      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(20),
                            sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                  // Welcome Header - Modern Style
                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                                          AppTheme.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                                      borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.insights_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                                        const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                                                'Hoş Geldiniz 👋',
                        style: GoogleFonts.inter(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                                                'Sistem istatistiklerinizi görüntüleyin',
                        style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed: _loadStats,
                                            tooltip: 'Yenile',
                                          ),
                                        ),
              ],
                                    ),
            ),
                                  const SizedBox(height: 24),
                                  // Stats Grid - Modern Card Style
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
                                      return GridView.count(
                                        crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 1.5,
              children: [
                _StatCard(
                  title: 'Kullanıcılar',
                  value: _formatNumber(_stats!['totalUsers']),
                  icon: Icons.people_rounded,
                  color: const Color(0xFF3B82F6),
                  gradientColors: [
                    const Color(0xFF3B82F6),
                    const Color(0xFF2563EB),
                  ],
                  theme: theme,
                                            isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen(),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Mekanlar',
                  value: _formatNumber(_stats!['totalPlaces']),
                  icon: Icons.location_city_rounded,
                  color: const Color(0xFF10B981),
                  gradientColors: [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
                  theme: theme,
                                            isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPlacesScreen(),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Emotion Log',
                  value: _formatNumber(_stats!['totalEmotionLogs']),
                  icon: Icons.psychology_rounded,
                  color: const Color(0xFFF59E0B),
                  gradientColors: [
                    const Color(0xFFF59E0B),
                    const Color(0xFFD97706),
                  ],
                  theme: theme,
                                            isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                                                  builder: (_) => const AdminEmotionLogsScreen(),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Öneriler',
                  value: _formatNumber(_stats!['totalRecommendations']),
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF8B5CF6),
                  gradientColors: [
                    const Color(0xFF8B5CF6),
                    const Color(0xFF7C3AED),
                  ],
                  theme: theme,
                                            isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                                                  builder: (_) => const AdminRecommendationsScreen(),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Editör Seçimi',
                  value: _formatNumber(_stats!['totalEditorChoicePlaces']),
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFBBF24),
                  gradientColors: [
                    const Color(0xFFFBBF24),
                    const Color(0xFFF59E0B),
                  ],
                  theme: theme,
                                            isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                                                  builder: (_) => const AdminPlacesScreen(initialTabIndex: 1),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Favoriler',
                  value: _formatNumber(_stats!['totalFavorites']),
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFEF4444),
                  gradientColors: [
                    const Color(0xFFEF4444),
                    const Color(0xFFDC2626),
                  ],
                  theme: theme,
                                            isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                                                  builder: (_) => const AdminFavoritesScreen(),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Storyler',
                  value: _formatNumber(_stats!['totalStories'] ?? 0),
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFFEC4899),
                  gradientColors: [
                    const Color(0xFFEC4899),
                    const Color(0xFFDB2777),
                  ],
                  theme: theme,
                                            isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminStoriesScreen(),
                      ),
                    );
                  },
                ),
              ],
                                      );
                                    },
            ),
                                  const SizedBox(height: 28),
                                  // Recent Activity - Modern Style
            Container(
              decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF161B22) : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                border: Border.all(
                                        color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                                        width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                                      padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppTheme.primaryColor,
                                                      AppTheme.primaryColor.withValues(alpha: 0.8),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: const Icon(
                                                  Icons.history_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                    Text(
                      'Son Aktiviteler',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF1F2328),
                                                  letterSpacing: -0.6,
                      ),
                    ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                    if (_stats!['recentActivities'] != null &&
                        (_stats!['recentActivities'] as List).isNotEmpty)
                      ...(_stats!['recentActivities'] as List)
                          .map((activity) => _ActivityItem(
                                title: activity['title'] ?? '',
                                subtitle: _formatTimeAgo(activity['timestamp']),
                                icon: _getActivityIcon(activity['type'] ?? ''),
                                theme: theme,
                                                      isDark: isDark,
                              ))
                          .toList()
                    else
                      Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Center(
                        child: Text(
                          'Henüz aktivite yok',
                          style: GoogleFonts.inter(
                                                    color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                                                    fontSize: 14,
                                                  ),
                          ),
                        ),
                      ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.theme,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Container(
                      width: 40,
                      height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                        borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (onTap != null)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                  value,
                  style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                        letterSpacing: -0.8,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeData theme;
  final bool isDark;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2328),
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                    ),
                    const SizedBox(width: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                  ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
            size: 20,
          ),
        ],
      ),
    );
  }
}
