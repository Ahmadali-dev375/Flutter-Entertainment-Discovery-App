// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../models/movie.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import '../widgets/movie_card.dart';

class WatchlistScreen extends StatefulWidget {
  final bool isFromBottomNav;

  const WatchlistScreen({super.key, this.isFromBottomNav = true});

  static void refreshWatchlistExternally() {
    _WatchlistScreenState.refreshWatchlist();
  }

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<Movie> _watchlist = [];
  bool _isLoading = true;
  String? _errorMessage;

  static _WatchlistScreenState? _currentInstance;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentInstance = this;
    _loadWatchlist();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWatchlist();
    }
  }

  static void refreshWatchlist() {
    if (_currentInstance != null && _currentInstance!.mounted) {
      _currentInstance!._quickRefresh();
    }
  }

  Future<void> _quickRefresh() async {
    try {
      final movies = await LocalStorageService.getWatchlistMovies();
      if (mounted) {
        setState(() {
          _watchlist = movies;
        });
      }
    } catch (e) {
      print('Quick refresh failed: $e');
    }
  }

  Future<void> _loadWatchlist() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final localMovies = await LocalStorageService.getWatchlistMovies();
      if (mounted) {
        setState(() {
          _watchlist = localMovies;
          _isLoading = false;
        });
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final firebaseMovies =
              await FirebaseService.fetchWatchlistFromFirebase(user.uid);

          await LocalStorageService.saveWatchlist(firebaseMovies);
          await LocalStorageService.setWatchlistOwner(user.uid);

          if (mounted) {
            setState(() {
              _watchlist = firebaseMovies;
            });
          }
        } catch (e) {
          print('Firebase sync failed: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _watchlist = [];
          _isLoading = false;
          _errorMessage = 'Failed to load watchlist. Please try again.';
        });
      }
    }
  }

  Future<void> _refreshWatchlist() async {
    HapticFeedback.lightImpact();
    await _loadWatchlist();

    if (mounted && _errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Watchlist refreshed'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          clipBehavior: Clip.none, // Allow the badge to overflow
          children: [
            const Text("My Watchlist", style: TextStyle(fontSize: 18)),
            if (_watchlist.isNotEmpty)
              Positioned(
                top: -6,
                right: -24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_watchlist.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: !widget.isFromBottomNav,
        actions: [
          if (!widget.isFromBottomNav || _errorMessage != null)
            IconButton(
              icon: _isLoading && _watchlist.isEmpty
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _refreshWatchlist,
              tooltip: 'Refresh',
            ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _watchlist.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) return _buildErrorState();
    if (_watchlist.isEmpty) return _buildEmptyState();
    return _buildWatchlistGrid();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWatchlist,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your watchlist is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              user != null
                  ? 'Add movies you want to watch later\nThey\'ll sync across all your devices'
                  : 'Add movies you want to watch later\nSign in to sync across devices',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistGrid() {
    return RefreshIndicator(
      onRefresh: _refreshWatchlist,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _watchlist.length,
        itemBuilder: (context, index) {
          return MovieCard(
            movie: _watchlist[index],
            onWatchlistChanged: () {
              _quickRefresh();
              HapticFeedback.selectionClick();
            },
          );
        },
      ),
    );
  }
}
//*********************