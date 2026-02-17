import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import 'user_profile_view_screen.dart';
import 'user_friends_screen.dart';
import 'user_messages_screen.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _apiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      // Hata olsa bile devam et
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler okundu olarak işaretlendi'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
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

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);
      await _loadNotifications();
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

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? '';
    final relatedUser = notification['relatedUser'] as Map<String, dynamic>?;
    final relatedUserId = relatedUser?['id'] as int?;

    if (relatedUserId == null) return;

    // Okundu olarak işaretle
    final notificationId = notification['id'] as int?;
    if (notificationId != null) {
      _markAsRead(notificationId);
    }

    if (type == 'FRIEND_REQUEST' || type == 'FRIEND_ACCEPTED') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UserFriendsScreen(),
        ),
      );
    } else if (type == 'MESSAGE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserMessagesScreen(otherUserId: relatedUserId),
        ),
      );
    } else if (type == 'STORY') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileViewScreen(
            userId: relatedUserId,
            username: relatedUser?['username'] as String?,
          ),
        ),
      );
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'FRIEND_REQUEST':
        return Icons.person_add_rounded;
      case 'FRIEND_ACCEPTED':
        return Icons.check_circle_rounded;
      case 'MESSAGE':
        return Icons.message_rounded;
      case 'STORY':
        return Icons.photo_library_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'FRIEND_REQUEST':
        return AppTheme.primaryColor;
      case 'FRIEND_ACCEPTED':
        return AppTheme.successGreen;
      case 'MESSAGE':
        return Colors.blue;
      case 'STORY':
        return const Color(0xFFEC4899);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Bildirimler',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (_notifications.any((n) => !(n['isRead'] ?? false)))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tümünü Okundu İşaretle',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: isDark ? Colors.white54 : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bildirim yok',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yeni bildirimler burada görünecek',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index] as Map<String, dynamic>;
                        final type = notification['type'] as String? ?? '';
                        final title = notification['title'] as String? ?? '';
                        final message = notification['message'] as String? ?? '';
                        final isRead = notification['isRead'] as bool? ?? false;
                        final relatedUser = notification['relatedUser'] as Map<String, dynamic>?;
                        final profilePictureUrl = relatedUser?['profilePictureUrl'] as String?;
                        final username = relatedUser?['username'] as String? ?? 'Kullanıcı';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead
                                ? (isDark ? const Color(0xFF1F2937) : Colors.white)
                                : (isDark ? const Color(0xFF2A3441) : Colors.blue[50]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!)
                                  : AppTheme.primaryColor.withValues(alpha: 0.3),
                              width: isRead ? 1.5 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _handleNotificationTap(notification),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Profile Picture or Icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getNotificationColor(type).withValues(alpha: 0.1),
                                      ),
                                      child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                profilePictureUrl.startsWith('http')
                                                    ? profilePictureUrl
                                                    : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    _getNotificationIcon(type),
                                                    color: _getNotificationColor(type),
                                                    size: 24,
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              _getNotificationIcon(type),
                                              color: _getNotificationColor(type),
                                              size: 24,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            message,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: isDark ? Colors.white70 : AppTheme.textSecondary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Unread indicator
                                    if (!isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

