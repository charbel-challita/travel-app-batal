class IncludedRules {
  final int hotel;
  final int activity;
  final int restaurant;
  final int nightlife;

  const IncludedRules({
    required this.hotel,
    required this.activity,
    required this.restaurant,
    required this.nightlife,
  });

  factory IncludedRules.fromJson(Map<String, dynamic> json) {
    return IncludedRules(
      hotel: json['hotel'] ?? 0,
      activity: json['activity'] ?? 0,
      restaurant: json['restaurant'] ?? 0,
      nightlife: json['nightlife'] ?? 0,
    );
  }
}

class AiPackageModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String city;
  final String country;
  final String mode;
  final double price;
  final String currency;
  final double rating;
  final String tag;
  final String? imageUrl;
  final String? imageAsset;
  final IncludedRules includedRules;
  final bool isActive;

  const AiPackageModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.city,
    required this.country,
    required this.mode,
    required this.price,
    required this.currency,
    required this.rating,
    required this.tag,
    this.imageUrl,
    this.imageAsset,
    required this.includedRules,
    required this.isActive,
  });

  factory AiPackageModel.fromJson(Map<String, dynamic> json) {
    return AiPackageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'Casual',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      tag: json['tag']?.toString() ?? 'Package',
      imageUrl: json['image_url']?.toString(),
      imageAsset: json['image_asset']?.toString(),
      includedRules: IncludedRules.fromJson(
        Map<String, dynamic>.from(json['included_rules'] ?? {}),
      ),
      isActive: json['is_active'] ?? true,
    );
  }
}