import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import 'admin_home_screen.dart';
import 'package:intl/intl.dart';

class AdminStoriesScreen extends StatefulWidget {
  final int? userId;

  const AdminStoriesScreen({super.key, this.userId});

  @override
  State<AdminStoriesScreen> createState() => _AdminStoriesScreenState();
}

class _AdminStoriesScreenState extends State<AdminStoriesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _stories = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<dynamic> stories;
      if (widget.userId != null) {
        stories = await _apiService.adminGetUserStories(widget.userId!);
      } else {
        stories = await _apiService.adminGetAllStories();
      }
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStory(int storyId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Story Sil',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$username kullanıcısının story\'sini silmek istediğinize emin misiniz?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sil',
              style: GoogleFonts.inter(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.adminDeleteStory(storyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Story başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStories();
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
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Bilinmiyor';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  List<dynamic> get _filteredStories {
    if (_searchQuery.isEmpty) return _stories;
    return _stories.where((story) {
      final username = (story['username'] as String? ?? '').toLowerCase();
      final caption = (story['caption'] as String? ?? '').toLowerCase();
      return username.contains(_searchQuery.toLowerCase()) ||
          caption.contains(_searchQuery.toLowerCase());
    }).toList();
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
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
              (route) => false,
            );
          },
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
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              widget.userId != null ? 'Kullanıcı Storyleri' : 'Storyler',
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
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı veya açıklama ara...',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.inter(
                color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF1F2328),
              ),
            ),
          ),
          // Stories list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                color: AppTheme.errorRed,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStories,
                              child: const Text('Yeniden Dene'),
                            ),
                          ],
                        ),
                      )
                    : _filteredStories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 64,
                                  color: isDark ? Colors.white38 : Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Arama sonucu bulunamadı'
                                      : 'Henüz story yok',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStories,
                            child: ListView.builder(
                              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                              itemCount: _filteredStories.length,
                              itemBuilder: (context, index) {
                                final story = _filteredStories[index];
                                final storyId = story['id'] as int? ?? 0;
                                final userId = story['userId'] as int? ?? 0;
                                final username = story['username'] as String? ?? 'Bilinmeyen';
                                final imageUrl = story['imageUrl'] as String? ?? '';
                                final caption = story['caption'] as String? ?? '';
                                final createdAt = story['createdAt'] as String?;
                                final expiresAt = story['expiresAt'] as String?;
                                final likeCount = story['likeCount'] as int? ?? 0;
                                final commentCount = story['commentCount'] as int? ?? 0;
                                final viewCount = story['viewCount'] as int? ?? 0;

                                final fullImageUrl = imageUrl.isNotEmpty
                                    ? (imageUrl.startsWith('http')
                                        ? imageUrl
                                        : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$imageUrl')
                                    : '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 18),
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
                                      // Story image
                                      if (fullImageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 1,
                                            child: Image.network(
                                              fullImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      // Story info
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // User info
                                            Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        AppTheme.primaryColor,
                                                        AppTheme.primaryColor.withValues(alpha: 0.8),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(14),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                  child: Text(
                                                    username[0].toUpperCase(),
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        username,
                                                        style: GoogleFonts.inter(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 18,
                                                          letterSpacing: -0.4,
                                                        ),
                                                      ),
                                                      Text(
                                                        'ID: $userId',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete_rounded, size: 22),
                                                  color: AppTheme.errorRed,
                                                  onPressed: () => _deleteStory(storyId, username),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Caption
                                            if (caption.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: Text(
                                                  caption,
                                                  style: GoogleFonts.inter(fontSize: 14),
                                                ),
                                              ),
                                            // Stats
                                            Row(
                                              children: [
                                                _buildStatChip(
                                                  Icons.favorite,
                                                  '$likeCount',
                                                  Colors.red,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildStatChip(
                                                  Icons.comment,
                                                  '$commentCount',
                                                  Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildStatChip(
                                                  Icons.visibility,
                                                  '$viewCount',
                                                  Colors.green,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Dates
                                            Text(
                                              'Oluşturulma: ${_formatDate(createdAt)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Bitiş: ${_formatDate(expiresAt)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

