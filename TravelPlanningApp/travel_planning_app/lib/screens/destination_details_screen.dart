import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../services/sample_data.dart';

class DestinationDetailsScreen extends StatelessWidget {
  final String destination;
  final String country;

  const DestinationDetailsScreen({
    super.key,
    required this.destination,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final destinationPlaces = SampleData.places.where((place) {
      return place.country.toLowerCase() == destination.toLowerCase() ||
          place.city.toLowerCase() == destination.toLowerCase();
    }).toList();

    final placesToShow = destinationPlaces.isEmpty
        ? SampleData.places.take(3).toList()
        : destinationPlaces;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
              ),

              const SizedBox(height: 8),

              Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF38BDF8),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.public,
                        size: 150,
                        color: Colors.white.withOpacity(0.13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Text(
                            destination,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            country,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Overview',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$destination is a great destination for culture, food, sightseeing, hotels, and unique activities. Later this page will load real places from your dataset.',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Top categories',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),

              const Row(
                children: [
                  _CategoryBox(
                    icon: Icons.map_outlined,
                    title: 'Activities',
                    subtitle: 'Tours & sights',
                  ),
                  SizedBox(width: 12),
                  _CategoryBox(
                    icon: Icons.hotel_outlined,
                    title: 'Hotels',
                    subtitle: 'Places to stay',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Row(
                children: [
                  _CategoryBox(
                    icon: Icons.restaurant_outlined,
                    title: 'Restaurants',
                    subtitle: 'Food spots',
                  ),
                  SizedBox(width: 12),
                  _CategoryBox(
                    icon: Icons.auto_awesome,
                    title: 'AI Plan',
                    subtitle: 'Generate trip',
                  ),
                ],
              ),

              const SizedBox(height: 26),

              const Text(
                'Recommended places',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),

              ...placesToShow.map((place) {
                return _PlaceCard(
                  title: place.name,
                  type: place.type,
                  price: '\$${place.cost.toStringAsFixed(0)}',
                  rating: place.rating.toStringAsFixed(1),
                  icon: _getPlaceIcon(place),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPlaceIcon(PlaceModel place) {
    if (place.type == 'hotel') return Icons.hotel_outlined;
    if (place.type == 'restaurant') return Icons.restaurant_outlined;

    final category = place.category.toLowerCase();

    if (category.contains('culture')) return Icons.account_balance_outlined;
    if (category.contains('beach')) return Icons.beach_access_outlined;
    if (category.contains('nature')) return Icons.landscape_outlined;

    return Icons.map_outlined;
  }
}

class _CategoryBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CategoryBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 105,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String title;
  final String type;
  final String price;
  final String rating;
  final IconData icon;

  const _PlaceCard({
    required this.title,
    required this.type,
    required this.price,
    required this.rating,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                  Text(
                    rating,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
