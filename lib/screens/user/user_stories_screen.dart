import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import 'user_profile_view_screen.dart';

class UserStoriesScreen extends StatefulWidget {
  const UserStoriesScreen({super.key});

  @override
  State<UserStoriesScreen> createState() => _UserStoriesScreenState();
}

class _UserStoriesScreenState extends State<UserStoriesScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  List<dynamic> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      final stories = await _apiService.getFriendsStories();
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createStory() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          await _apiService.createStory(File(image.path));
          if (mounted) {
            Navigator.pop(context); // Loading dialog
            await _loadStories();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Story paylaşıldı'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: $e'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
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

  Future<void> _viewStory(Map<String, dynamic> story) async {
    final storyId = story['id'] as int? ?? 0;
    final userId = story['userId'] as int? ?? story['user']?['id'] as int? ?? 0;
    final imageUrl = story['imageUrl'] as String? ?? '';
    final caption = story['caption'] as String?;

    // Story'yi görüntüleme olarak işaretle
    try {
      await _apiService.viewStory(storyId);
    } catch (e) {
      // Hata olsa bile devam et
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black,
        builder: (context) => _StoryViewer(
          story: story,
          userId: userId,
          imageUrl: imageUrl,
          caption: caption,
          isOwnStory: true, // Bu ekran kullanıcının kendi story'lerini gösterir
        ),
      );
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
          'Stories',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _createStory,
            tooltip: 'Story Paylaş',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStories,
              child: _stories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: isDark ? Colors.white54 : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz story yok',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _createStory,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('İlk Story\'ni Paylaş'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _stories.length,
                      itemBuilder: (context, index) {
                        final story = _stories[index];
                        final user = story['user'] as Map<String, dynamic>? ?? {};
                        final username = user['username'] as String? ?? 'Kullanıcı';
                        final imageUrl = story['imageUrl'] as String? ?? '';
                        final profilePictureUrl = user['profilePictureUrl'] as String?;

                        return GestureDetector(
                          onTap: () => _viewStory(story),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl.startsWith('http')
                                              ? imageUrl
                                              : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$imageUrl',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: AppTheme.primaryColor,
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Colors.white54,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: AppTheme.primaryColor,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: Colors.white54,
                                          ),
                                        ),
                                  // Gradient overlay
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                                ? NetworkImage(
                                                    profilePictureUrl.startsWith('http')
                                                        ? profilePictureUrl
                                                        : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
                                                  ) as ImageProvider?
                                                : null,
                                            backgroundColor: Colors.white,
                                            child: profilePictureUrl == null || profilePictureUrl.isEmpty
                                                ? Text(
                                                    username[0].toUpperCase(),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              username,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
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
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _StoryViewer extends StatefulWidget {
  final Map<String, dynamic> story;
  final int userId;
  final String imageUrl;
  final String? caption;
  final bool isOwnStory;

  const _StoryViewer({
    required this.story,
    required this.userId,
    required this.imageUrl,
    this.caption,
    this.isOwnStory = false,
  });

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Image
          Center(
            child: widget.imageUrl.isNotEmpty
                ? Image.network(
                    widget.imageUrl.startsWith('http')
                        ? widget.imageUrl
                        : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}${widget.imageUrl}',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      );
                    },
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
          ),
          // Top bar with user info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileViewScreen(userId: widget.userId),
                        ),
                      );
                    },
                    child: const Text(
                      'Profili Gör',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Caption at bottom
          if (widget.caption != null && widget.caption!.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.caption!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

