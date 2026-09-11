// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({super.key});

  final List<Map<String, dynamic>> moods = const [
    {'name': 'Happy', 'emoji': '😊', 'color': Colors.orange},
    {'name': 'Sad', 'emoji': '😢', 'color': Colors.blue},
    {'name': 'Excited', 'emoji': '🤩', 'color': Colors.red},
    {'name': 'Chill', 'emoji': '😎', 'color': Colors.green},
    {'name': 'Scared', 'emoji': '😱', 'color': Colors.purple},
    {'name': 'Romantic', 'emoji': '😍', 'color': Colors.pink},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'How are you feeling?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: moods.length,
              itemBuilder: (context, index) {
                final mood = moods[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Provider.of<RecommendationProvider>(
                        context,
                        listen: false,
                      ).getRecommendationsByMood(mood['name']);
                    },
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: (mood['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (mood['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood['emoji'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood['name'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: mood['color'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
