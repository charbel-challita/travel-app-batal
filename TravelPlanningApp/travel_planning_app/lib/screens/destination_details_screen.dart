import 'package:flutter/material.dart';

import '../models/ai_package_model.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';

class DestinationDetailsScreen extends StatefulWidget {
  final String destination;
  final String country;
  final String selectedMode;
  final PlaceModel? place;
  final AiPackageModel? package;

  const DestinationDetailsScreen({
    super.key,
    required this.destination,
    required this.country,
    this.selectedMode = 'Casual',
    this.place,
    this.package,
  });

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<DestinationDetailsScreen> {
  final ApiService _apiService = ApiService();

  bool isFavorite = false;
  bool isSavingTrip = false;
  bool isUpdatingFavorite = false;
  bool isLoadingIncludedItems = false;
  String? includedItemsError;
  String? checkedFavoriteKey;
  List<PlaceModel> backendIncludedItems = [];

  @override
  void initState() {
    super.initState();
    _loadIncludedItemsForPackage();
  }

  @override
  void didUpdateWidget(covariant DestinationDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.package?.id != widget.package?.id) {
      _loadIncludedItemsForPackage();
    }
  }

  Future<void> _loadIncludedItemsForPackage() async {
    final package = widget.package;

    if (package == null) {
      return;
    }

    setState(() {
      isLoadingIncludedItems = true;
      includedItemsError = null;
      backendIncludedItems = [];
    });

    try {
      final fetchedItems = <PlaceModel>[];

      Future<void> fetchType(String type, int count) async {
        if (count <= 0) return;

        final isLuxuryMode = widget.selectedMode == 'Luxury';

        Future<List<PlaceModel>> tryFetch({
          String? city,
          String? country,
          String? budgetLevel,
        }) {
          return _apiService.getTravelItems(
            city: city,
            country: country,
            type: type,
            budgetLevel: budgetLevel,
            includeImages: true,
            limit: count,
          );
        }

        List<PlaceModel> items = [];

        items = await tryFetch(
          city: package.city,
          country: package.country,
          budgetLevel: isLuxuryMode ? 'luxury' : null,
        );

        if (items.isEmpty) {
          items = await tryFetch(
            country: package.country,
            budgetLevel: isLuxuryMode ? 'luxury' : null,
          );
        }

        if (items.isEmpty) {
          items = await tryFetch(
            country: package.country,
          );
        }

        if (items.isEmpty && isLuxuryMode) {
          items = await tryFetch(
            budgetLevel: 'luxury',
          );
        }

        fetchedItems.addAll(items.take(count));
      }

      await fetchType('hotel', package.includedRules.hotel);
      await fetchType('activity', package.includedRules.activity);
      await fetchType('restaurant', package.includedRules.restaurant);
      await fetchType('nightlife', package.includedRules.nightlife);

      if (!mounted) return;

      setState(() {
        backendIncludedItems = fetchedItems;
        isLoadingIncludedItems = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        backendIncludedItems = [];
        includedItemsError = error.toString();
        isLoadingIncludedItems = false;
      });
    }
  }

