import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'admin_stories_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _apiService.adminGetUserById(widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Bilinmiyor';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'USER':
        return Colors.blue;
      default:
        return Colors.grey;
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
                Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
          'Kullanıcı Detayları',
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
                        onPressed: _loadUser,
                        child: const Text('Yeniden Dene'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? const Center(child: Text('Kullanıcı bulunamadı'))
                  : RefreshIndicator(
                      onRefresh: _loadUser,
                      color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header - Modern Style
                            Container(
                              padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor,
                                    AppTheme.primaryColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                borderRadius: BorderRadius.circular(24),
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
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.3),
                                          Colors.white.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 3,
                                      ),
                                  boxShadow: [
                                    BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (_user!['username'] ?? 'U')[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                          fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                          letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),
                                  const SizedBox(width: 20),
                                  Expanded(
                              child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                            Expanded(
                                              child: Text(
                                        _user!['username'] ?? 'Kullanıcı',
                                        style: GoogleFonts.inter(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -0.6,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _getRoleColor(_user!['role']),
                                                    _getRoleColor(_user!['role']).withValues(alpha: 0.8),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getRoleColor(_user!['role']).withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                          ),
                                                ],
                                        ),
                                        child: Text(
                                          _user!['role'] ?? 'USER',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 14,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                    _user!['email'] ?? '',
                                    style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Stats Cards - Modern Grid
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.35,
                              children: [
                                _StatCard(
                                  icon: Icons.psychology_rounded,
                                    label: 'Emotion Log',
                                    value: (_user!['emotionLogCount'] ?? 0).toString(),
                                  color: const Color(0xFFF59E0B),
                                    theme: theme,
                                  isDark: isDark,
                                ),
                                _StatCard(
                                  icon: Icons.auto_awesome_rounded,
                                    label: 'Öneriler',
                                    value: (_user!['recommendationCount'] ?? 0).toString(),
                                  color: const Color(0xFF8B5CF6),
                                    theme: theme,
                                  isDark: isDark,
                            ),
                                _StatCard(
                                  icon: Icons.favorite_rounded,
                                    label: 'Favoriler',
                                    value: (_user!['favoriteCount'] ?? 0).toString(),
                                  color: const Color(0xFFEF4444),
                                    theme: theme,
                                  isDark: isDark,
                                ),
                                _StatCard(
                                  icon: Icons.place_rounded,
                                    label: 'Ziyaretler',
                                    value: (_user!['visitCount'] ?? 0).toString(),
                                  color: const Color(0xFF10B981),
                                    theme: theme,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Story Management Button - Modern Style
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFEC4899),
                                    const Color(0xFFDB2777),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminStoriesScreen(userId: widget.userId),
                                  ),
                                );
                              },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.photo_library_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Storyleri Görüntüle',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Info Card - Modern Style
                            Container(
                              padding: const EdgeInsets.all(24),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                  Text(
                                    'Hesap Bilgileri',
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
                                  _InfoRow(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Kullanıcı Adı',
                                    value: _user!['username'] ?? '',
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 20),
                                  _InfoRow(
                                    icon: Icons.email_outlined,
                                    label: 'E-posta',
                                    value: _user!['email'] ?? '',
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 20),
                                  _InfoRow(
                                    icon: Icons.shield_outlined,
                                    label: 'Rol',
                                    value: _user!['role'] ?? 'USER',
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 20),
                                  _InfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Kayıt Tarihi',
                                    value: _formatDate(_user!['createdAt']?.toString()),
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                  if (_user!['lastActiveAt'] != null) ...[
                                    const SizedBox(height: 20),
                                    _InfoRow(
                                      icon: Icons.access_time_outlined,
                                      label: 'Son Aktiflik',
                                      value: _formatDate(_user!['lastActiveAt']?.toString()),
                                      theme: theme,
                                      isDark: isDark,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
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
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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
              borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                  ),
                ),
                const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2328),
                ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

