import '../models/movie.dart';

class MovieRepository {
  final List<Movie> _movies;

  MovieRepository(this._movies);

  Movie? getById(String id) {
    try {
      return _movies.firstWhere((movie) => movie.id == id);
    } catch (_) {
      return null;
    }
  }
}
