import 'package:flutter/material.dart';

import '../services/api_service.dart';

class TripDetailsScreen extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final String duration;
  final String budget;
  final String style;
  final String people;
  final Map<String, dynamic>? aiPackage;

  const TripDetailsScreen({
    super.key,
    required this.title,
    required this.location,
    required this.status,
    this.duration = '5 days',
    this.budget = '\$680',
    this.style = 'Casual',
    this.people = 'Friends',
    this.aiPackage,
  });

  List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return [];
  }

  List<Map<String, dynamic>> _readItinerary(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    return [];
  }

  IconData _iconForType(String type) {
    final cleanType = type.toLowerCase();

    if (cleanType == 'hotel') {
      return Icons.hotel_outlined;
    }

    if (cleanType == 'restaurant') {
      return Icons.restaurant_outlined;
    }

    if (cleanType == 'nightlife') {
      return Icons.nightlife_outlined;
    }

    return Icons.map_outlined;
  }

  String _selectedModeForSave() {
    final cleanStyle = style.toLowerCase();

    if (cleanStyle == 'luxury') {
      return 'Luxury';
    }

    if (cleanStyle == 'nightlife') {
      return 'Night';
    }

    return 'Casual';
  }

  Future<void> _saveTrip(BuildContext context) async {
    final package = aiPackage ?? {};
    final coverImageUrl = (package['cover_image_url'] ?? '').toString();

    final fallbackImage = package['selected_hotel_details'] is Map
        ? ((package['selected_hotel_details'] as Map)['image_url'] ?? '')
            .toString()
        : '';

    final image = coverImageUrl.isNotEmpty ? coverImageUrl : fallbackImage;

    final selectedCity = (package['selected_city'] ?? location).toString();
    final country = (package['country'] ?? '').toString();

    final tripData = {
      'item_key': 'ai-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'location': country.isEmpty ? selectedCity : '$selectedCity, $country',
      'image': image.isEmpty ? null : image,
      'selected_mode': _selectedModeForSave(),
      'status': 'saved',
      'tags': [
        'AI Generated',
        style,
        people,
      ],
      'price': budget,
      'rating': '',
      'duration': duration,
      'item_type': 'ai_package',
      'target_type': 'ai_generated_trip',
      'source_collection': 'ai_generated',
    };

    try {
      await ApiService().saveTrip(tripData);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip saved successfully.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.cleanErrorMessage(error)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = aiPackage ?? {};
    final coverImageUrl = (package['cover_image_url'] ?? '').toString();
    final isLuxury = style.toLowerCase() == 'luxury';
    final isNight = style.toLowerCase() == 'nightlife';

    final backgroundColor = isLuxury
        ? const Color(0xFF030303)
        : isNight
            ? const Color(0xFF050818)
            : const Color(0xFFFDFDFD);

    final cardColor = isLuxury || isNight
        ? const Color(0xFF0B1020)
        : Colors.white;

    final primaryTextColor = isLuxury
        ? const Color(0xFFFFF8E1)
        : isNight
            ? Colors.white
            : const Color(0xFF111827);

    final secondaryTextColor = isLuxury
        ? const Color(0xFFB8B8B8)
        : isNight
            ? const Color(0xFFB8B8D1)
            : const Color(0xFF6B7280);

    final accentColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : const Color(0xFF2563EB);

    final borderColor = isLuxury
        ? const Color(0xFFE8C766).withOpacity(0.35)
        : isNight
            ? const Color(0xFFA855F7).withOpacity(0.35)
            : const Color(0xFFE5E7EB);

    final selectedHotel = (package['selected_hotel'] ?? '').toString();
    final selectedActivities = _readStringList(package['selected_activities']);
    final selectedRestaurants = _readStringList(package['selected_restaurants']);

    final selectedHotelDetails = package['selected_hotel_details'] is Map
        ? Map<String, dynamic>.from(package['selected_hotel_details'] as Map)
        : <String, dynamic>{};

    final selectedActivityDetails =
        _readItinerary(package['selected_activities_details']);
    final selectedRestaurantDetails =
        _readItinerary(package['selected_restaurants_details']);

    final includedItems = <Map<String, dynamic>>[
      if (selectedHotelDetails.isNotEmpty) selectedHotelDetails,
      ...selectedActivityDetails,
      ...selectedRestaurantDetails,
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
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
                icon: Icon(
                  Icons.arrow_back,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 10),

              if (coverImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    coverImageUrl,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 260,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          color: Color(0xFF2563EB),
                          size: 70,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.travel_explore,
                    color: Color(0xFF2563EB),
                    size: 70,
                  ),
                ),

              const SizedBox(height: 22),

              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: secondaryTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    location,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              if (aiPackage != null) ...[
                const SizedBox(height: 28),

                Text(
                  'Included in this package',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 14),

                if (includedItems.isNotEmpty)
                  ...includedItems.map((item) {
                    final type = (item['type'] ?? '').toString();
                    final name = (item['name'] ?? '').toString();
                    final city = (item['city'] ?? location).toString();
                    final country = (item['country'] ?? '').toString();
                    final cost = item['cost'];
                    final durationHours = item['duration_hours'];
                    final rating = item['rating'];
                    final imageUrl = (item['image_url'] ?? '').toString();

                    return _AiIncludedCard(
                      imageUrl: imageUrl,
                      icon: _iconForType(type),
                      type: type.isEmpty ? 'item' : type,
                      title: name,
                      subtitle: country.isEmpty ? city : '$city, $country',
                      duration: type.toLowerCase() == 'hotel'
                          ? 'per night'
                          : durationHours is num
                              ? '${durationHours.toStringAsFixed(1)}h'
                              : '',
                      price: cost is num ? '\$${cost.toStringAsFixed(0)}' : '',
                      rating: rating is num ? rating.toStringAsFixed(1) : '',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      accentColor: accentColor,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    );
                  })
                else ...[
                  if (selectedHotel.isNotEmpty)
                    _InfoCard(
                      title: 'Hotel',
                      items: [selectedHotel],
                      icon: Icons.hotel_outlined,
                    ),
                  if (selectedActivities.isNotEmpty)
                    _InfoCard(
                      title: 'Activities',
                      items: selectedActivities,
                      icon: Icons.map_outlined,
                    ),
                  if (selectedRestaurants.isNotEmpty)
                    _InfoCard(
                      title: 'Restaurants',
                      items: selectedRestaurants,
                      icon: Icons.restaurant_outlined,
                    ),
                ],
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _saveTrip(context),
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text(
                    'Save Trip',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor:
                        isLuxury ? const Color(0xFF111827) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiIncludedCard extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final String type;
  final String title;
  final String subtitle;
  final String duration;
  final String price;
  final String rating;
  final Color cardColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final bool isLuxury;
  final bool isNight;

  const _AiIncludedCard({
    this.imageUrl,
    required this.icon,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.price,
    required this.rating,
    required this.cardColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(22),
              ),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      width: 112,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _ImageFallback(
                          icon: icon,
                          accentColor: accentColor,
                          isLuxury: isLuxury,
                          isNight: isNight,
                        );
                      },
                    )
                  : _ImageFallback(
                      icon: icon,
                      accentColor: accentColor,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (duration.isNotEmpty) ...[
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (price.isNotEmpty) ...[
                        Text(
                          price,
                          style: TextStyle(
                            color: isLuxury
                                ? const Color(0xFFE8C766)
                                : isNight
                                    ? const Color(0xFFA855F7)
                                    : const Color(0xFF16A34A),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (rating.isNotEmpty) ...[
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final bool isLuxury;
  final bool isNight;

  const _ImageFallback({
    required this.icon,
    required this.accentColor,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isLuxury
          ? const Color(0xFFE8C766).withOpacity(0.14)
          : isNight
              ? const Color(0xFFA855F7).withOpacity(0.14)
              : const Color(0xFFEFF6FF),
      child: Center(
        child: Icon(
          icon,
          color: accentColor,
          size: 44,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '• $item',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

