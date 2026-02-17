import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import 'user_friends_screen.dart';
import 'user_messages_screen.dart';
import 'recommendation_map_screen.dart';
import '../../models/recommendation_model.dart';

class UserProfileViewScreen extends StatefulWidget {
  final int userId;
  final String? username;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.username,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  List<dynamic> _favorites = [];
  List<dynamic> _recentVisits = [];
  bool _isLoading = true;
  bool _isFriend = false;
  bool _hasPendingRequest = false;
  String? _error;
  int _friendsCount = 0;
  int _favoritesCount = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _apiService.getUserProfile(widget.userId);
      final favorites = await _apiService.getUserFavorites(widget.userId);
      final recentVisits = await _apiService.getUserRecentVisits(widget.userId, limit: 12);
      final areFriends = await _apiService.areFriends(widget.userId);

      setState(() {
        _userData = userData;
        _favorites = favorites;
        _recentVisits = recentVisits;
        _isFriend = areFriends;
        _friendsCount = (userData['friendsCount'] as num?)?.toInt() ?? 0;
        _favoritesCount = (userData['favoritesCount'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      final success = await _apiService.sendFriendRequest(widget.userId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arkadaşlık isteği gönderildi'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        setState(() {
          _hasPendingRequest = true;
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

  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Kullanıcıyı Engelle',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: const Text('Bu kullanıcıyı engellemek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Engelle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _apiService.blockUser(widget.userId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı engellendi'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final isOwnProfile = currentUser?.userId == widget.userId;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _userData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
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
                _error ?? 'Kullanıcı bulunamadı',
                style: GoogleFonts.inter(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final username = _userData!['username'] as String? ?? widget.username ?? 'Kullanıcı';
    final profilePictureUrl = _userData!['profilePictureUrl'] as String?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          username,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (!isOwnProfile)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              onSelected: (value) {
                if (value == 'block') {
                  _blockUser();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Engelle',
                        style: GoogleFonts.inter(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Profile Picture and Stats
                  Row(
                    children: [
                      // Profile Picture
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.7),
                            ],
                          ),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.grey[300]!,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                              ? Image.network(
                                  profilePictureUrl.startsWith('http')
                                      ? profilePictureUrl
                                      : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildAvatarPlaceholder(username);
                                  },
                                )
                              : _buildAvatarPlaceholder(username),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('$_favoritesCount', 'Favoriler', isDark),
                            _buildStatColumn('$_friendsCount', 'Arkadaşlar', isDark),
                            _buildStatColumn('${_recentVisits.length}', 'Ziyaretler', isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Username
                  Text(
                    username,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  if (isOwnProfile)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to own profile settings
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.grey[200],
                          foregroundColor: isDark ? Colors.white : AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Profili Düzenle',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _isFriend
                              ? ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserMessagesScreen(
                                          otherUserId: widget.userId,
                                          otherUsername: username,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.message_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Mesaj',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _hasPendingRequest ? null : _sendFriendRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _hasPendingRequest ? Icons.check_circle_outline : Icons.person_add_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _hasPendingRequest ? 'İstek Gönderildi' : 'Arkadaş Ekle',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        if (!_isFriend) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserFriendsScreen(userId: widget.userId),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey[300]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          child: Icon(
                            Icons.person_add_rounded,
                            size: 20,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 2,
                labelColor: isDark ? Colors.white : AppTheme.textPrimary,
                unselectedLabelColor: isDark ? Colors.white54 : AppTheme.textSecondary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Favoriler'),
                  Tab(text: 'Son Ziyaretler'),
                ],
              ),
            ),
          ),
          // Tab Content
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      kToolbarHeight - 
                      242 - 
                      48, // Profile header + tab bar heights
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Favorites Tab
                  _buildFavoritesTab(isDark),
                  // Recent Visits Tab
                  _buildRecentVisitsTab(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(bool isDark) {
    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz favori mekan yok',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        final imageUrl = favorite['imageUrl'] as String?;
        final placeName = favorite['placeName'] as String? ?? 'Mekan';
        final placeCategory = favorite['placeCategory'] as String? ?? '';
        
        return GestureDetector(
          onTap: () {
            final lat = favorite['latitude'] as num?;
            final lon = favorite['longitude'] as num?;
            if (lat != null && lon != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecommendationMapScreen(
                    initialRecommendation: RecommendationModel(
                      id: 0,
                      name: placeName,
                      latitude: lat.toDouble(),
                      longitude: lon.toDouble(),
                      address: favorite['address'] as String?,
                      category: placeCategory,
                      rating: (favorite['rating'] as num?)?.toDouble(),
                      externalId: favorite['placeExternalId'] as String?,
                    ),
                  ),
                ),
              );
            }
          },
          child: Container(
            color: isDark ? const Color(0xFF1F2937) : Colors.grey[200],
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image or Place Name Background
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl.startsWith('http')
                        ? imageUrl
                        : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$imageUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? const Color(0xFF2D3748) : Colors.grey[300],
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              placeName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    color: isDark ? const Color(0xFF2D3748) : Colors.grey[300],
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          placeName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Gradient overlay (only if image exists)
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
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
                // Place name overlay on image (if image exists)
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Text(
                        placeName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentVisitsTab(bool isDark) {
    if (_recentVisits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz ziyaret edilen mekan yok',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _recentVisits.length,
      itemBuilder: (context, index) {
        final visit = _recentVisits[index];
        final placeName = visit['placeName'] as String? ?? 'Mekan';
        final placeCategory = visit['placeCategory'] as String?;
        final rating = visit['rating'] as num?;
        final visitedAt = visit['visitedAt'] as String?;
        
        String formattedDate = '';
        if (visitedAt != null) {
          try {
            final date = DateTime.parse(visitedAt);
            formattedDate = DateFormat('dd MMM yyyy', 'tr_TR').format(date);
          } catch (e) {
            formattedDate = visitedAt;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final lat = visit['latitude'] as num?;
                final lon = visit['longitude'] as num?;
                if (lat != null && lon != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecommendationMapScreen(
                        initialRecommendation: RecommendationModel(
                          id: 0,
                          name: placeName,
                          latitude: lat.toDouble(),
                          longitude: lon.toDouble(),
                          category: placeCategory,
                          rating: rating?.toDouble(),
                          externalId: visit['placeExternalId'] as String?,
                        ),
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          if (placeCategory != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              placeCategory,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                          if (rating != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (formattedDate.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String count, String label, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.white70 : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(String username) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.isEmpty) return Icons.place_rounded;
    
    switch (category.toLowerCase()) {
      case 'kafe':
      case 'cafe':
      case 'café':
        return Icons.coffee_rounded;
      case 'restoran':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'müze':
      case 'museum':
        return Icons.museum_rounded;
      case 'sinema':
      case 'cinema':
        return Icons.movie_rounded;
      case 'tiyatro':
      case 'theatre':
      case 'theater':
        return Icons.theater_comedy_rounded;
      case 'bar':
        return Icons.local_bar_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'spor salonu':
      case 'gym':
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'kütüphane':
      case 'library':
        return Icons.local_library_rounded;
      case 'avm':
      case 'shopping_mall':
      case 'alışveriş merkezi':
        return Icons.shopping_bag_rounded;
      case 'otel':
      case 'hotel':
        return Icons.hotel_rounded;
      case 'hastane':
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'okul':
      case 'school':
      case 'üniversite':
      case 'university':
        return Icons.school_rounded;
      case 'plaj':
      case 'beach':
        return Icons.beach_access_rounded;
      case 'kilise':
      case 'church':
      case 'cami':
      case 'mosque':
        return Icons.church_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
