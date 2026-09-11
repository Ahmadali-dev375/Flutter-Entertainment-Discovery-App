// ignore_for_file: avoid_print, null_check_always_fails, unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync complete watchlist to Firebase with full movie objects
  static Future<bool> syncWatchlistToFirebase(
    String uid,
    List<Movie> localWatchlist,
  ) async {
    try {
      print('📤 Syncing ${localWatchlist.length} movies to Firebase...');

      // Convert movies to the desired structure with complete data
      // Use DateTime.now() instead of FieldValue.serverTimestamp() inside arrays
      final currentTime = DateTime.now();
      final movieMaps = localWatchlist
          .map(
            (movie) => {
              'id': movie.id,
              'title': movie.title,
              'overview': movie.overview,
              'posterUrl': movie.posterUrl,
              'releaseDate': movie.releaseDate,
              'rating': movie.rating,
              'genres': movie.genres,
              'addedAt': Timestamp.fromDate(
                currentTime,
              ), // Use Timestamp instead
            },
          )
          .toList();

      final userDocRef = _firestore.collection('users').doc(uid);
      await _ensureUserDocumentExists(uid);

      // Store complete movie objects in watchlist array
      await userDocRef.update({
        'watchlist': movieMaps,
        'lastWatchlistSync':
            FieldValue.serverTimestamp(), // This is fine - not inside array
      });

      print(
        '✅ Successfully synced ${movieMaps.length} complete movies to Firebase',
      );
      return true;
    } catch (e) {
      print('❌ Error syncing watchlist to Firebase: $e');
      return false;
    }
  }

  /// Fetch watchlist from Firebase (gets complete movie objects directly)
  static Future<List<Movie>> fetchWatchlistFromFirebase(String uid) async {
    try {
      print('☁️ Fetching watchlist for user: $uid');

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        print('⚠️ User document does not exist');
        return [];
      }

      final data = doc.data();
      if (data == null || !data.containsKey('watchlist')) {
        print('⚠️ Watchlist field does not exist');
        return [];
      }

      final watchlistData = data['watchlist'] as List<dynamic>? ?? [];
      final movies = <Movie>[];

      for (final item in watchlistData) {
        if (item is Map<String, dynamic>) {
          try {
            // Convert Firebase data back to Movie object
            final movie = Movie(
              id: item['id'] ?? '',
              title: item['title'] ?? '',
              overview: item['overview'] ?? '',
              posterUrl: item['posterUrl'],
              releaseDate: item['releaseDate'] ?? '',
              rating: (item['rating'] ?? 0.0).toDouble(),
              genres: _parseGenres(item['genres']),
            );
            movies.add(movie);
          } catch (e) {
            print('❌ Error parsing movie object: $e');
          }
        } else if (item is String) {
          // Handle legacy format - just skip for now
          print('⚠️ Found legacy movie ID format: $item');
        }
      }

      print('☁️ Successfully fetched ${movies.length} movies from Firebase');
      return movies;
    } catch (e) {
      print('❌ Error fetching watchlist from Firebase: $e');
      return [];
    }
  }

  /// Add single movie to Firebase watchlist (stores complete movie object)
  static Future<bool> addMovieToFirebaseWatchlist(
    String uid,
    Movie movie,
  ) async {
    try {
      await _ensureUserDocumentExists(uid);

      // Use current timestamp instead of server timestamp
      final movieMap = {
        'id': movie.id,
        'title': movie.title,
        'overview': movie.overview,
        'posterUrl': movie.posterUrl,
        'releaseDate': movie.releaseDate,
        'rating': movie.rating,
        'genres': movie.genres,
        'addedAt': Timestamp.fromDate(DateTime.now()), // Fixed: Use Timestamp
      };

      final userDocRef = _firestore.collection('users').doc(uid);

      // Check if movie already exists
      final doc = await userDocRef.get();
      final data = doc.data();
      final watchlist = data?['watchlist'] as List<dynamic>? ?? [];

      final exists = watchlist.any(
        (item) => item is Map<String, dynamic> && item['id'] == movie.id,
      );

      if (!exists) {
        await userDocRef.update({
          'watchlist': FieldValue.arrayUnion([movieMap]),
          'lastWatchlistSync': FieldValue.serverTimestamp(),
        });
        print('✅ Added movie ${movie.title} to Firebase watchlist');
      } else {
        print('⚠️ Movie ${movie.title} already exists in watchlist');
      }

      return true;
    } catch (e) {
      print('❌ Error adding movie to Firebase watchlist: $e');
      return false;
    }
  }

  /// Remove movie from Firebase watchlist (removes complete movie object)
  static Future<bool> removeMovieFromFirebaseWatchlist(
    String uid,
    String movieId,
  ) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final doc = await userDocRef.get();

      if (!doc.exists) {
        print('⚠️ User document does not exist');
        return false;
      }

      final data = doc.data();
      final watchlist = data?['watchlist'] as List<dynamic>? ?? [];

      // Filter out the movie to remove
      final updatedWatchlist = watchlist.where((item) {
        if (item is Map<String, dynamic>) {
          return item['id'] != movieId;
        }
        if (item is String) {
          return item != movieId; // Handle legacy format
        }
        return true;
      }).toList();

      await userDocRef.update({
        'watchlist': updatedWatchlist,
        'lastWatchlistSync': FieldValue.serverTimestamp(),
      });

      print('✅ Removed movie $movieId from Firebase watchlist');
      return true;
    } catch (e) {
      print('❌ Error removing movie from Firebase watchlist: $e');
      return false;
    }
  }

  /// Create or update user document with profile information
  static Future<void> ensureUserDocument(
    String uid, {
    String? name,
    String? email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await userDocRef.set({
          'uid': uid,
          'name': name ?? displayName ?? 'User',
          'email': email ?? '',
          'displayName': displayName ?? name ?? 'User',
          'photoURL': photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'preferences': {
            'favoriteGenres': <String>[],
            'favoriteActors': <String>[],
            'favoriteDirectors': <String>[],
            'favoriteTitles': <String>[],
          },
          'watchlist':
              <Map<String, dynamic>>[], // Array of complete movie objects
          'watchHistory':
              <Map<String, dynamic>>[], // Array of complete movie objects
        });
        print('✅ Created user document for $uid');
      } else {
        // Update existing document
        await userDocRef.update({
          'lastSignIn': FieldValue.serverTimestamp(),
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (displayName != null) 'displayName': displayName,
          if (photoURL != null) 'photoURL': photoURL,
        });
        print('✅ Updated user document for $uid');
      }
    } catch (e) {
      print('❌ Error ensuring user document: $e');
    }
  }

  /// Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTime(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final timestamp = data?['lastWatchlistSync'] as Timestamp?;
        return timestamp?.toDate();
      }
    } catch (e) {
      print('❌ Error getting last sync time: $e');
    }
    return null;
  }

  /// Migrate legacy watchlist format (ID-only) to complete objects
  static Future<bool> migrateUserWatchlist(
    String uid,
    List<Movie> localMovies,
  ) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final watchlist = data?['watchlist'] as List<dynamic>? ?? [];

      // Check if migration is needed
      final needsMigration = watchlist.any((item) => item is String);
      if (!needsMigration) {
        print('ℹ️ No migration needed - watchlist already in new format');
        return false;
      }

      print('🔄 Migrating watchlist from ID-only to complete objects...');
      final migratedWatchlist = <Map<String, dynamic>>[];
      final currentTime = DateTime.now();

      for (final item in watchlist) {
        if (item is String) {
          // Find complete movie data from local storage
          final movie = localMovies.firstWhere(
            (m) => m.id == item,
            orElse: () => null!,
          );

          if (movie != null) {
            migratedWatchlist.add({
              'id': movie.id,
              'title': movie.title,
              'overview': movie.overview,
              'posterUrl': movie.posterUrl,
              'releaseDate': movie.releaseDate,
              'rating': movie.rating,
              'genres': movie.genres,
              'addedAt': Timestamp.fromDate(
                currentTime,
              ), // Fixed: Use Timestamp
            });
          } else {
            print('⚠️ Could not find local movie data for ID: $item');
          }
        } else if (item is Map<String, dynamic>) {
          // Already in new format
          migratedWatchlist.add(item);
        }
      }

      // Update Firebase with migrated data
      await _firestore.collection('users').doc(uid).update({
        'watchlist': migratedWatchlist,
        'lastWatchlistSync': FieldValue.serverTimestamp(),
        'migrated': true,
      });

      print('✅ Successfully migrated ${migratedWatchlist.length} movies');
      return true;
    } catch (e) {
      print('❌ Error during migration: $e');
      return false;
    }
  }

  /// Private helper to ensure user document exists
  static Future<void> _ensureUserDocumentExists(String uid) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await userDocRef.set({
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'watchlist':
              <Map<String, dynamic>>[], // Array of complete movie objects
          'watchHistory':
              <Map<String, dynamic>>[], // Array of complete movie objects
          'preferences': {
            'favoriteGenres': <String>[],
            'favoriteActors': <String>[],
            'favoriteDirectors': <String>[],
            'favoriteTitles': <String>[],
          },
        });
        print('✅ Auto-created user document for $uid');
      }
    } catch (e) {
      print('❌ Error auto-creating user document: $e');
    }
  }

  /// Helper to parse genres from different formats
  static List<String> _parseGenres(dynamic genres) {
    if (genres == null) return [];

    if (genres is List<String>) {
      return genres;
    } else if (genres is List<int>) {
      return genres.map((id) => id.toString()).toList();
    } else if (genres is List) {
      return genres.map((item) => item.toString()).toList();
    }

    return [];
  }
}
