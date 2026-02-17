import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import 'user_profile_view_screen.dart';

class UserMessagesScreen extends StatefulWidget {
  final int? otherUserId;
  final String? otherUsername;

  const UserMessagesScreen({
    super.key,
    this.otherUserId,
    this.otherUsername,
  });

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  int? _selectedConversationId;
  String? _otherUserProfilePicture;
  String? _otherUsername;
  bool _isSelectionMode = false;
  Set<int> _selectedMessageIds = <int>{};
  Set<int> _selectedConversationIds = <int>{}; // Seçilen konuşmalar

  @override
  void initState() {
    super.initState();
    if (widget.otherUserId != null) {
      _selectedConversationId = widget.otherUserId;
      _loadConversation();
    } else {
      _loadConversations();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _apiService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConversation() async {
    if (_selectedConversationId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getConversation(_selectedConversationId!);
      final messages = response['content'] as List<dynamic>? ?? [];
      final otherUser = response['otherUser'] as Map<String, dynamic>?;
      
      setState(() {
        _messages = messages.reversed.toList();
        if (otherUser != null) {
          _otherUsername = otherUser['username'] as String? ?? widget.otherUsername ?? 'Kullanıcı';
          _otherUserProfilePicture = otherUser['profilePictureUrl'] as String?;
        } else {
          _otherUsername = widget.otherUsername ?? 'Kullanıcı';
        }
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedConversationId == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await _apiService.sendMessage(_selectedConversationId!, content);
      await _loadConversation();
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.otherUserId == null && _selectedConversationId == null) {
      // Conversation list view - Instagram Direct Messages style
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Mesajlar',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _selectedConversationIds.isEmpty
                    ? null
                    : () async {
                        if (_selectedConversationIds.isEmpty) return;
                        
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                            title: Text(
                              'Konuşmaları Sil',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            content: Text(
                              '${_selectedConversationIds.length} konuşmayı silmek istediğinize emin misiniz?',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white70 : AppTheme.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'İptal',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Sil',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          try {
                            final conversationIds = _selectedConversationIds.toList();
                            for (final conversationId in conversationIds) {
                              await _apiService.deleteConversation(conversationId);
                            }
                            setState(() {
                              _selectedConversationIds.clear();
                              _isSelectionMode = false;
                            });
                            await _loadConversations();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Konuşmalar silindi'),
                                  backgroundColor: Colors.green,
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
                      },
              ),
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.close : Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) {
                    _selectedConversationIds.clear();
                  }
                });
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: isDark ? Colors.white54 : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesajınız yok',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _conversations.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300],
                        indent: 80,
                      ),
                      itemBuilder: (context, index) {
                        final user = _conversations[index] as Map<String, dynamic>;
                        final userId = user['id'] as int? ?? 0;
                        final username = user['username'] as String? ?? 'Kullanıcı';
                        final profilePictureUrl = user['profilePictureUrl'] as String?;
                        final isSelected = _selectedConversationIds.contains(userId);

                        return InkWell(
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedConversationIds.remove(userId);
                                } else {
                                  _selectedConversationIds.add(userId);
                                }
                              });
                            } else {
                            setState(() {
                              _selectedConversationId = userId;
                            });
                            _loadConversation();
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedConversationIds.add(userId);
                              });
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? (isDark ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1))
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                // Checkbox (selection mode'da görünür)
                                if (_isSelectionMode) ...[
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : (isDark ? Colors.white54 : Colors.grey[400]!),
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                // Profile picture
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
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
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Son mesaj...',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: isDark ? Colors.white54 : AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isSelectionMode)
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark ? Colors.white38 : Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      );
    }

    // Chat view
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (widget.otherUserId != null) {
              Navigator.pop(context);
            } else {
              setState(() {
                _selectedConversationId = null;
                _messages = [];
              });
              _loadConversations();
            }
          },
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_selectedConversationId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileViewScreen(
                        userId: _selectedConversationId!,
                        username: _otherUsername ?? widget.otherUsername,
                      ),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: _otherUserProfilePicture != null && _otherUserProfilePicture!.isNotEmpty
                    ? NetworkImage(
                        _otherUserProfilePicture!.startsWith('http')
                            ? _otherUserProfilePicture!
                            : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$_otherUserProfilePicture',
                      ) as ImageProvider?
                    : null,
                backgroundColor: AppTheme.primaryColor,
                child: _otherUserProfilePicture == null || _otherUserProfilePicture!.isEmpty
                    ? Text(
                        (_otherUsername ?? widget.otherUsername ?? 'U')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _otherUsername ?? widget.otherUsername ?? 'Kullanıcı',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedMessageIds.isEmpty
                  ? null
                  : () async {
                      if (_selectedMessageIds.isEmpty) return;
                      
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Mesajları Sil',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Text(
                            '${_selectedMessageIds.length} mesajı silmek istediğinize emin misiniz?',
                            style: GoogleFonts.inter(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'İptal',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Sil',
                                style: GoogleFonts.inter(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        try {
                          final messageIds = _selectedMessageIds.toList();
                          await _apiService.deleteMessages(messageIds);
                          setState(() {
                            _selectedMessageIds.clear();
                            _isSelectionMode = false;
                          });
                          await _loadConversation();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Mesajlar silindi'),
                                backgroundColor: Colors.green,
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
                    },
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.person_rounded),
            onPressed: _isSelectionMode
                ? () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedMessageIds.clear();
                    });
                  }
                : () {
              if (_selectedConversationId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileViewScreen(
                      userId: _selectedConversationId!,
                      username: widget.otherUsername,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Henüz mesaj yok',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversation,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final currentUserId = authProvider.user?.userId;
                            
                            final message = _messages[index];
                            final messageId = message['id'] as int? ?? 0;
                            final senderId = message['senderId'] as int? ?? 0;
                            final isMe = currentUserId != null && senderId == currentUserId;
                            final content = message['content'] as String? ?? '';
                            final isSelected = _selectedMessageIds.contains(messageId);
                            final story = message['story'] as Map<String, dynamic>?;

                            // Story mesajı ise özel gösterim
                            if (story != null) {
                              final storyImageUrl = story['imageUrl'] as String? ?? '';
                              final storyCaption = story['caption'] as String?;
                              final senderUsername = message['senderUsername'] as String? ?? 
                                                   message['sender']?['username'] as String? ?? 
                                                   'Kullanıcı';
                              
                              return GestureDetector(
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    setState(() {
                                      _isSelectionMode = true;
                                      _selectedMessageIds.add(messageId);
                                    });
                                  }
                                },
                                onTap: () {
                                  if (_isSelectionMode) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedMessageIds.remove(messageId);
                                        if (_selectedMessageIds.isEmpty) {
                                          _isSelectionMode = false;
                                        }
                                      } else {
                                        _selectedMessageIds.add(messageId);
                                      }
                                    });
                                  }
                                },
                                child: Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isMe 
                                              ? AppTheme.primaryColor.withOpacity(0.7)
                                              : (isDark ? Color(0xFF1F2937).withOpacity(0.7) : (Colors.grey[200] ?? Colors.grey).withOpacity(0.7)))
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isSelected
                                          ? Border.all(
                                              color: AppTheme.primaryColor,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        // "Bu kişi hikayene yanıt verdi" yazısı (sadece alıcı için)
                                        if (!isMe)
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.primaryColor.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.reply_rounded,
                                                  size: 16,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$senderUsername hikayene yanıt verdi',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        // Story görseli
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: Container(
                                            width: double.infinity,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                            ),
                                            child: storyImageUrl.isNotEmpty
                                                ? Image.network(
                                                    storyImageUrl.startsWith('http')
                                                        ? storyImageUrl
                                                        : '${AppConfig.baseUrl.replaceAll('/api/v1', '')}$storyImageUrl',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.broken_image,
                                                        size: 48,
                                                        color: Colors.grey,
                                                      );
                                                    },
                                                  )
                                                : const Icon(
                                                    Icons.image_outlined,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                          ),
                                        ),
                                        // Story caption (varsa)
                                        if (storyCaption != null && storyCaption.isNotEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.6),
                                            ),
                                            child: Text(
                                              storyCaption,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        // Mesaj içeriği
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? AppTheme.primaryColor
                                                : (isDark ? const Color(0xFF1F2937) : (Colors.grey[200] ?? Colors.grey)),
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_isSelectionMode) ...[
                                                Icon(
                                                  isSelected
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : (isDark ? Colors.white54 : Colors.grey[600]),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Flexible(
                                                child: Text(
                                                  content,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    color: isMe ? Colors.white : (isDark ? Colors.white : AppTheme.textPrimary),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Normal mesaj
                            return GestureDetector(
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedMessageIds.add(messageId);
                                  });
                                }
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedMessageIds.remove(messageId);
                                      if (_selectedMessageIds.isEmpty) {
                                        _isSelectionMode = false;
                                      }
                                    } else {
                                      _selectedMessageIds.add(messageId);
                                    }
                                  });
                                }
                              },
                              child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isMe 
                                            ? AppTheme.primaryColor.withOpacity(0.7)
                                            : (isDark ? Color(0xFF1F2937).withOpacity(0.7) : (Colors.grey[200] ?? Colors.grey).withOpacity(0.7)))
                                        : (isMe
                                      ? AppTheme.primaryColor
                                            : (isDark ? const Color(0xFF1F2937) : (Colors.grey[200] ?? Colors.grey))),
                                  borderRadius: BorderRadius.circular(20).copyWith(
                                    bottomRight: isMe ? const Radius.circular(4) : null,
                                    bottomLeft: !isMe ? const Radius.circular(4) : null,
                                  ),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppTheme.primaryColor,
                                            width: 2,
                                          )
                                        : null,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isSelectionMode) ...[
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white54 : Colors.grey[600]),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                child: Text(
                                  content,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: isMe ? Colors.white : (isDark ? Colors.white : AppTheme.textPrimary),
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
          ),
          if (!_isSelectionMode)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF111827) : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedMessageIds.length} mesaj seçildi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedMessageIds.clear();
                      });
                    },
                    child: Text(
                      'İptal',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                      ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

