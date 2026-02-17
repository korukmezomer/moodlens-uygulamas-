class RecommendationModel {
  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String? address;
  final String? category;
  final List<String>? tags;
  final double? rating;
  final double? distance; // km cinsinden
  final double? score;
  final String? imageUrl;
  final String? website;
  final String? phone;
  final String? externalId; // Google Places ID

  RecommendationModel({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.category,
    this.tags,
    this.rating,
    this.distance,
    this.score,
    this.imageUrl,
    this.website,
    this.phone,
    this.externalId,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    // distanceMeters varsa km'ye çevir, yoksa distance'ı kullan
    double? distanceKm;
    if (json['distance'] != null) {
      distanceKm = (json['distance'] as num).toDouble();
    } else if (json['distanceMeters'] != null) {
      distanceKm = (json['distanceMeters'] as num).toDouble() / 1000.0;
    }
    
    // İsim için kategori bazlı varsayılan değer
    String name = json['name'] as String? ?? '';
    if (name.isEmpty) {
      final category = json['category'] as String?;
      name = category ?? 'Mekan';
    }
    
    return RecommendationModel(
      id: json['id'] as int? ?? 0,
      name: name,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      category: json['category'] as String?,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : null,
      rating: json['rating'] != null 
          ? (json['rating'] as num).toDouble()
          : null,
      distance: distanceKm,
      score: json['score'] != null
          ? (json['score'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      externalId: json['externalId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'category': category,
      'tags': tags,
      'rating': rating,
      'distance': distance,
      'score': score,
      'imageUrl': imageUrl,
      'website': website,
      'phone': phone,
      'externalId': externalId,
    };
  }
}

