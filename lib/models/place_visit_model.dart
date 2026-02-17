class PlaceVisitModel {
  final int? id;
  final String placeExternalId;
  final String placeName;
  final String? placeCategory;
  final double latitude;
  final double longitude;
  final DateTime visitedAt;
  final int? rating;
  final String? review;
  final int? visitCount;

  PlaceVisitModel({
    this.id,
    required this.placeExternalId,
    required this.placeName,
    this.placeCategory,
    required this.latitude,
    required this.longitude,
    required this.visitedAt,
    this.rating,
    this.review,
    this.visitCount,
  });

  factory PlaceVisitModel.fromJson(Map<String, dynamic> json) {
    return PlaceVisitModel(
      id: json['id'] as int?,
      placeExternalId: json['placeExternalId'] as String,
      placeName: json['placeName'] as String,
      placeCategory: json['placeCategory'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      rating: json['rating'] as int?,
      review: json['review'] as String?,
      visitCount: json['visitCount'] as int?,
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
      'visitedAt': visitedAt.toIso8601String(),
      'rating': rating,
      'review': review,
      'visitCount': visitCount,
    };
  }
}

