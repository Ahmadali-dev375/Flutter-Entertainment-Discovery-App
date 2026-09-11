import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';
import '../models/user_preferences.dart';

class LocalStorageService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'qselect.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE watchlist (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            posterUrl TEXT,
            overview TEXT,
            rating REAL,
            releaseDate TEXT,
            genres TEXT,
            runtime TEXT,
            certificate TEXT,
            contentType TEXT,
            cast TEXT,
            directors TEXT,
            addedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE watch_history (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            posterUrl TEXT,
            overview TEXT,
            rating REAL,
            releaseDate TEXT,
            genres TEXT,
            runtime TEXT,
            certificate TEXT,
            contentType TEXT,
            cast TEXT,
            directors TEXT,
            watchedAt TEXT
          )
        ''');
      },
    );
  }

  static Future<void> resetDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static const String _watchlistOwnerKey = 'watchlist_owner_uid';

  /// Returns the UID of the user who owns the current local watchlist, or null if guest/unowned.
  static Future<String?> getWatchlistOwner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_watchlistOwnerKey);
  }

  /// Sets the UID of the user who owns the current local watchlist.
  static Future<void> setWatchlistOwner(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid != null) {
      await prefs.setString(_watchlistOwnerKey, uid);
    } else {
      await prefs.remove(_watchlistOwnerKey);
    }
  }

  /// Clears all items in the local SQLite watchlist table.
  static Future<void> clearWatchlist() async {
    final db = await database;
    await db.delete('watchlist');
  }

  static Future<void> saveWatchlistIds(List<String> watchlist) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('watchlist', watchlist);
  }

  static Future<List<String>> getWatchlistIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('watchlist') ?? [];
  }

  static Future<void> addToWatchlist(Movie movie) async {
    final db = await database;
    await db.insert('watchlist', {
      ...movie.toJson(),
      'addedAt': DateTime.now().toIso8601String(),
      'genres': jsonEncode(movie.genres),
      'cast': jsonEncode(movie.cast),
      'directors': jsonEncode(movie.directors),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> removeFromWatchlist(String movieId) async {
    final db = await database;
    await db.delete('watchlist', where: 'id = ?', whereArgs: [movieId]);
  }

  static Future<List<Movie>> getWatchlistMovies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('watchlist');

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      map['genres'] = _parseStringList(map['genres']);
      map['cast'] = _parseStringList(map['cast']);
      map['directors'] = _parseStringList(map['directors']);
      return Movie.fromJson(map);
    });
  }

  static Future<bool> isInWatchlist(String movieId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'watchlist',
      where: 'id = ?',
      whereArgs: [movieId],
    );
    return maps.isNotEmpty;
  }

  static Future<Movie?> getMovieById(String id) async {
    final db = await database;
    final maps = await db.query(
      'watchlist',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final map = Map<String, dynamic>.from(maps.first);
      map['genres'] = _parseStringList(map['genres']);
      map['cast'] = _parseStringList(map['cast']);
      map['directors'] = _parseStringList(map['directors']);
      return Movie.fromJson(map);
    }

    return null;
  }

  static Future<void> addToWatchHistory(Movie movie) async {
    final db = await database;
    await db.insert('watch_history', {
      ...movie.toJson(),
      'watchedAt': DateTime.now().toIso8601String(),
      'genres': jsonEncode(movie.genres),
      'cast': jsonEncode(movie.cast),
      'directors': jsonEncode(movie.directors),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Movie>> getWatchHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'watch_history',
      orderBy: 'watchedAt DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      map['genres'] = _parseStringList(map['genres']);
      map['cast'] = _parseStringList(map['cast']);
      map['directors'] = _parseStringList(map['directors']);
      return Movie.fromJson(map);
    });
  }

  static Future<void> saveUserPreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPreferences', jsonEncode(preferences.toJson()));
  }

  static Future<UserPreferences> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsString = prefs.getString('userPreferences');
    if (prefsString != null) {
      return UserPreferences.fromJson(jsonDecode(prefsString));
    }
    return UserPreferences();
  }

  /// ✅ NEW: Replace local watchlist entirely with a new list of Movie objects
  static Future<void> saveWatchlist(List<Movie> movies) async {
    final db = await database;

    // Clear existing local watchlist
    await db.delete('watchlist');

    // Insert each movie into the watchlist
    for (final movie in movies) {
      await db.insert('watchlist', {
        ...movie.toJson(),
        'addedAt': DateTime.now().toIso8601String(),
        'genres': jsonEncode(movie.genres),
        'cast': jsonEncode(movie.cast),
        'directors': jsonEncode(movie.directors),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// ✅ Helper: Parse JSON list safely
  static List<String> _parseStringList(dynamic value) {
    try {
      if (value == null) return [];
      if (value is String) {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } else if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Optionally log error
    }
    return [];
  }
}
