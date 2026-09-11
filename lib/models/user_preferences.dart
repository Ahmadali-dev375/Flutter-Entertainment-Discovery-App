class UserPreferences {
  final List<String> favoriteGenres;
  final List<String> favoriteActors;
  final List<String> favoriteDirectors;
  final List<String> favoriteTitles;
  final String preferredLanguage;
  final String preferredContentType;

  UserPreferences({
    this.favoriteGenres = const [],
    this.favoriteActors = const [],
    this.favoriteDirectors = const [],
    this.favoriteTitles = const [],
    this.preferredLanguage = 'English',
    this.preferredContentType = 'movie',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      favoriteGenres: List<String>.from(json['favoriteGenres'] ?? []),
      favoriteActors: List<String>.from(json['favoriteActors'] ?? []),
      favoriteDirectors: List<String>.from(json['favoriteDirectors'] ?? []),
      favoriteTitles: List<String>.from(json['favoriteTitles'] ?? []),
      preferredLanguage: json['preferredLanguage'] ?? 'English',
      preferredContentType: json['preferredContentType'] ?? 'movie',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteGenres': favoriteGenres,
      'favoriteActors': favoriteActors,
      'favoriteDirectors': favoriteDirectors,
      'favoriteTitles': favoriteTitles,
      'preferredLanguage': preferredLanguage,
      'preferredContentType': preferredContentType,
    };
  }

  UserPreferences copyWith({
    List<String>? favoriteGenres,
    List<String>? favoriteActors,
    List<String>? favoriteDirectors,
    List<String>? favoriteTitles,
    String? preferredLanguage,
    String? preferredContentType,
  }) {
    return UserPreferences(
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      favoriteActors: favoriteActors ?? this.favoriteActors,
      favoriteDirectors: favoriteDirectors ?? this.favoriteDirectors,
      favoriteTitles: favoriteTitles ?? this.favoriteTitles,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredContentType: preferredContentType ?? this.preferredContentType,
    );
  }
}
