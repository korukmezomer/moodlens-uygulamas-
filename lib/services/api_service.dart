import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class ApiService {
  late Dio _dio;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getStoredToken();
        print('🔑 Token check: ${token != null ? "Token exists (${token.length} chars)" : "No token"}');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 Authorization header set');
        } else {
          print('⚠️ No token available for request: ${options.path}');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Sadece 401 (Unauthorized) durumunda token'ı temizle
        // 403 (Forbidden) farklı bir durum - yetki yok ama token geçerli olabilir
        if (error.response?.statusCode == 401) {
          print('🔑 Token expired or invalid (401), clearing auth data');
          clearAuthData();
        } else if (error.response?.statusCode == 403) {
          // 403 durumunda token'ı TEMİZLEME - sadece log yaz
          print('⚠️ 403 Forbidden - Endpoint erişim yetkisi yok');
        } else {
          print('⚠️ Request failed with status: ${error.response?.statusCode}');
          print('⚠️ Request URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
          print('⚠️ Request Method: ${error.requestOptions.method}');
          print('⚠️ Request Data: ${error.requestOptions.data}');
        }
        return handler.next(error);
      },
    ));
  }

  // Auth Methods
  Future<UserModel> register(String username, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      final user = UserModel.fromJson(response.data);
      await storeAuthData(user);
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> login(String usernameOrEmail, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      });

      final user = UserModel.fromJson(response.data);
      await storeAuthData(user);
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await clearAuthData();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _dio.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> updateProfilePicture(File imageFile) async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token yok');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/auth/profile-picture',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data['profilePictureUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Emotion Methods
  Future<Map<String, dynamic>> createEmotionLog({
    required String emotionKey,
    required double confidence,
    required double latitude,
    required double longitude,
    String? rawOutput,
    int? photoId,
  }) async {
    try {
      final token = await getStoredToken();
      print('🎭 Creating emotion log with token: ${token != null ? "Exists" : "MISSING"}');
      
      final response = await _dio.post(
        '/emotions/logs', 
        data: {
          'emotionKey': emotionKey,
          'confidence': confidence,
          'latitude': latitude,
          'longitude': longitude,
          if (rawOutput != null) 'rawOutput': rawOutput,
          if (photoId != null) 'photoId': photoId,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          receiveTimeout: const Duration(seconds: 120), // Google Places API için daha uzun timeout
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      print('🎭 Emotion log created successfully');
      return response.data;
    } on DioException catch (e) {
      print('🎭 Emotion log error: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getEmotionLogs() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        print('⚠️ getEmotionLogs: Token yok, boş liste döndürülüyor');
        return [];
      }
      
      final response = await _dio.get('/emotions/logs');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 404) {
        print('⚠️ getEmotionLogs: 403/404 hatası - Endpoint bulunamadı veya yetki yok');
        print('⚠️ Response: ${e.response?.data}');
        // 403/404 hatası durumunda boş liste döndür (kullanıcıyı rahatsız etme)
        return [];
      } else if (e.response?.statusCode == 401) {
        print('⚠️ getEmotionLogs: 401 Unauthorized - Token süresi dolmuş');
        await clearAuthData();
        return [];
      }
      print('❌ getEmotionLogs hatası: ${_handleError(e)}');
      return [];
    } catch (e) {
      print('❌ getEmotionLogs beklenmeyen hata: $e');
      return [];
    }
  }

  // Place Methods
  Future<List<dynamic>> getNearbyPlaces({
    required double lat,
    required double lon,
    int radius = 5000,
  }) async {
    try {
      final response = await _dio.get('/places/nearby', queryParameters: {
        'lat': lat,
        'lon': lon,
        'radius': radius,
      });
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Place details from Google Places API
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        print('⚠️ getPlaceDetails: Token yok');
        return null;
      }
      
      final response = await _dio.get('/places/details', queryParameters: {
        'placeId': placeId,
      });
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print('⚠️ Place details not found for: $placeId');
        return null;
      }
      print('❌ getPlaceDetails hatası: ${_handleError(e)}');
      return null;
    } catch (e) {
      print('❌ getPlaceDetails beklenmeyen hata: $e');
      return null;
    }
  }

  // Recommendation Methods
  Future<List<dynamic>> getRecommendations(int emotionLogId) async {
    try {
      final response = await _dio.get('/recommendations', queryParameters: {
        'emotionLogId': emotionLogId,
      });
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Son önerileri getir (kullanıcının son emotion log'larına göre)
  Future<List<dynamic>> getRecentRecommendations({int limit = 5}) async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        print('⚠️ getRecentRecommendations: Token yok, boş liste döndürülüyor');
        return [];
      }
      
      final response = await _dio.get('/recommendations/recent', queryParameters: {
        'limit': limit,
      });
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('⚠️ 403 Forbidden - Token geçersiz olabilir, yeniden giriş gerekebilir');
        // 403 hatası durumunda boş liste döndür (kullanıcıyı rahatsız etme)
        return [];
      } else if (e.response?.statusCode == 401) {
        print('⚠️ 401 Unauthorized - Token süresi dolmuş, auth data temizleniyor');
        await clearAuthData();
        return [];
      }
      print('❌ Öneriler yüklenirken hata: ${_handleError(e)}');
      return [];
    } catch (e) {
      print('❌ Öneriler yüklenirken beklenmeyen hata: $e');
      return [];
    }
  }

  // Emotion log'a göre önerileri getir (emotion log oluşturulduğunda zaten döner)
  Future<List<dynamic>> getRecommendationsByEmotionLog(int emotionLogId) async {
    try {
      final response = await _dio.get('/recommendations', queryParameters: {
        'emotionLogId': emotionLogId,
      });
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Editör seçimi mekanları getir
  Future<List<dynamic>> getEditorChoicePlaces() async {
    try {
      final response = await _dio.get('/places/editor-choice');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Google Places'den mekan ara
  Future<List<dynamic>> adminSearchPlaces(String query, {double? latitude, double? longitude, int radius = 5000}) async {
    try {
      final response = await _dio.get('/admin/places/search', queryParameters: {
        'query': query,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'radius': radius,
      });
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Editör seçimi toggle
  Future<bool> adminToggleEditorChoice(String placeId) async {
    try {
      final response = await _dio.post('/admin/places/$placeId/toggle-editor-choice');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Tüm editör seçimi mekanları getir
  Future<List<dynamic>> adminGetEditorChoicePlaces() async {
    try {
      final response = await _dio.get('/admin/places/editor-choice');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Dashboard istatistiklerini getir
  Future<Map<String, dynamic>> adminGetDashboardStats() async {
    try {
      final response = await _dio.get('/admin/dashboard/stats');
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Tüm kullanıcıları getir
  Future<List<dynamic>> adminGetAllUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Kullanıcı detaylarını getir
  Future<Map<String, dynamic>> adminGetUserById(int userId) async {
    try {
      final response = await _dio.get('/admin/users/$userId');
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Yeni kullanıcı oluştur
  Future<Map<String, dynamic>> adminCreateUser({
    required String username,
    required String email,
    required String password,
    String role = 'USER',
  }) async {
    try {
      final response = await _dio.post('/admin/users', data: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      });
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Kullanıcı güncelle
  Future<Map<String, dynamic>> adminUpdateUser(
    int userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.put('/admin/users/$userId', data: updates);
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin: Kullanıcı sil
  Future<Map<String, dynamic>> adminDeleteUser(int userId) async {
    try {
      final response = await _dio.delete('/admin/users/$userId');
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Storage Methods
  Future<void> storeAuthData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_completed') ?? false);
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  // Photo Methods
  Future<Map<String, dynamic>> uploadPhoto(String imagePath, {String? device}) async {
    try {
      print('📸 Upload Photo - Starting: $imagePath');
      final fileName = imagePath.split('/').last;
      
      final file = await MultipartFile.fromFile(
        imagePath,
        filename: fileName,
      );
      
      print('📸 File created: ${file.length} bytes');
      
      final formData = FormData.fromMap({
        'file': file,
        if (device != null) 'device': device,
      });

      // Token'ı kontrol et
      final token = await getStoredToken();
      print('📸 Token for upload: ${token != null ? "Exists (${token.length} chars)" : "MISSING!"}');
      
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required. Please login again.');
      }

      print('📸 Sending request to /photos/upload');
      final response = await _dio.post(
        '/photos/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token', // Doğrudan ekle
          },
          responseType: ResponseType.json, // JSON response bekliyoruz
        ),
      );
      print('📸 Request sent with Authorization header');
      
      print('📸 Response Status: ${response.statusCode}');
      print('📸 Response Type: ${response.data.runtimeType}');
      print('📸 Response Data: ${response.data}');
      
      // Response.data tipini kontrol et ve parse et
      dynamic responseData = response.data;
      
      // Eğer String ise JSON parse et
      if (responseData is String) {
        print('📸 Parsing String response as JSON');
        responseData = jsonDecode(responseData);
      }
      
      // Map kontrolü
      if (responseData is Map) {
        print('📸 Response is Map, keys: ${responseData.keys}');
        return Map<String, dynamic>.from(responseData);
      }
      
      print('❌ Unexpected response type: ${responseData.runtimeType}');
      throw Exception('Unexpected response type: ${responseData.runtimeType}');
      
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e, stackTrace) {
      print('❌ Upload Photo Error: $e');
      print('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Place Visit Methods
  Future<Map<String, dynamic>> recordPlaceVisit({
    required String placeExternalId,
    required String placeName,
    String? placeCategory,
    required double latitude,
    required double longitude,
    int? rating,
    String? review,
  }) async {
    try {
      final response = await _dio.post('/visits', data: {
        'placeExternalId': placeExternalId,
        'placeName': placeName,
        if (placeCategory != null) 'placeCategory': placeCategory,
        'latitude': latitude,
        'longitude': longitude,
        if (rating != null) 'rating': rating,
        if (review != null) 'review': review,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserVisits() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        print('⚠️ getUserVisits: Token yok, boş liste döndürülüyor');
        return [];
      }
      
      final response = await _dio.get('/visits');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 404) {
        print('⚠️ getUserVisits: 403/404 hatası - Endpoint bulunamadı veya yetki yok');
        print('⚠️ Response: ${e.response?.data}');
        // 403/404 hatası durumunda boş liste döndür (kullanıcıyı rahatsız etme)
        return [];
      } else if (e.response?.statusCode == 401) {
        print('⚠️ getUserVisits: 401 Unauthorized - Token süresi dolmuş');
        await clearAuthData();
        return [];
      }
      print('❌ getUserVisits hatası: ${_handleError(e)}');
      return [];
    } catch (e) {
      print('❌ getUserVisits beklenmeyen hata: $e');
      return [];
    }
  }

  // Pagination ile ziyaret geçmişini getir
  Future<Map<String, dynamic>> getUserVisitsPaginated({
    required int page,
    required int size,
  }) async {
    try {
      final response = await _dio.get('/visits/paginated', queryParameters: {
        'page': page,
        'size': size,
      });
      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMostVisitedPlaces({int limit = 10}) async {
    try {
      final response = await _dio.get('/visits/favorites', queryParameters: {
        'limit': limit,
      });
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    print('❌ DioException Type: ${error.type}');
    print('❌ DioException Message: ${error.message}');
    
    if (error.response != null) {
      print('❌ Response Status: ${error.response?.statusCode}');
      print('❌ Response Data Type: ${error.response?.data.runtimeType}');
      print('❌ Response Data: ${error.response?.data}');
      
      // Güvenli message çıkarma
      dynamic responseData = error.response?.data;
      String message = 'Bir hata oluştu: ${error.response?.statusCode}';
      
      if (responseData is Map && responseData.containsKey('message')) {
        message = responseData['message']?.toString() ?? message;
      } else if (responseData is String) {
        try {
          final parsed = jsonDecode(responseData);
          if (parsed is Map && parsed.containsKey('message')) {
            message = parsed['message']?.toString() ?? message;
          }
        } catch (e) {
          message = responseData;
        }
      }
      
      return message;
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Bağlantı zaman aşımına uğradı';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Sunucu yanıt vermiyor';
    } else {
      return 'Bağlantı hatası: ${error.message}';
    }
  }

  // Favorite Methods
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearAuthData();
      }
      print('❌ getFavorites hatası: ${_handleError(e)}');
      return [];
    } catch (e) {
      print('❌ getFavorites beklenmeyen hata: $e');
      return [];
    }
  }

  Future<bool> addFavorite({
    required String placeExternalId,
    required String placeName,
    String? placeCategory,
    required double latitude,
    required double longitude,
    String? address,
    double? rating,
    String? imageUrl,
  }) async {
    try {
      await _dio.post('/favorites', data: {
        'placeExternalId': placeExternalId,
        'placeName': placeName,
        'placeCategory': placeCategory,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'rating': rating,
        'imageUrl': imageUrl,
      });
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearAuthData();
      }
      print('❌ addFavorite hatası: ${_handleError(e)}');
      return false;
    } catch (e) {
      print('❌ addFavorite beklenmeyen hata: $e');
      return false;
    }
  }

  Future<bool> removeFavorite(String placeExternalId) async {
    try {
      await _dio.delete('/favorites/$placeExternalId');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearAuthData();
      }
      print('❌ removeFavorite hatası: ${_handleError(e)}');
      return false;
    } catch (e) {
      print('❌ removeFavorite beklenmeyen hata: $e');
      return false;
    }
  }

  Future<bool> isFavorite(String placeExternalId) async {
    try {
      final response = await _dio.get('/favorites/check/$placeExternalId');
      return response.data as bool? ?? false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearAuthData();
      }
      print('❌ isFavorite hatası: ${_handleError(e)}');
      return false;
    } catch (e) {
      print('❌ isFavorite beklenmeyen hata: $e');
      return false;
    }
  }

  // ========== FRIEND METHODS ==========
  
  Future<bool> removeFriend(int friendId) async {
    try {
      final response = await _dio.delete('/friends/$friendId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadMessageCount() async {
    try {
      final response = await _dio.get('/messages/unread-count');
      return (response.data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      return 0;
    }
  }

  // ========== STORY METHODS ==========

  Future<Map<String, dynamic>> createStory(File imageFile, {String? caption}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        if (caption != null) 'caption': caption,
      });

      final response = await _dio.post(
        '/stories/create',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyStories() async {
    try {
      final response = await _dio.get('/stories/my');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getFriendsStories() async {
    try {
      final response = await _dio.get('/stories/friends');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> viewStory(int storyId) async {
    try {
      final response = await _dio.post('/stories/$storyId/view');
      return response.statusCode == 200;
    } on DioException catch (e) {
      // Story view hatası kritik değil, sessizce devam et
      debugPrint('⚠️ Story view hatası: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('⚠️ Story view beklenmeyen hata: $e');
      return false;
    }
  }

  Future<List<dynamic>> getStoryViewers(int storyId) async {
    try {
      final response = await _dio.get('/stories/$storyId/viewers');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addStoryComment(int storyId, String content) async {
    try {
      final response = await _dio.post('/stories/$storyId/comments', data: {
        'content': content,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getStoryComments(int storyId) async {
    try {
      final response = await _dio.get('/stories/$storyId/comments');
      return response.data ?? [];
    } on DioException catch (e) {
      // Story comments hatası kritik değil, boş liste döndür
      debugPrint('⚠️ Story comments hatası: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('⚠️ Story comments beklenmeyen hata: $e');
      return [];
    }
  }

  Future<bool> likeStory(int storyId) async {
    try {
      final response = await _dio.post('/stories/$storyId/like');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> unlikeStory(int storyId) async {
    try {
      final response = await _dio.delete('/stories/$storyId/like');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteStory(int storyId) async {
    try {
      final response = await _dio.delete('/stories/$storyId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ deleteStory hatası: ${_handleError(e)}');
      throw _handleError(e);
    }
  }

  Future<int> getStoryLikeCount(int storyId) async {
    try {
      final response = await _dio.get('/stories/$storyId/likes/count');
      return (response.data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      return 0;
    }
  }

  Future<bool> checkStoryLike(int storyId) async {
    try {
      final response = await _dio.get('/stories/$storyId/likes/check');
      return (response.data['isLiked'] as bool?) ?? false;
    } on DioException catch (e) {
      return false;
    }
  }

  // ========== USER PROFILE METHODS ==========

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserFavorites(int userId) async {
    try {
      final response = await _dio.get('/users/$userId/favorites');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserRecentVisits(int userId, {int limit = 10}) async {
    try {
      final response = await _dio.get('/users/$userId/recent-visits', queryParameters: {'limit': limit});
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      final response = await _dio.get('/users/search', queryParameters: {'query': query.trim()});
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== FRIEND METHODS ==========

  Future<bool> areFriends(int userId) async {
    try {
      final response = await _dio.get('/friends/check/$userId');
      return response.data['areFriends'] ?? false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _handleError(e);
    }
  }

  Future<bool> sendFriendRequest(int userId) async {
    try {
      final response = await _dio.post('/friends/request', data: {'userId': userId});
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getFriends() async {
    try {
      final response = await _dio.get('/friends');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getFriendRequests() async {
    try {
      final response = await _dio.get('/friends/requests');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> acceptFriendRequest(int senderId) async {
    try {
      final response = await _dio.post('/friends/accept', data: {'senderId': senderId});
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> rejectFriendRequest(int senderId) async {
    try {
      final response = await _dio.post('/friends/reject', data: {'senderId': senderId});
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== MESSAGE METHODS ==========

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('/messages/conversations');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getConversation(int otherUserId) async {
    try {
      final response = await _dio.get('/messages/conversation/$otherUserId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> sendMessage(int otherUserId, String content) async {
    try {
      final response = await _dio.post('/messages/send', data: {
        'receiverId': otherUserId,
        'content': content,
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await _dio.delete('/messages/$messageId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteMessages(List<int> messageIds) async {
    try {
      final response = await _dio.delete('/messages/bulk', data: {
        'messageIds': messageIds,
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteConversation(int otherUserId) async {
    try {
      final response = await _dio.delete('/messages/conversations/$otherUserId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Story mesajları
  Future<bool> sendStoryMessage(int storyId, String content) async {
    try {
      final response = await _dio.post('/stories/$storyId/messages', data: {
        'content': content,
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ sendStoryMessage hatası: ${_handleError(e)}');
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getStoryMessages(int storyId) async {
    try {
      final response = await _dio.get('/stories/$storyId/messages');
      return List<dynamic>.from(response.data ?? []);
    } on DioException catch (e) {
      debugPrint('❌ getStoryMessages hatası: ${_handleError(e)}');
      return [];
    }
  }

  // ========== NOTIFICATION METHODS ==========

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      // Backend direkt Long döndürüyor, response.data direkt int olabilir
      if (response.data is int) {
        return response.data as int;
      } else if (response.data is Map) {
        return (response.data['count'] as num?)?.toInt() ?? 0;
      }
      return (response.data as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      return 0;
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await _dio.post('/notifications/$notificationId/read');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await _dio.post('/notifications/read-all');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _dio.delete('/notifications/$notificationId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== USER BLOCK METHODS ==========

  Future<bool> blockUser(int userId) async {
    try {
      final response = await _dio.post('/users/$userId/block');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      final response = await _dio.delete('/users/$userId/block');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== ADMIN EMOTION LOG METHODS ==========

  Future<List<dynamic>> adminGetAllEmotionLogs() async {
    try {
      final response = await _dio.get('/admin/emotion-logs');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin getAllEmotionLogs 400 error: ${e.response?.data}');
      }
      if (e.response?.statusCode == 400) {
        return [];
      }
      throw _handleError(e);
    }
  }

  // ========== ADMIN RECOMMENDATION METHODS ==========

  Future<List<dynamic>> adminGetAllRecommendations() async {
    try {
      final response = await _dio.get('/admin/recommendations');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin getAllRecommendations 400 error: ${e.response?.data}');
      }
      if (e.response?.statusCode == 400) {
        return [];
      }
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> adminGetAllFavorites() async {
    try {
      final response = await _dio.get('/admin/favorites');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin getAllFavorites 400 error: ${e.response?.data}');
      }
      if (e.response?.statusCode == 400) {
        return [];
      }
      throw _handleError(e);
    }
  }

  // ========== ADMIN STORY METHODS ==========

  Future<List<dynamic>> adminGetAllStories() async {
    try {
      final response = await _dio.get('/admin/stories');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin getAllStories 400 error: ${e.response?.data}');
      }
      // 400 hatası durumunda boş liste döndür
      if (e.response?.statusCode == 400) {
        return [];
      }
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> adminGetUserStories(int userId) async {
    try {
      final response = await _dio.get('/admin/stories/user/$userId');
      return response.data ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin getUserStories 400 error: ${e.response?.data}');
      }
      // 400 hatası durumunda boş liste döndür
      if (e.response?.statusCode == 400) {
        return [];
      }
      throw _handleError(e);
    }
  }

  Future<bool> adminDeleteStory(int storyId) async {
    try {
      final response = await _dio.delete('/admin/stories/$storyId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin deleteStory 400 error: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }

  Future<bool> adminDeleteFavorite(int favoriteId) async {
    try {
      final response = await _dio.delete('/admin/favorites/$favoriteId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin deleteFavorite 400 error: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }

  Future<bool> adminDeleteEmotionLog(int emotionLogId) async {
    try {
      final response = await _dio.delete('/admin/emotion-logs/$emotionLogId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin deleteEmotionLog 400 error: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }

  Future<bool> adminDeleteRecommendation(int recommendationId) async {
    try {
      final response = await _dio.delete('/admin/recommendations/$recommendationId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('❌ Admin deleteRecommendation 400 error: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }
}

