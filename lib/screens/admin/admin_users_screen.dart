import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _apiService.adminGetAllUsers();
      setState(() {
        _users = users;
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
      return DateFormat('dd MMM yyyy', 'tr_TR').format(date);
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
                Icons.people_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Kullanıcılar',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2328),
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.add_rounded,
                color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
              ),
              onPressed: () => _showAddUserDialog(context),
              tooltip: 'Yeni Kullanıcı',
            ),
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
              onPressed: _loadUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: AppTheme.primaryColor,
                  child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Info Header - Modern Style
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
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
                  Icons.people_rounded,
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
                          '${_users.length} Kullanıcı',
                      style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                        color: Colors.white,
                            letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                          'Tüm kullanıcıları yönetin',
                      style: GoogleFonts.inter(
                            fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
          ),
        ),
        // Users List
          if (_users.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                      color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz kullanıcı yok',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                        color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                          ),
                        ),
                      ],
                    ),
                    ),
                  )
          else
            SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                      final user = _users[index];
                      return _UserCard(
                        user: user,
                        theme: theme,
                      isDark: isDark,
                        formatDate: _formatDate,
                        getRoleColor: _getRoleColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(
                                userId: user['id'],
                              ),
                            ),
                          ).then((_) => _loadUsers());
                        },
                        onEdit: () => _showEditUserDialog(context, user),
                        onDelete: () => _showDeleteUserDialog(context, user),
                      );
                    },
                  childCount: _users.length,
                  ),
          ),
        ),
      ],
      ),
    ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'USER';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Yeni Kullanıcı Ekle',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['USER', 'ADMIN']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await _apiService.adminCreateUser(
          username: usernameController.text,
          email: emailController.text,
          password: passwordController.text,
          role: selectedRole,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı başarıyla oluşturuldu'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
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

  Future<void> _showEditUserDialog(BuildContext context, Map<String, dynamic> user) async {
    final usernameController = TextEditingController(text: user['username']);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String selectedRole = user['role'] ?? 'USER';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Kullanıcı Düzenle',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre (boş bırakılabilir)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['USER', 'ADMIN']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final updates = <String, dynamic>{
          'username': usernameController.text,
          'email': emailController.text,
          'role': selectedRole,
        };
        if (passwordController.text.isNotEmpty) {
          updates['password'] = passwordController.text;
        }
        await _apiService.adminUpdateUser(user['id'], updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
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

  Future<void> _showDeleteUserDialog(BuildContext context, Map<String, dynamic> user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Kullanıcıyı Sil',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${user['username']} kullanıcısını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _apiService.adminDeleteUser(user['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
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
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final ThemeData theme;
  final bool isDark;
  final String Function(String?) formatDate;
  final Color Function(String?) getRoleColor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UserCard({
    required this.user,
    required this.theme,
    required this.isDark,
    required this.formatDate,
    required this.getRoleColor,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                      width: 60,
                      height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                        borderRadius: BorderRadius.circular(18),
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
                      (user['username'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.inter(
                            fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['username'] ?? 'Kullanıcı',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1F2328),
                                    letterSpacing: -0.4,
                              ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  getRoleColor(user['role']),
                                  getRoleColor(user['role']).withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: getRoleColor(user['role']).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              user['role'] ?? 'USER',
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
                            color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                        user['email'] ?? '',
                        style: GoogleFonts.inter(
                                fontSize: 14,
                                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                              ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                        ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                          ),
                          const SizedBox(width: 6),
                      Text(
                        'Kayıt: ${formatDate(user['createdAt']?.toString())}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
                        ),
                      ),
                    ],
                ),
              ],
            ),
                ),
              ],
            ),
                const SizedBox(height: 18),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
                    Colors.transparent,
                  ],
                ),
                ),
            ),
            const SizedBox(height: 16),
            Row(
                  mainAxisAlignment: MainAxisAlignment.end,
              children: [
                    _ActionButton(
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF3B82F6),
                    onPressed: onTap,
                      tooltip: 'Detay',
                      isDark: isDark,
                ),
                const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF10B981),
                    onPressed: onEdit,
                      tooltip: 'Düzenle',
                      isDark: isDark,
                ),
                const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete_rounded,
                      color: AppTheme.errorRed,
                    onPressed: user['role'] == 'ADMIN' ? null : onDelete,
                      tooltip: 'Sil',
                      isDark: isDark,
                ),
              ],
            ),
          ],
            ),
        ),
      ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onPressed,
    required this.tooltip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
      child: Container(
            padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
              color: onPressed == null
                  ? (isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA))
                  : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: onPressed == null
                    ? Colors.transparent
                    : color.withValues(alpha: 0.3),
                width: 1,
        ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null
                  ? (isDark ? const Color(0xFF484F58) : const Color(0xFFD0D7DE))
                  : color,
              ),
            ),
        ),
      ),
    );
  }
}
