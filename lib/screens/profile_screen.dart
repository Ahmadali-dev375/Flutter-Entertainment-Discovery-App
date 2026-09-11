// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:q_select/screens/watchlist_screen.dart';
import '../providers/app_state_provider.dart';
import '../widgets/login_dialog.dart';
import '../models/movie.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user != null) {
            return _buildAuthenticatedProfile(context, user);
          } else {
            return _buildUnauthenticatedProfile(context);
          }
        },
      ),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            (user.displayName != null &&
                                    user.displayName!.isNotEmpty)
                                ? user.displayName!
                                      .substring(0, 1)
                                      .toUpperCase()
                                : 'U',
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Watchlist Preview Card - Now fetches from Firebase only
          _buildWatchlistPreview(context, user),
          const SizedBox(height: 20),

          _buildSettingsSection(context, user),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'Sign in to sync your data',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep your watchlist, preferences, and viewing history synced across all your devices.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _showLoginDialog(context),
              child: const Text('Sign In'),
            ),

            const SizedBox(height: 20),
            _buildOfflineSettingsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistPreview(BuildContext context, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Watchlist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WatchlistScreen(isFromBottomNav: false),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fetch watchlist data directly from Firebase
            FutureBuilder<List<Movie>>(
              future: FirebaseService.fetchWatchlistFromFirebase(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load watchlist',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // Trigger rebuild by calling setState equivalent
                            (context as Element).markNeedsBuild();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final movies = snapshot.data ?? [];

                if (movies.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: const Column(
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No movies in watchlist',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show first 3 movies
                final displayMovies = movies.take(3).toList();

                return Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayMovies.length,
                        itemBuilder: (context, index) {
                          final movie = displayMovies[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    movie.posterUrl ?? '',
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 80,
                                        width: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.movie),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  movie.title,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (movies.length > 3) ...[
                      const SizedBox(height: 8),
                      Text(
                        'and ${movies.length - 3} more movies',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, User user) {
    return Column(
      children: [
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            return _buildSettingsTile(
              context,
              'Dark Mode',
              appState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              () => appState.toggleTheme(),
              trailing: Switch(
                value: appState.isDarkMode,
                onChanged: (_) => appState.toggleTheme(),
              ),
            );
          },
        ),

        _buildSettingsTile(
          context,
          'Preferences',
          Icons.tune,
          () => _showPreferencesDialog(context),
        ),

        _buildSettingsTile(
          context,
          'Sign Out',
          Icons.logout,
          () => _showSignOutDialog(context),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildOfflineSettingsSection(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Card(
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                'Dark Mode',
                appState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                () => appState.toggleTheme(),
                trailing: Switch(
                  value: appState.isDarkMode,
                  onChanged: (_) => appState.toggleTheme(),
                ),
              ),
              _buildSettingsTile(
                context,
                'Preferences',
                Icons.tune,
                () => _showPreferencesDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const LoginDialog());
  }

  void _showPreferencesDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preferences coming soon!')));
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ignore_for_file: avoid_print, use_build_context_synchronously, await_only_futures, unnecessary_null_comparison
}
