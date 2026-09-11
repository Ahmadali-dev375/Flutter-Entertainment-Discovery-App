import 'dart:convert';

class Movie {
  final String id;
  final String title;
  final String? posterUrl;
  final String? overview;
  final double? rating;
  final String? releaseDate;
  final List<String> genres;
  final String? runtime;
  final String? certificate;
  final String? contentType;
  final List<String> cast;
  final List<String> directors;

  Movie({
    required this.id,
    required this.title,
    this.posterUrl,
    this.overview,
    this.rating,
    this.releaseDate,
    this.genres = const [],
    this.runtime,
    this.certificate,
    this.contentType,
    this.cast = const [],
    this.directors = const [],
  });

  /// ✅ Save to Firestore or local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'overview': overview,
      'rating': rating,
      'releaseDate': releaseDate,
      'genres': genres, // Safe: List<String>
      'runtime': runtime,
      'certificate': certificate,
      'contentType': contentType,
      'cast': cast, // Safe: List<String>
      'directors': directors, // Safe: List<String>
    };
  }

  /// ✅ Load from Firestore or local storage
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      posterUrl: json['posterUrl'] ?? json['posterPath'], // ✅ fallback
      overview: json['overview'],
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : null,
      releaseDate: json['releaseDate'],
      genres: _parseList(json['genres']),
      runtime: json['runtime'],
      certificate: json['certificate'],
      contentType: json['contentType'],
      cast: _parseList(json['cast']),
      directors: _parseList(json['directors']),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return List<String>.from(decoded);
      } catch (e) {
        // Not a valid JSON string list
      }
    }
    return [];
  }
}
