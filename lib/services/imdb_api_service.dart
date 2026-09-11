// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../utils/constants.dart';

class ImdbApiService {
  static const String _baseUrl = ApiConstants.tmdbBaseUrl;
  static const String _imageBaseUrl = ApiConstants.tmdbImageBaseUrl;

  static Map<String, String> get _headers => {
    if (ApiConstants.tmdbAccessToken.isNotEmpty)
      'Authorization': 'Bearer ${ApiConstants.tmdbAccessToken}',
    'Content-Type': 'application/json',
  };

  static bool _warnIfCredentialsMissing() {
    if (!ApiConstants.hasTmdbCredentials) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ TMDB credentials missing! Supply them at build time using:\n'
          '--dart-define=TMDB_API_KEY=YOUR_KEY --dart-define=TMDB_READ_ACCESS_TOKEN=YOUR_TOKEN',
        );
      }
      return false;
    }
    return true;
  }

  static Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final query = <String, String>{
      if (ApiConstants.tmdbApiKey.isNotEmpty) 'api_key': ApiConstants.tmdbApiKey,
      if (queryParameters != null) ...queryParameters,
    };
    final baseUri = Uri.parse('$_baseUrl$path');
    if (query.isEmpty) return baseUri;
    return baseUri.replace(queryParameters: query);
  }

  static Future<List<Movie>> getTrending({String timeWindow = 'day'}) async {
    if (!_warnIfCredentialsMissing()) return [];
    try {
      final response = await http.get(
        _buildUri('/trending/all/$timeWindow'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => _parseMovieFromTmdb(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching trending content: $e');
      }
      return [];
    }
  }

  static Future<List<Movie>> searchContent(String query) async {
    if (!_warnIfCredentialsMissing()) return [];
    try {
      final response = await http.get(
        _buildUri('/search/multi', {'query': query}),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => _parseMovieFromTmdb(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching content: $e');
      }
      return [];
    }
  }

  static Future<List<Movie>> getMoviesByGenre(int genreId) async {
    if (!_warnIfCredentialsMissing()) return [];
    try {
      final response = await http.get(
        _buildUri('/discover/movie', {'with_genres': genreId.toString()}),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => _parseMovieFromTmdb(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching movies by genre: $e');
      }
      return [];
    }
  }

  static Future<List<Movie>> getTVShowsByGenre(int genreId) async {
    if (!_warnIfCredentialsMissing()) return [];
    try {
      final response = await http.get(
        _buildUri('/discover/tv', {'with_genres': genreId.toString()}),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => _parseMovieFromTmdb(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching TV shows by genre: $e');
      }
      return [];
    }
  }

  static Future<List<Movie>> getPopularMovies() async {
    if (!_warnIfCredentialsMissing()) return [];
    try {
      final response = await http.get(
        _buildUri('/movie/popular'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => _parseMovieFromTmdb(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching popular movies: $e');
      }
      return [];
    }
  }

  static Future<List<Movie>> getPopularTVShows() async {
    if (!_warnIfCredentialsMissing()) return [];
    try {
      final response = await http.get(
        _buildUri('/tv/popular'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => _parseMovieFromTmdb(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching popular TV shows: $e');
      }
      return [];
    }
  }

  static Future<List<Movie>> getTopRated(String type) async {
    if (!_warnIfCredentialsMissing()) return [];
    try {
      final response = await http.get(
        _buildUri('/$type/top_rated'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => _parseMovieFromTmdb(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching top rated content: $e');
      }
      return [];
    }
  }

  static Future<Movie?> getContentDetails(String id, String type) async {
    if (!_warnIfCredentialsMissing()) return null;
    try {
      final response = await http.get(
        _buildUri('/$type/$id', {'append_to_response': 'credits'}),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMovieFromTmdb(data, includeCredits: true);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching content details: $e');
      }
      return null;
    }
  }

  static Movie _parseMovieFromTmdb(
    Map<String, dynamic> json, {
    bool includeCredits = false,
  }) {
    String contentType = 'movie';
    if (json['media_type'] == 'tv' || json['first_air_date'] != null) {
      contentType = 'tv';
    }

    String title = json['title'] ?? json['name'] ?? 'Unknown Title';
    String? releaseDate = json['release_date'] ?? json['first_air_date'];

    String? posterUrl;
    if (json['poster_path'] != null) {
      posterUrl = '$_imageBaseUrl${json['poster_path']}';
    }

    List<String> genres = [];
    if (json['genres'] != null) {
      genres = (json['genres'] as List)
          .map((g) => g['name']?.toString() ?? '')
          .toList();
    } else if (json['genre_ids'] != null) {
      final genreMap = {
        28: 'Action',
        12: 'Adventure',
        16: 'Animation',
        35: 'Comedy',
        80: 'Crime',
        99: 'Documentary',
        18: 'Drama',
        10751: 'Family',
        14: 'Fantasy',
        36: 'History',
        27: 'Horror',
        10402: 'Music',
        9648: 'Mystery',
        10749: 'Romance',
        878: 'Science Fiction',
        10770: 'TV Movie',
        53: 'Thriller',
        10752: 'War',
        37: 'Western',
      };
      genres = (json['genre_ids'] as List)
          .map((id) => genreMap[id] ?? 'Unknown')
          .toList();
    }

    List<String> cast = [];
    List<String> directors = [];
    if (includeCredits && json['credits'] != null) {
      if (json['credits']['cast'] != null) {
        cast = (json['credits']['cast'] as List)
            .take(5)
            .map((c) => c['name']?.toString() ?? '')
            .toList();
      }
      if (json['credits']['crew'] != null) {
        directors = (json['credits']['crew'] as List)
            .where((c) => c['job'] == 'Director')
            .map((c) => c['name']?.toString() ?? '')
            .toList();
      }
    }

    String? runtime;
    if (json['runtime'] != null) {
      runtime = '${json['runtime']} min';
    } else if (json['episode_run_time'] != null &&
        (json['episode_run_time'] as List).isNotEmpty) {
      runtime = '${json['episode_run_time'][0]} min/episode';
    }

    return Movie(
      id: json['id']?.toString() ?? '',
      title: title,
      posterUrl: posterUrl,
      overview: json['overview'],
      rating: json['vote_average']?.toDouble(),
      releaseDate: releaseDate != null ? releaseDate.split('-')[0] : null,
      genres: genres,
      runtime: runtime,
      certificate: _getCertificate(json['adult'] ?? false),
      contentType: contentType,
      cast: cast,
      directors: directors,
    );
  }

  static String _getCertificate(bool isAdult) {
    return isAdult ? 'R' : 'PG-13';
  }

  // 🔻 ADD THESE TO SUPPORT RecommendationProvider 🔻

  static Future<List<Movie>> getTopTitles({
    String? genre,
    String? contentType,
    int limit = 10,
  }) async {
    final genreMap = {
      'Action': 28,
      'Adventure': 12,
      'Animation': 16,
      'Comedy': 35,
      'Crime': 80,
      'Documentary': 99,
      'Drama': 18,
      'Family': 10751,
      'Fantasy': 14,
      'History': 36,
      'Horror': 27,
      'Music': 10402,
      'Mystery': 9648,
      'Romance': 10749,
      'Science Fiction': 878,
      'TV Movie': 10770,
      'Thriller': 53,
      'War': 10752,
      'Western': 37,
    };

    int? genreId = genreMap[genre ?? ''];
    List<Movie> results = [];

    if (genreId != null) {
      if (contentType == 'tv') {
        results = await getTVShowsByGenre(genreId);
      } else {
        results = await getMoviesByGenre(genreId);
      }
    } else {
      results = await getTopRated(contentType ?? 'movie');
    }

    return results.take(limit).toList();
  }

  static Future<List<Movie>> getTrendingTitles() async {
    return await getTrending();
  }

  static Future<List<Movie>> searchTitles(String query) async {
    return await searchContent(query);
  }

  static Future<Map<String, dynamic>?> getTitleCredits(
    String id, {
    String type = 'movie',
  }) async {
    final movie = await getContentDetails(id, type);
    if (movie != null) {
      return {'cast': movie.cast, 'directors': movie.directors};
    }
    return null;
  }
}
