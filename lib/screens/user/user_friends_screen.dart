import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import 'user_profile_view_screen.dart';
import 'user_messages_screen.dart';

class UserFriendsScreen extends StatefulWidget {
  final int? userId;
  
  const UserFriendsScreen({super.key, this.userId});

  @override
  State<UserFriendsScreen> createState() => _UserFriendsScreenState();
}

class _UserFriendsScreenState extends State<UserFriendsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<dynamic> _friends = [];
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _apiService.getFriends();
      final requests = await _apiService.getFriendRequests();
      setState(() {
        _friends = friends;
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAcceptRequest(int senderId) async {
    try {
      final success = await _apiService.acceptFriendRequest(senderId);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arkadaşlık isteği kabul edildi'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
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

  Future<void> _handleRejectRequest(int senderId) async {
    try {
      final success = await _apiService.rejectFriendRequest(senderId);
      if (success) {
        await _loadData();
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
          'Arkadaşlar',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white70 : AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text('Arkadaşlar (${_friends.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text('İstekler (${_pendingRequests.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(isDark),
                _buildRequestsList(isDark),
              ],
            ),
    );
  }

  Widget _buildFriendsList(bool isDark) {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: isDark ? Colors.white54 : AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz arkadaşınız yok',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          final userId = friend['id'] as int? ?? friend['userId'] as int? ?? 0;
          final username = friend['username'] as String? ?? 'Kullanıcı';
          final profilePictureUrl = friend['profilePictureUrl'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              title: Text(
                username,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message_rounded),
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserMessagesScreen(otherUserId: userId),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_rounded),
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileViewScreen(userId: userId, username: username),
                        ),
                      );
                    },
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileViewScreen(userId: userId, username: username),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(bool isDark) {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: isDark ? Colors.white54 : AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bekleyen istek yok',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          final sender = request['sender'] as Map<String, dynamic>? ?? {};
          final senderId = sender['id'] as int? ?? 0;
          final username = sender['username'] as String? ?? 'Kullanıcı';
          final profilePictureUrl = sender['profilePictureUrl'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              title: Text(
                username,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Arkadaşlık isteği gönderdi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_rounded),
                    color: AppTheme.successGreen,
                    onPressed: () => _handleAcceptRequest(senderId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.errorRed,
                    onPressed: () => _handleRejectRequest(senderId),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

