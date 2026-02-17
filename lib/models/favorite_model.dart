class FavoriteModel {
  final int id;
  final String placeExternalId;
  final String placeName;
  final String? placeCategory;
  final double latitude;
  final double longitude;
  final String? address;
  final double? rating;
  final String? imageUrl;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.placeExternalId,
    required this.placeName,
    this.placeCategory,
    required this.latitude,
    required this.longitude,
    this.address,
    this.rating,
    this.imageUrl,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as int,
      placeExternalId: json['placeExternalId'] as String,
      placeName: json['placeName'] as String,
      placeCategory: json['placeCategory'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeExternalId': placeExternalId,
      'placeName': placeName,
      'placeCategory': placeCategory,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'rating': rating,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

