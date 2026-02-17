import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import 'user_camera_screen.dart';
import 'user_recommendations_screen.dart';
import 'user_profile_screen.dart';
import 'user_history_screen.dart';
import 'user_visits_screen.dart';
import 'recommendation_map_screen.dart';
import 'user_search_screen.dart';
import 'user_notifications_screen.dart';
import 'user_messages_screen.dart';
import 'user_settings_screen.dart';
import '../../services/api_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  int _unreadNotificationCount = 0;

  void navigateToCamera() {
    setState(() {
      _selectedIndex = 1; // Kamera sekmesi
    });
  }

  void navigateToPlaces() {
    setState(() {
      _selectedIndex = 2; // Mekanlar sekmesi
    });
  }

  void navigateToHistory() {
    setState(() {
      _selectedIndex = 3; // Geçmiş sekmesi
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    // Her 30 saniyede bir bildirim sayısını güncelle
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadNotificationCount();
      }
    });
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await _apiService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Hata olsa bile devam et
    }
  }

  List<Widget> get _screens => [
    UserRecommendationsScreen(
      onCameraTap: navigateToCamera,
      onPlacesTap: navigateToPlaces,
      onHistoryTap: navigateToHistory,
    ),
    UserCameraScreen(onPlacesTap: navigateToPlaces),
    const RecommendationMapScreen(),
    const UserHistoryScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _selectedIndex == 2 ? null : _buildDrawer(context, user), // Harita ekranında drawer'ı kapat
      appBar: _selectedIndex == 2 ? null : _buildAppBar(context, user), // Harita ekranında appBar'ı kapat
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.grid_view_rounded,
            color: theme.iconTheme.color,
            size: 22,
          ),
        ),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: theme.iconTheme.color,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserSearchScreen(),
                ),
              );
            },
          ),
        ),
        // Messages button
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.message_rounded,
              color: theme.iconTheme.color,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserMessagesScreen(),
                ),
              );
            },
          ),
        ),
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: theme.iconTheme.color,
                  size: 22,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserNotificationsScreen(),
                    ),
                  );
                  _loadNotificationCount(); // Geri dönünce sayıyı güncelle
                },
              ),
            ),
            if (_unreadNotificationCount > 0)
              Positioned(
                right: 12,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F5F5),
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Modern Header with user info
          Container(
            constraints: const BoxConstraints(minHeight: 240, maxHeight: 280),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                // User info
                SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, top: 40, right: 24, bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedIndex = 4; // Profil ekranına git
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        // Profil Fotoğrafı with modern design
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
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
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: AppTheme.primaryColor,
                                backgroundImage: user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                                    ? NetworkImage(
                                        user.profilePictureUrl!.startsWith('http')
                                            ? user.profilePictureUrl!
                                            : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}${user.profilePictureUrl}',
                                      ) as ImageProvider?
                                    : null,
                                child: user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty
                                    ? (user?.username != null
                                        ? Text(
                                            user!.username.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            size: 45,
                                            color: Colors.white,
                                          ))
                                    : null,
                              ),
                            ),
                            // Edit badge with modern design
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.primaryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Kullanıcı Adı
                        Text(
                          user?.username ?? 'Kullanıcı',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w400,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                return Container(
                  color: theme.scaffoldBackgroundColor,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                  // Ana Sayfa
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Ana Sayfa',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    isSelected: _selectedIndex == 0,
                  ),
                  // Kamera
                  _buildDrawerItem(
                    icon: Icons.camera_alt_rounded,
                    title: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    isSelected: _selectedIndex == 1,
                  ),
                  // Harita
                  _buildDrawerItem(
                    icon: Icons.map_rounded,
                    title: 'Harita',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                    isSelected: _selectedIndex == 2,
                  ),
                  // Geçmiş
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'Geçmiş',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    isSelected: _selectedIndex == 3,
                  ),
                  // Son Gezdiklerim
                  _buildDrawerItem(
                    icon: Icons.place_rounded,
                    title: 'Son Gezdiklerim',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserVisitsScreen(),
                        ),
                      );
                    },
                  ),
                  // Profil
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Profil',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 4;
                      });
                    },
                    isSelected: _selectedIndex == 4,
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                    ),
                  ),
                  
                      // İstatistiklerim
                  _buildDrawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'İstatistiklerim',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  // Ayarlar
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Ayarlar',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserSettingsScreen(),
                        ),
                      );
                    },
                  ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? const Color(0xFF1F2937) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppTheme.textPrimary),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.white : AppTheme.textPrimary),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Ana Sayfa', 0),
              _buildNavItem(Icons.camera_alt_outlined, Icons.camera_alt, 'Kamera', 1),
              _buildNavItem(Icons.map_outlined, Icons.map, 'Harita', 2),
              _buildNavItem(Icons.history_outlined, Icons.history, 'Geçmiş', 3),
              _buildNavItem(Icons.person_outlined, Icons.person, 'Profil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    final selectedColor = theme.bottomNavigationBarTheme.selectedItemColor ?? AppTheme.primaryColor;
    final unselectedColor = theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? selectedColor : unselectedColor,
          size: 24,
        ),
      ),
    );
  }

}
