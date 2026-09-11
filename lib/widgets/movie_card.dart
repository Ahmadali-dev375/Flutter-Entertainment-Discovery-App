// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onWatchlistChanged;

  const MovieCard({super.key, required this.movie, this.onWatchlistChanged});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isInWatchlist = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _checkWatchlistStatus();
  }

  Future<void> _checkWatchlistStatus() async {
    try {
      final isInWatchlist = await LocalStorageService.isInWatchlist(
        widget.movie.id,
      );
      if (mounted) {
        setState(() => _isInWatchlist = isInWatchlist);
      }
    } catch (e) {
      print('❌ Error checking watchlist status: $e');
    }
  }

  /// ✅ FIXED: Complete sync logic for watchlist changes
  Future<void> _toggleWatchlist() async {
    if (_isUpdating) return; // Prevent multiple concurrent updates

    setState(() => _isUpdating = true);

    try {
      if (_isInWatchlist) {
        // Remove from local storage
        await LocalStorageService.removeFromWatchlist(widget.movie.id);
        print('📱 Removed ${widget.movie.title} from local storage');
      } else {
        // Add to local storage
        await LocalStorageService.addToWatchlist(widget.movie);
        print('📱 Added ${widget.movie.title} to local storage');
      }

      // Update local state
      setState(() => _isInWatchlist = !_isInWatchlist);

      // Sync with Firebase if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final allLocalMovies = await LocalStorageService.getWatchlistMovies();
        await FirebaseService.syncWatchlistToFirebase(user.uid, allLocalMovies);
        print('☁️ Synced watchlist changes to Firebase');
      }

      // Notify parent widget to refresh
      widget.onWatchlistChanged?.call();
    } catch (e) {
      print('❌ Error toggling watchlist: $e');
      // Revert local state on error
      setState(() => _isInWatchlist = !_isInWatchlist);

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update watchlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3.2,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showMovieDetails(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top image
                  SizedBox(
                    height: constraints.maxHeight * 0.65, // 65% image
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.movie.posterUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.movie.posterUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.movie, size: 48),
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.movie, size: 48),
                              ),
                        // Bookmark button with loading state
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _isUpdating
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.amber,
                                            ),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      _isInWatchlist
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: Colors.amber,
                                    ),
                                    onPressed: _toggleWatchlist,
                                  ),
                          ),
                        ),
                        // Rating
                        if (widget.movie.rating != null)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.movie.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Bottom content
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.movie.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    if (widget.movie.releaseDate != null)
                                      Text(
                                        widget.movie.releaseDate!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    if (widget.movie.genres.isNotEmpty)
                                      Text(
                                        widget.movie.genres.take(2).join(', '),
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMovieDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.movie.posterUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: widget.movie.posterUrl!,
                            width: 120,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (widget.movie.rating != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.movie.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            if (widget.movie.releaseDate != null)
                              Text('Release: ${widget.movie.releaseDate}'),
                            if (widget.movie.runtime != null)
                              Text('Runtime: ${widget.movie.runtime}'),
                            if (widget.movie.certificate != null)
                              Text('Rating: ${widget.movie.certificate}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (widget.movie.genres.isNotEmpty) ...[
                    Text(
                      'Genres',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.movie.genres
                          .map((genre) => Chip(label: Text(genre)))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (widget.movie.overview != null) ...[
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.movie.overview!),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating ? null : _toggleWatchlist,
                          icon: _isUpdating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isInWatchlist
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                          label: Text(
                            _isInWatchlist
                                ? 'Remove from Watchlist'
                                : 'Add to Watchlist',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openInIMDb(),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('View on IMDb'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openInIMDb() async {
    final url = Uri.parse('https://www.imdb.com/title/${widget.movie.id}/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
