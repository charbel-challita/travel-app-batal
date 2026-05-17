class PlaceModel {
  final String? id;
  final String country;
  final String city;
  final String type;
  final String name;
  final String category;
  final double cost;
  final String currency;
  final double durationHours;
  final double rating;
  final List<String> interestTags;
  final String? budgetLevel;
  final PlaceFlags? flags;
  final List<String> images;

  const PlaceModel({
    this.id,
    required this.country,
    required this.city,
    required this.type,
    required this.name,
    required this.category,
    required this.cost,
    this.currency = 'USD',
    required this.durationHours,
    required this.rating,
    required this.interestTags,
    this.budgetLevel,
    this.flags,
    this.images = const [],
  });

  factory PlaceModel.fromApiJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: _readString(json['id'] ?? json['_id']),
      country: _readString(json['country']) ?? '',
      city: _readString(json['city']) ?? '',
      type: _readString(json['type']) ?? '',
      name: _readString(json['name']) ?? '',
      category: _readString(json['category']) ?? '',
      cost: _readDouble(json['cost']),
      currency: _readString(json['currency']) ?? 'USD',
      durationHours: _readDouble(json['duration_hours']),
      rating: _readDouble(json['rating']),
      interestTags: _readStringList(json['interest_tags']),
      budgetLevel: _readString(json['item_budget_level']),
      flags: json['flags'] is Map<String, dynamic>
          ? PlaceFlags.fromApiJson(json['flags'] as Map<String, dynamic>)
          : null,
      images: _readStringList(json['images']),
    );
  }

  String get locationLabel => '$city, $country';

  String get priceLabel => '$currency ${cost.toStringAsFixed(0)}';

  String get durationLabel {
    if (type.toLowerCase() == 'hotel') {
      return 'per night';
    }
    return '${durationHours.toStringAsFixed(1)}h';
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => _readString(item))
        .whereType<String>()
        .toList(growable: false);
  }
}

class PlaceFlags {
  final bool familyFriendly;
  final bool cultureItem;
  final bool romanticItem;
  final bool adventureItem;
  final bool nightlifeItem;

  const PlaceFlags({
    required this.familyFriendly,
    required this.cultureItem,
    required this.romanticItem,
    required this.adventureItem,
    required this.nightlifeItem,
  });

  factory PlaceFlags.fromApiJson(Map<String, dynamic> json) {
    return PlaceFlags(
      familyFriendly: _readBool(json['family_friendly']),
      cultureItem: _readBool(json['culture_item']),
      romanticItem: _readBool(json['romantic_item']),
      adventureItem: _readBool(json['adventure_item']),
      nightlifeItem: _readBool(json['nightlife_item']),
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
