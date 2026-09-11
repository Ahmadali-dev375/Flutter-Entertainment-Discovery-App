class ApiConstants {
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const String tmdbAccessToken = String.fromEnvironment(
    'TMDB_READ_ACCESS_TOKEN',
    defaultValue: String.fromEnvironment('TMDB_ACCESS_TOKEN'),
  );
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  /// True if at least one TMDB credential was provided at build time via --dart-define.
  static bool get hasTmdbCredentials =>
      tmdbApiKey.isNotEmpty || tmdbAccessToken.isNotEmpty;
}
