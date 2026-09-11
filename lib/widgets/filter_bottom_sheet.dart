import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? selectedGenre;
  String? selectedLanguage;
  String? selectedContentType;
  String? selectedCertificate;
  RangeValues ratingRange = const RangeValues(0, 10);
  RangeValues yearRange = const RangeValues(1990, 2024);

  final List<String> genres = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
    'War',
    'Western'
  ];

  final List<String> languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Japanese',
    'Korean',
    'Chinese',
    'Hindi',
    'Arabic'
  ];

  final List<String> contentTypes = [
    'Movie',
    'TV Series',
    'TV Movie',
    'Documentary',
    'Short'
  ];

  final List<String> certificates = [
    'G',
    'PG',
    'PG-13',
    'R',
    'NC-17',
    'TV-Y',
    'TV-PG',
    'TV-14',
    'TV-MA'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Options',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGenreFilter(),
                  const SizedBox(height: 20),
                  _buildLanguageFilter(),
                  const SizedBox(height: 20),
                  _buildContentTypeFilter(),
                  const SizedBox(height: 20),
                  _buildCertificateFilter(),
                  const SizedBox(height: 20),
                  _buildRatingFilter(),
                  const SizedBox(height: 20),
                  _buildYearFilter(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Genre', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: genres
              .map((genre) => FilterChip(
                    label: Text(genre),
                    selected: selectedGenre == genre,
                    onSelected: (selected) {
                      setState(() {
                        selectedGenre = selected ? genre : null;
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedLanguage,
          decoration: const InputDecoration(
            hintText: 'Select Language',
            border: OutlineInputBorder(),
          ),
          items: languages
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedLanguage = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContentTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Content Type',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: contentTypes
              .map((type) => FilterChip(
                    label: Text(type),
                    selected: selectedContentType == type,
                    onSelected: (selected) {
                      setState(() {
                        selectedContentType = selected ? type : null;
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCertificateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Certificate',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: certificates
              .map((cert) => FilterChip(
                    label: Text(cert),
                    selected: selectedCertificate == cert,
                    onSelected: (selected) {
                      setState(() {
                        selectedCertificate = selected ? cert : null;
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Rating: ${ratingRange.start.toStringAsFixed(1)} - ${ratingRange.end.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        RangeSlider(
          values: ratingRange,
          min: 0,
          max: 10,
          divisions: 20,
          onChanged: (values) {
            setState(() {
              ratingRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildYearFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Release Year: ${yearRange.start.toInt()} - ${yearRange.end.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        RangeSlider(
          values: yearRange,
          min: 1990,
          max: 2024,
          divisions: 34,
          onChanged: (values) {
            setState(() {
              yearRange = values;
            });
          },
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      selectedGenre = null;
      selectedLanguage = null;
      selectedContentType = null;
      selectedCertificate = null;
      ratingRange = const RangeValues(0, 10);
      yearRange = const RangeValues(1990, 2024);
    });
  }

  void _applyFilters() {
    final provider =
        Provider.of<RecommendationProvider>(context, listen: false);
    provider.applyFilters(
      genre: selectedGenre,
      language: selectedLanguage,
      contentType: selectedContentType,
      certificate: selectedCertificate,
      minRating: ratingRange.start,
      maxRating: ratingRange.end,
      minYear: yearRange.start.toInt(),
      maxYear: yearRange.end.toInt(),
    );
    Navigator.pop(context);
  }
}
