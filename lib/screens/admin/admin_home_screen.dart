import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_places_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_stories_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      screen: const AdminDashboardScreen(),
    ),
    _NavItem(
      icon: Icons.people_rounded,
      label: 'Kullanıcılar',
      screen: const AdminUsersScreen(),
    ),
    _NavItem(
      icon: Icons.location_city_rounded,
      label: 'Mekanlar',
      screen: const AdminPlacesScreen(),
    ),
    _NavItem(
      icon: Icons.photo_library_rounded,
      label: 'Storyler',
      screen: const AdminStoriesScreen(),
    ),
    _NavItem(
      icon: Icons.analytics_rounded,
      label: 'Analitik',
      screen: const AdminAnalyticsScreen(),
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Profil',
      screen: const AdminProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      drawer: isMobile ? _buildDrawer(theme, isDark, user) : null,
      body: Row(
        children: [
          // Desktop Sidebar
          if (!isMobile) _buildSidebar(theme, isDark, user),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Modern AppBar
                _buildAppBar(theme, isDark, user, authProvider, isMobile),
                // Content
                Expanded(
                  child: _navItems[_selectedIndex].screen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, bool isDark, dynamic user) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
          'Admin Panel',
          style: GoogleFonts.inter(
                          fontSize: 16,
            fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2328),
                          letterSpacing: -0.5,
          ),
        ),
                      const SizedBox(height: 2),
                      Text(
                        'Yönetim',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return _buildNavItem(
                  item: item,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          // User Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
            child: Center(
              child: Text(
                      (user?.username ?? 'A')[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                user?.username ?? 'Admin',
                style: GoogleFonts.inter(
                          fontSize: 14,
                  fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2328),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Logout Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                  width: 1,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
                      title: Text(
                        'Çıkış Yap',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2328),
                        ),
                      ),
                      content: Text(
                        'Çıkış yapmak istediğinize emin misiniz?',
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF656D76),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.inter(
                              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDA3633),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await authProvider.logout();
                    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                    await themeProvider.resetTheme();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFFDA3633) : const Color(0xFFDA3633),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Çıkış Yap',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFDA3633) : const Color(0xFFDA3633),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required _NavItem item,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF1F6FEB) : const Color(0xFF0969DA))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFC9D1D9) : const Color(0xFF1F2328)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme, bool isDark, dynamic user) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      child: _buildSidebar(theme, isDark, user),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark, dynamic user, AuthProvider authProvider, bool isMobile) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 768 ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu Button (Mobile)
          if (isMobile)
            IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          // Page Title
          Expanded(
            child: Text(
              _navItems[_selectedIndex].label,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2328),
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Actions
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
                  title: Text(
                    'Çıkış Yap',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2328),
                    ),
                  ),
                  content: Text(
                    'Çıkış yapmak istediğinize emin misiniz?',
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF656D76),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDA3633),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
              await authProvider.logout();
              // Tema ayarını sıfırla
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              await themeProvider.resetTheme();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
                }
              }
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;

  _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
  }
