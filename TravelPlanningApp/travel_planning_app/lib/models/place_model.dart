class PlaceModel {
  final String country;
  final String city;
  final String type;
  final String name;
  final String category;
  final double cost;
  final double durationHours;
  final double rating;
  final List<String> interestTags;

  const PlaceModel({
    required this.country,
    required this.city,
    required this.type,
    required this.name,
    required this.category,
    required this.cost,
    required this.durationHours,
    required this.rating,
    required this.interestTags,
  });
}