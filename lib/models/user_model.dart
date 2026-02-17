class UserModel {
  final String token;
  final String username;
  final String email;
  final int userId;
  final String role;
  final String? profilePictureUrl;

  UserModel({
    required this.token,
    required this.username,
    required this.email,
    required this.userId,
    required this.role,
    this.profilePictureUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'] ?? 0,
      role: json['role'] ?? 'USER',
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'username': username,
      'email': email,
      'userId': userId,
      'role': role,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  UserModel copyWith({
    String? token,
    String? username,
    String? email,
    int? userId,
    String? role,
    String? profilePictureUrl,
  }) {
    return UserModel(
      token: token ?? this.token,
      username: username ?? this.username,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isUser => role == 'USER';
}