  String _itemKeyFromTitle(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _saveTrip({
    required String status,
    required String message,
    required String title,
    required String location,
    required String image,
    required String price,
    required String rating,
    required String duration,
    required List<String> tags,
  }) async {
    if (isSavingTrip) {
      return;
    }

    setState(() {
      isSavingTrip = true;
    });

    try {
      await _apiService.saveTrip({
        'item_key': _itemKeyFromTitle(title),
        'title': title,
        'location': location,
        'image': image,
        'selected_mode': widget.selectedMode,
        'status': status,
        'tags': tags,
        'price': price,
        'rating': rating,
        'duration': duration,
      });

      if (!mounted) return;

      setState(() {
        isSavingTrip = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSavingTrip = false;
      });

      final message = ApiService.cleanErrorMessage(error) == 'Please log in first.'
          ? 'Please log in to save trips.'
          : 'Could not update trip.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _syncFavoriteState(String itemKey) async {
    if (checkedFavoriteKey == itemKey) {
      return;
    }

    checkedFavoriteKey = itemKey;

    try {
      final favorite = await _apiService.checkFavorite(itemKey);

      if (!mounted || checkedFavoriteKey != itemKey) return;

      setState(() {
        isFavorite = favorite;
      });
    } catch (_) {
      // Guests can still view details. The tap handler shows the login message.
    }
  }

  Future<void> _toggleFavorite({
    required String itemKey,
    required String itemType,
    required String title,
    required String location,
    required String image,
    required String price,
    required String rating,
    required String duration,
    required List<String> tags,
    required String sourceCollection,
  }) async {
    if (isUpdatingFavorite) {
      return;
    }

    setState(() {
      isUpdatingFavorite = true;
    });

    try {
      if (isFavorite) {
        await _apiService.removeFavorite(itemKey);

        if (!mounted) return;

        setState(() {
          isFavorite = false;
          isUpdatingFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites.')),
        );
        return;
      }

      await _apiService.addFavorite({
        'target_id': itemKey,
        'target_type': itemType,
        'item_key': itemKey,
        'item_type': itemType,
        'title': title,
        'location': location,
        'image': image,
        'selected_mode': widget.selectedMode,
        'tags': tags,
        'price': price,
        'rating': rating,
        'duration': duration,
        'source_collection': sourceCollection,
      });

      if (!mounted) return;

      setState(() {
        isFavorite = true;
        isUpdatingFavorite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isUpdatingFavorite = false;
      });

      final message = ApiService.cleanErrorMessage(error) == 'Please log in first.'
          ? 'Please log in to add favorites.'
          : 'Could not update favorite.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLuxury = widget.selectedMode == 'Luxury';
    final isNight = widget.selectedMode == 'Night';

    final backgroundColor = isLuxury
        ? const Color(0xFF030303)
        : isNight
            ? const Color(0xFF050818)
            : const Color(0xFFFDFDFD);

    final primaryTextColor = isLuxury || isNight
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

    final cardColor = isLuxury || isNight
        ? const Color(0xFF111827)
        : Colors.white;

    final borderColor = isLuxury
        ? const Color(0xFFE8C766).withOpacity(0.45)
        : isNight
            ? const Color(0xFFA855F7).withOpacity(0.35)
            : const Color(0xFFE5E7EB);

    final isBavarianTour = widget.destination == 'Private Bavarian Alps Tour';
    final isHalongPackage = widget.destination == 'Halong Bay Seaplane Tour';
    final isDubaiLuxuryPackage = widget.destination == 'Dubai Elite Yacht Escape';
    final isPrivateIslandPackage = widget.destination == 'Private Island Stay';
    final isJustCavalli = widget.destination == 'Just Cavalli Club';
    final backendPlace = widget.place;
    final hasBackendPlace = backendPlace != null;
    final backendPackage = widget.package;
    final hasBackendPackage = backendPackage != null;

    final isPackage = hasBackendPackage ||
        widget.destination == 'Rome First-Time Tour' ||
        widget.destination == 'Dubai City Highlights' ||
        widget.destination == 'Tokyo Discovery Tour' ||
        widget.destination == 'Halong Bay Seaplane Tour' ||
        widget.destination == 'Dubai Elite Yacht Escape' ||
        widget.destination == 'Private Island Stay';

    final imageAsset = isBavarianTour
        ? 'assets/images/privatebavariantour.jpg'
        : isHalongPackage
            ? 'assets/images/halongbay.jpg'
            : isDubaiLuxuryPackage
                ? 'assets/images/dubaiyacht.jpg'
                : isPrivateIslandPackage
                    ? 'assets/images/prvtislandstay.webp'
                    : isJustCavalli
                        ? 'assets/images/justcavalli.jpg'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'assets/images/rome.jpg'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'assets/images/dubai.png'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'assets/images/tokyo.webp'
                                    : 'assets/images/baligetaway.png';

    final title = isBavarianTour
        ? 'Private Bavarian Alps Tour'
        : isHalongPackage
            ? 'Halong Bay Seaplane Tour'
            : isDubaiLuxuryPackage
                ? 'Dubai Elite Yacht Escape'
                : isPrivateIslandPackage
                    ? 'Private Island Stay'
                    : isJustCavalli
                        ? 'Just Cavalli Club'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'Rome First-Time Tour'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'Dubai City Highlights'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'Tokyo Discovery Tour'
                                    : 'Island Escape Getaway';

    final location = isBavarianTour
        ? 'Bavaria, Germany'
        : isHalongPackage
            ? 'Halong Bay, Vietnam'
            : isDubaiLuxuryPackage
                ? 'Dubai, UAE'
                : isPrivateIslandPackage
                    ? 'Maldives'
                    : isJustCavalli
                        ? 'Dubai, UAE'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'Rome, Italy'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'Dubai, UAE'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'Tokyo, Japan'
                                    : 'Bali, Indonesia';

    final rating = isBavarianTour
        ? '4.9'
        : isHalongPackage
            ? '4.9'
            : isDubaiLuxuryPackage
                ? '4.8'
                : isPrivateIslandPackage
                    ? '4.9'
                    : isJustCavalli
                        ? '4.8'
                        : widget.destination == 'Rome First-Time Tour'
                            ? '4.7'
                            : widget.destination == 'Dubai City Highlights'
                                ? '4.6'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? '4.8'
                                    : '4.8';

    final description = isBavarianTour
        ? 'A private scenic luxury tour through the Bavarian Alps, designed for travelers who want mountain views, peaceful landscapes, premium comfort, and a curated countryside escape.'
        : isHalongPackage
            ? 'A premium seaplane tour over Halong Bay, designed for travelers who want breathtaking aerial views, limestone islands, emerald waters, and a luxury scenic experience from above.'
            : isDubaiLuxuryPackage
                ? 'A luxury Dubai escape combining a five-star hotel stay, private yacht experience, and fine dining. Designed for travelers who want premium comfort, skyline views, and a curated high-end city experience.'
                : isPrivateIslandPackage
                    ? 'A premium private island escape with an exclusive villa stay, private yacht transfer, and sunset fine dining. Designed for travelers who want privacy, ocean views, and a luxury tropical experience.'
                    : isJustCavalli
                        ? 'A luxury nightlife experience in Dubai with high-energy music, stylish interiors, premium vibes, and a glamorous club atmosphere for travelers who want an unforgettable night out.'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'A ready-made first-time tour package through Rome, designed for travelers who want to explore the citys most iconic landmarks, culture, history, and local atmosphere in one organized plan.'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'A ready-made city package for discovering Dubais modern skyline, iconic attractions, shopping areas, and cultural highlights in one smooth travel plan.'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'A ready-made discovery package through Tokyo, combining modern city life, traditional culture, famous districts, local food, and unforgettable sightseeing stops.'
                                    : 'A peaceful beachside getaway designed for relaxing, enjoying ocean views, and spending time near the shore. This stay is perfect for travelers who want a calm escape with nature, beach walks, and a comfortable private place to unwind.';

    final price = isBavarianTour
        ? '\$1480'
        : isHalongPackage
            ? '\$980'
            : isDubaiLuxuryPackage
                ? '\$1850'
                : isPrivateIslandPackage
                    ? '\$3450'
                    : isJustCavalli
                        ? '\$\$\$'
                        : widget.destination == 'Rome First-Time Tour'
                            ? '\$320'
                            : widget.destination == 'Dubai City Highlights'
                                ? '\$290'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? '\$340'
                                    : '\$680 / night';

    final displayTitle = hasBackendPackage
        ? backendPackage!.title
        : hasBackendPlace
            ? backendPlace!.name
            : title;

    final displayLocation = hasBackendPackage
        ? '${backendPackage!.city}, ${backendPackage!.country}'
        : hasBackendPlace
            ? '${backendPlace!.city}, ${backendPlace!.country}'
            : location;

    final displayRating = hasBackendPackage
        ? backendPackage!.rating.toStringAsFixed(1)
        : hasBackendPlace
            ? backendPlace!.rating.toStringAsFixed(1)
            : rating;

    final displayDescription = hasBackendPackage
        ? backendPackage!.description
        : hasBackendPlace
            ? _descriptionForBackendPlace(backendPlace!)
            : description;

    final displayPrice = hasBackendPackage
        ? '\$${backendPackage!.price.toStringAsFixed(0)}'
        : hasBackendPlace
            ? backendPlace!.type == 'hotel'
                ? '\$${backendPlace!.cost.toStringAsFixed(0)} / night'
                : '\$${backendPlace!.cost.toStringAsFixed(0)}'
            : price;

    final displayDuration = hasBackendPlace
        ? backendPlace!.type == 'hotel'
            ? 'per night'
            : '${backendPlace!.durationHours.toStringAsFixed(1)} hours'
        : isBavarianTour
            ? '8 hours'
            : isJustCavalli
                ? '5 hours'
                : '24 hours';

    final backendImageUrl =
        backendPlace?.primaryImageUrl ?? backendPlace?.primaryThumbnailUrl;
    final packageImageUrl = backendPackage?.imageUrl;
    final packageImageAsset = backendPackage?.imageAsset;

    final buttonText = isPackage ? 'Add Package to Plan' : 'Add to Plan';

    final includedItems = widget.destination == 'Halong Bay Seaplane Tour'
        ? [
            {
              'imageAsset': 'assets/images/seaplane.jpg',
              'icon': Icons.flight_takeoff,
              'type': 'activity',
              'title': 'Scenic Seaplane Flight',
              'subtitle': 'Aerial views over limestone islands',
              'duration': '45m',
              'price': '\$420',
              'rating': '4.9',
            },
            {
              'imageAsset': 'assets/images/halongcruise.jpg',
              'icon': Icons.directions_boat_outlined,
              'type': 'activity',
              'title': 'Private Bay Cruise',
              'subtitle': 'Luxury cruise through emerald waters',
              'duration': '3h',
              'price': '\$380',
              'rating': '4.8',
            },
            {
              'imageAsset': 'assets/images/halongcave.jpg',
              'icon': Icons.landscape_outlined,
              'type': 'activity',
              'title': 'Cave & Island Stop',
              'subtitle': 'Hidden caves and island viewpoints',
              'duration': '2h',
              'price': '\$180',
              'rating': '4.7',
            },
          ]
        : widget.destination == 'Dubai Elite Yacht Escape'
            ? [
                {
                  'imageAsset': 'assets/images/5starhotel.webp',
                  'icon': Icons.hotel_outlined,
                  'type': 'hotel',
                  'title': 'Five-Star Hotel Stay',
                  'subtitle': 'Luxury suite with skyline views',
                  'duration': '1 night',
                  'price': '\$650',
                  'rating': '4.9',
                },
                {
                  'imageAsset': 'assets/images/privateyachttour.jpg',
                  'icon': Icons.directions_boat_outlined,
                  'type': 'activity',
                  'title': 'Private Yacht Tour',
                  'subtitle': 'Premium marina cruise with sea views',
                  'duration': '2h',
                  'price': '\$850',
                  'rating': '4.8',
                },
                {
                  'imageAsset': 'assets/images/finedining.webp',
                  'icon': Icons.restaurant_menu,
                  'type': 'restaurant',
                  'title': 'Fine Dining Experience',
                  'subtitle': 'Upscale dinner with curated menu',
                  'duration': '2h',
                  'price': '\$350',
                  'rating': '4.9',
                },
              ]
            : widget.destination == 'Private Island Stay'
                ? [
                    {
                      'imageAsset': 'assets/images/privatevilla.jpg',
                      'icon': Icons.villa_outlined,
                      'type': 'hotel',
                      'title': 'Private Island Villa',
                      'subtitle': 'Exclusive villa with ocean views',
                      'duration': '1 night',
                      'price': '\$1800',
                      'rating': '4.9',
                    },
                    {
                      'imageAsset': 'assets/images/yachttransfer.jpg',
                      'icon': Icons.directions_boat_outlined,
                      'type': 'activity',
                      'title': 'Yacht Transfer',
                      'subtitle': 'Private yacht arrival experience',
                      'duration': '1h',
                      'price': '\$950',
                      'rating': '4.8',
                    },
                    {
                      'imageAsset': 'assets/images/sunsetdining.webp',
                      'icon': Icons.restaurant_menu,
                      'type': 'restaurant',
                      'title': 'Sunset Fine Dining',
                      'subtitle': 'Beachfront dinner with curated menu',
                      'duration': '2h',
                      'price': '\$700',
                      'rating': '4.9',
                    },
                  ]
                : widget.destination == 'Rome First-Time Tour'
                    ? [
                        {
                          'imageAsset': 'assets/images/colosseum.webp',
                          'icon': Icons.account_balance_outlined,
                          'type': 'activity',
                          'title': 'Colosseum Tour',
                          'subtitle': 'Ancient Rome guided landmark visit',
                          'tags': ['Culture', 'History', 'Landmark'],
                          'duration': '2h',
                          'price': '\$90',
                          'rating': '4.8',
                        },
                        {
                          'imageAsset': 'assets/images/vatican.webp',
                          'icon': Icons.church_outlined,
                          'type': 'activity',
                          'title': 'Vatican Visit',
                          'subtitle': 'Art, history, museums, and culture',
                          'tags': ['Art', 'Culture', 'Museum'],
                          'duration': '2.5h',
                          'price': '\$120',
                          'rating': '4.7',
                        },
                        {
                          'imageAsset': 'assets/images/pizza.jpg',
                          'icon': Icons.restaurant_outlined,
                          'type': 'restaurant',
                          'title': 'Roman Food Walk',
                          'subtitle': 'Pasta, pizza, gelato, and local bites',
                          'tags': ['Food', 'Local', 'Walking'],
                          'duration': '1.5h',
                          'price': '\$110',
                          'rating': '4.9',
                        },
                      ]
                    : widget.destination == 'Dubai City Highlights'
                        ? [
                            {
                              'imageAsset': 'assets/images/burjkhalifa.jpg',
                              'icon': Icons.location_city_outlined,
                              'type': 'activity',
                              'title': 'Burj Khalifa Visit',
                              'subtitle': 'City skyline views from the top',
                              'tags': ['Views', 'Landmark', 'Luxury'],
                              'duration': '1.5h',
                              'price': '\$120',
                              'rating': '4.8',
                            },
                            {
                              'imageAsset': 'assets/images/dubaimall.jpg',
                              'icon': Icons.shopping_bag_outlined,
                              'type': 'activity',
                              'title': 'Dubai Mall Stop',
                              'subtitle': 'Shopping, cafes, and attractions',
                              'tags': ['Shopping', 'Modern', 'Indoor'],
                              'duration': '2h',
                              'price': '\$70',
                              'rating': '4.6',
                            },
                            {
                              'imageAsset': 'assets/images/dubaimarina.webp',
                              'icon': Icons.waves_outlined,
                              'type': 'activity',
                              'title': 'Marina Walk',
                              'subtitle': 'Waterfront walk with skyline views',
                              'tags': ['Waterfront', 'Views', 'Relax'],
                              'duration': '1h',
                              'price': '\$100',
                              'rating': '4.7',
                            },
                          ]
                        : widget.destination == 'Tokyo Discovery Tour'
                            ? [
                                {
                                  'imageAsset': 'assets/images/asakusatemple.jpg',
                                  'icon': Icons.temple_buddhist_outlined,
                                  'type': 'activity',
                                  'title': 'Asakusa Temple Visit',
                                  'subtitle': 'Traditional culture and historic streets',
                                  'tags': ['Culture', 'Temple', 'History'],
                                  'duration': '2h',
                                  'price': '\$95',
                                  'rating': '4.8',
                                },
                                {
                                  'imageAsset': 'assets/images/shibuyacrossing.jpg',
                                  'icon': Icons.train_outlined,
                                  'type': 'activity',
                                  'title': 'Shibuya Crossing',
                                  'subtitle': 'Famous city lights and urban energy',
                                  'tags': ['City', 'Modern', 'Photo'],
                                  'duration': '1h',
                                  'price': '\$80',
                                  'rating': '4.7',
                                },
                                {
                                  'imageAsset': 'assets/images/japanesefood.jpg',
                                  'icon': Icons.ramen_dining_outlined,
                                  'type': 'restaurant',
                                  'title': 'Local Food Stop',
                                  'subtitle': 'Ramen, sushi, and street snacks',
                                  'tags': ['Food', 'Local', 'Taste'],
                                  'duration': '1.5h',
                                  'price': '\$165',
                                  'rating': '4.9',
                                },
                              ]
                            : [];

    final displayImage = backendImageUrl ??
        packageImageUrl ??
        packageImageAsset ??
        imageAsset;
    final displayTags = hasBackendPackage
        ? [backendPackage!.tag, widget.selectedMode]
        : hasBackendPlace
            ? backendPlace!.interestTags.take(3).toList(growable: false)
            : includedItems
                .expand((item) => (item['tags'] as List?) ?? const [])
                .map((tag) => tag.toString())
                .take(3)
                .toList(growable: false);
    final itemKey = _itemKeyFromTitle(displayTitle);
    final favoriteItemType = hasBackendPackage || isPackage
        ? 'package'
        : hasBackendPlace
            ? backendPlace!.type
            : 'place';
    final sourceCollection = hasBackendPackage
        ? 'ai_packages'
        : hasBackendPlace
            ? 'travel_items'
            : 'hardcoded_package';
    _syncFavoriteState(itemKey);

    return Scaffold(
      backgroundColor: backgroundColor,

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSavingTrip
                  ? null
                  : () => _saveTrip(
                        status: 'saved',
                        message: 'Package saved to trips.',
                        title: displayTitle,
                        location: displayLocation,
                        image: displayImage,
                        price: displayPrice,
                        rating: displayRating,
                        duration: displayDuration,
                        tags: displayTags,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: isLuxury ? const Color(0xFF111827) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isSavingTrip ? 'Saving...' : buttonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: isUpdatingFavorite
                        ? null
                        : () => _toggleFavorite(
                              itemKey: itemKey,
                              itemType: favoriteItemType,
                              title: displayTitle,
                              location: displayLocation,
                              image: displayImage,
                              price: displayPrice,
                              rating: displayRating,
                              duration: displayDuration,
                              tags: displayTags,
                              sourceCollection: sourceCollection,
                            ),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : primaryTextColor,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: hasBackendPlace && backendImageUrl != null && backendImageUrl.isNotEmpty
                    ? Image.network(
                        backendImageUrl,
                        width: double.infinity,
                        height: 320,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            imageAsset,
                            width: double.infinity,
                            height: 320,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : hasBackendPackage && packageImageUrl != null && packageImageUrl.isNotEmpty
                        ? Image.network(
                            packageImageUrl,
                            width: double.infinity,
                            height: 320,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                packageImageAsset ?? imageAsset,
                                width: double.infinity,
                                height: 320,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                    : Image.asset(
                        packageImageAsset ?? imageAsset,
                        width: double.infinity,
                        height: 320,
                        fit: BoxFit.cover,
                      ),
              ),

              const SizedBox(height: 14),

              Text(
                displayTitle,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: secondaryTextColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayLocation,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star_half, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    displayRating,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                displayDescription,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Price: $displayPrice',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              if (isPackage) ...[
                const SizedBox(height: 18),
                Text(
                  'Included in this package',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (hasBackendPackage) ...[
                  if (isLoadingIncludedItems)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (includedItemsError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Could not load included items.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (backendIncludedItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No included items found for this package.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    ...backendIncludedItems.map((item) {
                      return _PackageIncludedCard(
                        imageUrl: item.primaryThumbnailUrl ?? item.primaryImageUrl,
                        icon: _iconForPlaceType(item),
                        type: item.type,
                        title: item.name,
                        subtitle: '${item.city}, ${item.country}',
                        duration: item.type == 'hotel'
                            ? 'per night'
                            : '${item.durationHours.toStringAsFixed(1)}h',
                        price: '\$${item.cost.toStringAsFixed(0)}',
                        rating: item.rating.toStringAsFixed(1),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        accentColor: accentColor,
                        isLuxury: isLuxury,
                      );
                    }),
                ] else ...[
                  ...includedItems.map((item) {
                    return _PackageIncludedCard(
                      imageAsset: item['imageAsset'] as String?,
                      icon: item['icon'] as IconData,
                      type: item['type'] as String,
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      duration: item['duration'] as String,
                      price: item['price'] as String,
                      rating: item['rating'] as String,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      accentColor: accentColor,
                      isLuxury: isLuxury,
                    );
                  }),
                ],
              ],

              if (hasBackendPlace || !isPackage || isBavarianTour || isJustCavalli)
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: secondaryTextColor,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      displayDuration,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

            ],
          ),
        ),
      ),
    );
  }

  String _descriptionForBackendPlace(PlaceModel place) {
    final category = place.category.trim().isEmpty
        ? place.type
        : place.category.trim();

    final location = [
      if (place.city.trim().isNotEmpty) place.city.trim(),
      if (place.country.trim().isNotEmpty) place.country.trim(),
    ].join(', ');

    final tags = place.interestTags
        .where((tag) => tag.trim().isNotEmpty)
        .take(3)
        .join(', ');

    if (tags.isNotEmpty) {
      return '${place.name} is a $category experience in $location, recommended for travelers interested in $tags.';
    }

    return '${place.name} is a $category experience in $location, selected from Triply travel recommendations.';
  }

  IconData _iconForPlaceType(PlaceModel place) {
    if (place.type == 'hotel') return Icons.hotel_outlined;
    if (place.type == 'restaurant') return Icons.restaurant_outlined;
    if (place.type == 'nightlife') return Icons.nightlife_outlined;

    final category = place.category.toLowerCase();

    if (category.contains('culture')) return Icons.account_balance_outlined;
    if (category.contains('beach')) return Icons.beach_access_outlined;
    if (category.contains('nature')) return Icons.landscape_outlined;

    return Icons.map_outlined;
  }
}

class _PackageIncludedCard extends StatelessWidget {
  final String? imageAsset;
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

  const _PackageIncludedCard({
    this.imageAsset,
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
                        if (imageAsset != null && imageAsset!.isNotEmpty) {
                          return Image.asset(
                            imageAsset!,
                            width: 112,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          );
                        }

                        return Container(
                          color: isLuxury
                              ? const Color(0xFFE8C766).withOpacity(0.14)
                              : const Color(0xFFEFF6FF),
                          child: Center(
                            child: Icon(
                              icon,
                              color: accentColor,
                              size: 44,
                            ),
                          ),
                        );
                      },
                    )
                  : imageAsset != null && imageAsset!.isNotEmpty
                      ? Image.asset(
                          imageAsset!,
                          width: 112,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: isLuxury
                              ? const Color(0xFFE8C766).withOpacity(0.14)
                              : const Color(0xFFEFF6FF),
                          child: Center(
                            child: Icon(
                              icon,
                              color: accentColor,
                              size: 44,
                            ),
                          ),
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
                      Text(
                        price,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
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
