import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user_preferences.dart';
import '../services/imdb_api_service.dart';
import '../services/local_storage_service.dart';

enum RecommendationMode { mood, type, preferences, trending }

class RecommendationProvider with ChangeNotifier {
  List<Movie> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  RecommendationMode _currentMode = RecommendationMode.trending;
  UserPreferences _userPreferences = UserPreferences();

  List<Movie> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  RecommendationMode get currentMode => _currentMode;
  UserPreferences get userPreferences => _userPreferences;

  RecommendationProvider() {
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    _userPreferences = await LocalStorageService.getUserPreferences();
    notifyListeners();
  }

  Future<void> getRecommendationsByMood(String mood) async {
    _setLoading(true);
    _currentMode = RecommendationMode.mood;

    try {
      final genreMap = {
        'happy': ['Comedy', 'Musical', 'Family'],
        'sad': ['Drama', 'Romance'],
        'excited': ['Action', 'Adventure', 'Thriller'],
        'chill': ['Documentary', 'Biography'],
        'scared': ['Horror', 'Thriller'],
        'romantic': ['Romance', 'Comedy'],
      };

      final genres = genreMap[mood.toLowerCase()] ?? ['Drama'];
      final results = <Movie>[];

      for (final genre in genres) {
        final movies = await ImdbApiService.getTopTitles(
          genre: genre,
          limit: 10,
        );
        results.addAll(movies);
      }

      _recommendations = results.take(20).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to get mood recommendations';
      _recommendations = [];
    }

    _setLoading(false);
  }

  Future<void> getRecommendationsByType(String type) async {
    _setLoading(true);
    _currentMode = RecommendationMode.type;

    try {
      String? contentType;
      String? genre;

      switch (type.toLowerCase()) {
        case 'family':
          genre = 'Family';
          break;
        case 'couple':
          genre = 'Romance';
          break;
        case 'kids':
          genre = 'Animation';
          break;
        case '18+':
          // Handle age verification logic here
          break;
      }

      _recommendations = await ImdbApiService.getTopTitles(
        genre: genre,
        contentType: contentType,
        limit: 20,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to get type recommendations';
      _recommendations = [];
    }

    _setLoading(false);
  }

  Future<void> getRecommendationsByPreferences() async {
    _setLoading(true);
    _currentMode = RecommendationMode.preferences;

    try {
      final results = <Movie>[];

      // Get recommendations based on user's favorite genres
      for (final genre in _userPreferences.favoriteGenres) {
        final movies = await ImdbApiService.getTopTitles(
          genre: genre,
          limit: 5,
        );
        results.addAll(movies);
      }

      _recommendations = results.take(20).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to get preference recommendations';
      _recommendations = [];
    }

    _setLoading(false);
  }

  Future<void> getTrendingRecommendations() async {
    _setLoading(true);
    _currentMode = RecommendationMode.trending;

    try {
      _recommendations = await ImdbApiService.getTrendingTitles();
      _error = null;
    } catch (e) {
      _error = 'Failed to get trending recommendations';
      _recommendations = [];
    }

    _setLoading(false);
  }

  Future<void> smartPreferenceFinder(List<String> favoriteTitles) async {
    _setLoading(true);

    try {
      final genres = <String>[];
      final actors = <String>[];
      final directors = <String>[];

      for (final title in favoriteTitles) {
        final searchResults = await ImdbApiService.searchTitles(title);
        if (searchResults.isNotEmpty) {
          final movie = searchResults.first;
          genres.addAll(movie.genres);

          final credits = await ImdbApiService.getTitleCredits(movie.id);
          if (credits != null) {
            // Process credits to extract actors and directors
            // This would need to be implemented based on the actual API response structure
          }
        }
      }

      // Update user preferences
      _userPreferences = _userPreferences.copyWith(
        favoriteGenres: genres.toSet().toList(),
        favoriteActors: actors.toSet().toList(),
        favoriteDirectors: directors.toSet().toList(),
        favoriteTitles: favoriteTitles,
      );

      await LocalStorageService.saveUserPreferences(_userPreferences);
      await getRecommendationsByPreferences();
    } catch (e) {
      _error = 'Failed to analyze preferences';
    }

    _setLoading(false);
  }

  Future<void> applyFilters({
    String? genre,
    String? language,
    String? contentType,
    String? certificate,
    double? minRating,
    double? maxRating,
    int? minYear,
    int? maxYear,
  }) async {
    _setLoading(true);

    try {
      // If no recommendations exist, fetch new ones based on genre
      if (_recommendations.isEmpty && genre != null) {
        _recommendations = await ImdbApiService.getTopTitles(
          genre: genre,
          limit: 50,
        );
      } else if (_recommendations.isEmpty) {
        // Get trending if no genre specified
        _recommendations = await ImdbApiService.getTrendingTitles();
      }

      // Filter current recommendations based on criteria
      List<Movie> filteredMovies = _recommendations.where((movie) {
        // Genre filter
        if (genre != null &&
            !movie.genres.any(
              (g) => g.toLowerCase().contains(genre.toLowerCase()),
            )) {
          return false;
        }

        // Content type filter
        if (contentType != null &&
            !movie
                .contentType! //*********** */
                .toLowerCase()
                .contains(contentType.toLowerCase())) {
          return false;
        }

        // Certificate filter
        if (certificate != null && movie.certificate != certificate) {
          return false;
        }

        // Rating filter
        if (movie.rating != null) {
          if (minRating != null && movie.rating! < minRating) {
            return false;
          }
          if (maxRating != null && movie.rating! > maxRating) {
            return false;
          }
        }

        // Year filter
        if (movie.releaseDate != null) {
          final year = int.tryParse(movie.releaseDate!);
          if (year != null) {
            if (minYear != null && year < minYear) {
              return false;
            }
            if (maxYear != null && year > maxYear) {
              return false;
            }
          }
        }

        return true;
      }).toList();

      _recommendations = filteredMovies;
      _error = null;
    } catch (e) {
      _error = 'Failed to apply filters';
    }

    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
