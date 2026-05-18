import 'package:flutter/material.dart';

import '../services/api_service.dart';

class TripsScreen extends StatefulWidget {
  final String selectedMode;

  const TripsScreen({
    super.key,
    this.selectedMode = 'Casual',
  });

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final ApiService _apiService = ApiService();
  final List<String> tabs = ['Ongoing', 'Favorites', 'Saved', 'Past'];

  String selectedTab = 'Ongoing';
  bool isLoading = false;
  String? errorMessage;
  List<TripItem> currentTrips = [];
  Map<String, int> counts = {
    'ongoing': 0,
    'favorites': 0,
    'saved': 0,
    'past': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  String get _selectedStatus => _statusForTab(selectedTab);

  String _statusForTab(String tab) {
    if (tab == 'Saved') return 'saved';
    if (tab == 'Past') return 'past';
    return 'ongoing';
  }

  Future<void> _loadTrips() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedCounts = await _apiService.getTripCounts();
      final loadedFavorites = await _apiService.getFavorites();
      final loadedTrips = selectedTab == 'Favorites'
          ? loadedFavorites
          : await _apiService.getTrips(status: _selectedStatus);

      if (!mounted) return;

      setState(() {
        counts = {
          ...loadedCounts,
          'favorites': loadedFavorites.length,
        };
        currentTrips = loadedTrips
            .map<TripItem>(
              selectedTab == 'Favorites'
                  ? TripItem.fromFavoriteJson
                  : TripItem.fromJson,
            )
            .where(
              (trip) => selectedTab == 'Favorites' || trip.isPackageTrip,
            )
            .toList(growable: false);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = ApiService.cleanErrorMessage(error);
        currentTrips = [];
        isLoading = false;
      });
    }
  }

  Future<void> _updateTripStatus(TripItem trip, String status) async {
    try {
      await _apiService.updateTripStatus(trip.id, status);
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _updateTripStatusFromSheet(
    TripItem trip,
    String status,
    String message,
  ) async {
    try {
      await _apiService.updateTripStatus(trip.id, status);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _deleteTripFromSheet(TripItem trip, String message) async {
    try {
      await _apiService.deleteTrip(trip.id);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _removeFavoriteFromSheet(TripItem trip) async {
    try {
      await _apiService.removeFavorite(trip.favoriteTargetIdForApi);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites.')),
      );
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _saveFavoritePackageToTrips(TripItem trip) async {
    if (!trip.isPackageItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only packages can be saved to trips.'),
        ),
      );
      return;
    }

    try {
      await _apiService.saveTrip({
        'item_key': trip.itemKey,
        'title': trip.title,
        'location': trip.location,
        'image': trip.image,
        'selected_mode': trip.selectedMode,
        'status': 'saved',
        'tags': trip.interests,
        'price': trip.price,
        'rating': trip.rating,
        'duration': trip.duration,
        'item_type': 'package',
        'target_type': 'ai_package',
        'source_collection': trip.sourceCollection.isEmpty
            ? 'hardcoded_package'
            : trip.sourceCollection,
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package saved to trips.')),
      );
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _addTripToFavorites(TripItem trip) async {
    try {
      await _apiService.addFavorite({
        'target_id': trip.itemKey,
        'target_type': 'package',
        'item_key': trip.itemKey,
        'item_type': 'package',
        'title': trip.title,
        'location': trip.location,
        'image': trip.image,
        'selected_mode': trip.selectedMode,
        'tags': trip.interests,
        'price': trip.price,
        'rating': trip.rating,
        'duration': trip.duration,
        'source_collection': trip.sourceCollection.isEmpty
            ? 'hardcoded_package'
            : trip.sourceCollection,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites.')),
      );
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _removeTripFavoriteFromSheet(TripItem trip) async {
    try {
      await _apiService.removeFavorite(trip.itemKey);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites.')),
      );
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _showTripDetailSheet(TripItem trip) async {
    final isTripPackage = trip.status != 'favorite' || trip.isPackageFavorite;
    bool isAlreadyFavorite = false;

    if (isTripPackage && trip.status != 'favorite' && trip.itemKey.isNotEmpty) {
      try {
        isAlreadyFavorite = await _apiService.checkFavorite(trip.itemKey);
      } catch (_) {
        isAlreadyFavorite = false;
      }
    }

    if (!mounted) return;

    final isLuxury = widget.selectedMode == 'Luxury';
    final isNight = widget.selectedMode == 'Night';
    final cardColor = isLuxury || isNight ? const Color(0xFF111827) : Colors.white;
    final primaryTextColor = isLuxury || isNight
        ? Colors.white
        : const Color(0xFF111827);
    final secondaryTextColor = isLuxury
        ? const Color(0xFFB8B8B8)
        : isNight
            ? const Color(0xFFB8B8D1)
            : const Color(0xFF64748B);
    final accentColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : const Color(0xFF2563EB);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: secondaryTextColor.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _TripDetailImage(
                  image: trip.image,
                  icon: trip.icon,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                Text(
                  trip.title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 23,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (trip.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _TripDetailRow(
                    icon: Icons.location_on_outlined,
                    text: trip.location,
                    color: secondaryTextColor,
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  trip.description,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (trip.selectedMode.isNotEmpty)
                      _DetailPill(label: trip.selectedMode, color: accentColor),
                    if (trip.price.isNotEmpty)
                      _DetailPill(label: trip.price, color: accentColor),
                    if (trip.rating.isNotEmpty)
                      _DetailPill(label: 'Rating ${trip.rating}', color: accentColor),
                    if (trip.duration.isNotEmpty)
                      _DetailPill(label: trip.duration, color: accentColor),
                    ...trip.interests.map(
                      (tag) => _DetailPill(label: tag, color: accentColor),
                    ),
                  ],
                ),
                if (isTripPackage && trip.includedItems.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Included in this package',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...trip.includedItems.map(
                    (item) => _IncludedPackageItemCard(
                      item: item,
                      accentColor: accentColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ..._detailActionsForTrip(
                  trip,
                  accentColor,
                  isLuxury,
                  isAlreadyFavorite,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _detailActionsForTrip(
    TripItem trip,
    Color accentColor,
    bool isLuxury,
    bool isAlreadyFavorite,
  ) {
    final actions = <Widget>[];

    void addAction({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
      bool danger = false,
    }) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: danger
                    ? const Color(0xFFDC2626)
                    : accentColor,
                foregroundColor: isLuxury && !danger
                    ? const Color(0xFF111827)
                    : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (trip.status == 'favorite') {
      addAction(
        label: 'Remove from Favorites',
        icon: Icons.favorite_border,
        danger: true,
        onPressed: () => _removeFavoriteFromSheet(trip),
      );

      if (trip.isPackageFavorite) {
        addAction(
          label: 'Add Package to Plan',
          icon: Icons.bookmark_add_outlined,
          onPressed: () => _saveFavoritePackageToTrips(trip),
        );
      }
    } else if (trip.status == 'saved') {
      addAction(
        label: 'Start Trip',
        icon: Icons.play_arrow_rounded,
        onPressed: () => _updateTripStatusFromSheet(
          trip,
          'ongoing',
          'Trip started.',
        ),
      );
      addAction(
        label: 'Remove from Saved',
        icon: Icons.delete_outline,
        danger: true,
        onPressed: () => _deleteTripFromSheet(
          trip,
          'Removed from saved trips.',
        ),
      );
      addAction(
        label: isAlreadyFavorite ? 'Remove from Favorites' : 'Add to Favorites',
        icon: isAlreadyFavorite ? Icons.favorite : Icons.favorite_border,
        danger: isAlreadyFavorite,
        onPressed: isAlreadyFavorite
            ? () => _removeTripFavoriteFromSheet(trip)
            : () => _addTripToFavorites(trip),
      );
    } else if (trip.status == 'ongoing') {
      addAction(
        label: 'Mark as Past',
        icon: Icons.history,
        onPressed: () => _updateTripStatusFromSheet(
          trip,
          'past',
          'Trip moved to past.',
        ),
      );
      if (isAlreadyFavorite) {
        addAction(
          label: 'Remove from Favorites',
          icon: Icons.favorite,
          danger: true,
          onPressed: () => _removeTripFavoriteFromSheet(trip),
        );
      } else {
        addAction(
          label: 'Add to Favorites',
          icon: Icons.favorite_border,
          onPressed: () => _addTripToFavorites(trip),
        );
      }
    } else if (trip.status == 'past') {
      if (isAlreadyFavorite) {
        addAction(
          label: 'Remove from Favorites',
          icon: Icons.favorite,
          danger: true,
          onPressed: () => _removeTripFavoriteFromSheet(trip),
        );
      } else {
        addAction(
          label: 'Add to Favorites',
          icon: Icons.favorite_border,
          onPressed: () => _addTripToFavorites(trip),
        );
      }
    }

    actions.add(
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor.withOpacity(0.55)),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Close',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );

    return actions;
  }

  String get _emptyMessage {
    if (selectedTab == 'Favorites') return 'No favorites yet.';
    if (selectedTab == 'Saved') return 'No saved trips yet.';
    if (selectedTab == 'Past') return 'No past trips yet.';
    return 'No ongoing trips yet.';
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
    final cardColor = isLuxury
        ? const Color(0xFF0B1020)
        : isNight
            ? const Color(0xFF111827)
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
            : const Color(0xFF64748B);
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trips',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _TripSummaryCard(
                    label: 'Ongoing',
                    number: '${counts['ongoing'] ?? 0}',
                    icon: Icons.sync,
                    color: const Color(0xFF10B981),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Favorites',
                    number: '${counts['favorites'] ?? 0}',
                    icon: Icons.favorite,
                    color: const Color(0xFFEC4899),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Saved',
                    number: '${counts['saved'] ?? 0}',
                    icon: Icons.bookmark,
                    color: const Color(0xFF2563EB),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Past',
                    number: '${counts['past'] ?? 0}',
                    icon: Icons.history,
                    color: const Color(0xFFF59E0B),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isLuxury || isNight ? cardColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isLuxury || isNight ? borderColor : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: tabs.map((tab) {
                    final isSelected = selectedTab == tab;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (selectedTab == tab) return;

                          setState(() {
                            selectedTab = tab;
                          });
                          _loadTrips();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected
                                  ? isLuxury
                                      ? const Color(0xFF111827)
                                      : Colors.white
                                  : secondaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 26),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else if (currentTrips.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      _emptyMessage,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: currentTrips.map((trip) {
                    return _TripLargeCard(
                      trip: trip,
                      isLuxury: isLuxury,
                      isNight: isNight,
                      onTap: () => _showTripDetailSheet(trip),
                      onAction: trip.status == 'saved'
                          ? () => _updateTripStatus(trip, 'ongoing')
                          : trip.status == 'ongoing'
                              ? () => _updateTripStatus(trip, 'past')
                              : null,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TripItem {
  final String id;
  final String itemKey;
  final String favoriteTargetId;
  final String itemType;
  final String targetType;
  final String sourceCollection;
  final String title;
  final String location;
  final String image;
  final String selectedMode;
  final String price;
  final String rating;
  final String duration;
  final String status;
  final String action;
  final List<String> interests;
  final IconData icon;

  TripItem({
    required this.id,
    required this.itemKey,
    required this.favoriteTargetId,
    required this.itemType,
    required this.targetType,
    required this.sourceCollection,
    required this.title,
    required this.location,
    required this.image,
    required this.selectedMode,
    required this.price,
    required this.rating,
    required this.duration,
    required this.status,
    required this.action,
    required this.interests,
    required this.icon,
  });

  factory TripItem.fromJson(Map<String, dynamic> json) {
    final status = _readString(json['status'], fallback: 'saved');
    final title = _readString(json['title'], fallback: 'Untitled trip');
    final image = _readString(
      json['image'] ??
          json['cover_image_url'] ??
          json['image_url'] ??
          json['thumbnail'] ??
          json['asset_image'],
      fallback: _packageImageForTitle(title),
    );

    return TripItem(
      id: _readString(json['_id'] ?? json['id']),
      itemKey: _readString(json['item_key'] ?? json['_id'] ?? json['id']),
      favoriteTargetId: _readString(json['target_id'] ?? json['item_key']),
      itemType: _readString(json['item_type'], fallback: 'package'),
      targetType: _readString(json['target_type'], fallback: 'ai_package'),
      sourceCollection: _readString(json['source_collection']),
      title: title,
      location: _readString(json['location']),
      image: image,
      selectedMode: _displayMode(
        _readString(json['selected_mode'] ?? json['travel_mode']),
      ),
      price: _readString(json['price'] ?? json['estimated_cost']),
      rating: _readString(json['rating']),
      duration: _readString(json['duration'], fallback: 'Trip plan'),
      status: status,
      action: _actionForStatus(status),
      interests: _readStringList(json['tags']),
      icon: _iconForStatus(status),
    );
  }

  factory TripItem.fromFavoriteJson(Map<String, dynamic> json) {
    final itemType = _readString(json['item_type'], fallback: 'Favorite');
    final title = _readString(json['title'], fallback: 'Untitled favorite');
    final image = _readString(
      json['image'] ??
          json['cover_image_url'] ??
          json['image_url'] ??
          json['thumbnail'] ??
          json['asset_image'],
      fallback: _packageImageForTitle(title),
    );

    return TripItem(
      id: _readString(json['_id'] ?? json['id']),
      itemKey: _readString(json['item_key'] ?? json['target_id']),
      favoriteTargetId: _readString(json['target_id'] ?? json['item_key']),
      itemType: itemType,
      targetType: _readString(json['target_type']),
      sourceCollection: _readString(json['source_collection']),
      title: title,
      location: _readString(json['location']),
      image: image,
      selectedMode: _displayMode(
        _readString(json['selected_mode'] ?? json['travel_mode']),
      ),
      price: _readString(json['price']),
      rating: _readString(json['rating']),
      duration: _readString(json['duration'], fallback: 'Favorite'),
      status: 'favorite',
      action: 'View favorite',
      interests: _readStringList(json['tags']).isEmpty
          ? [itemType]
          : _readStringList(json['tags']),
      icon: Icons.favorite,
    );
  }

  String get displayStatus {
    if (status == 'ongoing') return 'Ongoing';
    if (status == 'past') return 'Past';
    if (status == 'favorite') return 'Favorite';
    return 'Saved';
  }

  bool get isPackageItem {
    final normalizedType = itemType.toLowerCase();
    final normalizedTargetType = targetType.toLowerCase();
    final normalizedSource = sourceCollection.toLowerCase();
    final nonPackageTypes = {
      'activity',
      'hotel',
      'restaurant',
      'nightlife',
      'place',
      'travel_item',
    };

    if (nonPackageTypes.contains(normalizedType)) {
      return false;
    }

    return normalizedType == 'package' ||
        normalizedType == 'ai_package' ||
        normalizedTargetType == 'ai_package' ||
        normalizedSource == 'ai_packages' ||
        normalizedSource == 'hardcoded_package';
  }

  bool get isPackageFavorite => isPackageItem;

  bool get isPackageTrip => status != 'favorite' && isPackageItem;

  String get favoriteTargetIdForApi {
    if (favoriteTargetId.isNotEmpty) return favoriteTargetId;
    return itemKey;
  }

  String get description {
    final typeLabel = status == 'favorite'
        ? isPackageFavorite
            ? 'Favorite package'
            : 'Favorite ${itemType.isEmpty ? 'place' : itemType}'
        : '$displayStatus package';
    final locationText = location.isEmpty ? 'your trip list' : location;
    final modeText = selectedMode.isEmpty ? 'selected' : selectedMode;
    return '$typeLabel in $locationText with a $modeText travel style.';
  }

  List<IncludedPackageItem> get includedItems {
    return IncludedPackageItem.forPackage(title);
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
    return fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  static String _displayMode(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'night') return 'Night';
    if (normalized == 'luxury') return 'Luxury';
    if (normalized == 'casual') return 'Casual';
    return value;
  }

  static String _packageImageForTitle(String title) {
    if (title == 'Tokyo Discovery Tour') return 'assets/images/tokyo.webp';
    if (title == 'Rome First-Time Tour') return 'assets/images/rome.jpg';
    if (title == 'Dubai City Highlights') return 'assets/images/dubai.png';
    if (title == 'Halong Bay Seaplane Tour') return 'assets/images/halongbay.jpg';
    if (title == 'Dubai Elite Yacht Escape') return 'assets/images/dubaiyacht.jpg';
    if (title == 'Private Island Stay') return 'assets/images/prvtislandstay.webp';
    if (title == 'Just Cavalli Club') return 'assets/images/justcavalli.jpg';
    if (title == 'Private Bavarian Alps Tour') {
      return 'assets/images/privatebavariantour.jpg';
    }
    return '';
  }

  static String _actionForStatus(String status) {
    if (status == 'saved') return 'Start Trip';
    if (status == 'ongoing') return 'Mark as Past';
    return 'View memories';
  }

  static IconData _iconForStatus(String status) {
    if (status == 'saved') return Icons.bookmark;
    if (status == 'past') return Icons.history;
    return Icons.sync;
  }
}

class IncludedPackageItem {
  final String imageAsset;
  final IconData icon;
  final String type;
  final String title;
  final String subtitle;
  final String duration;
  final String price;
  final String rating;

  const IncludedPackageItem({
    required this.imageAsset,
    required this.icon,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.price,
    required this.rating,
  });

  static List<IncludedPackageItem> forPackage(String packageTitle) {
    if (packageTitle == 'Tokyo Discovery Tour') {
      return const [
        IncludedPackageItem(
          imageAsset: 'assets/images/asakusatemple.jpg',
          icon: Icons.temple_buddhist_outlined,
          type: 'activity',
          title: 'Asakusa Temple Visit',
          subtitle: 'Traditional culture and historic streets',
          duration: '2h',
          price: '\$95',
          rating: '4.8',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/shibuyacrossing.jpg',
          icon: Icons.train_outlined,
          type: 'activity',
          title: 'Shibuya Crossing',
          subtitle: 'Famous city lights and urban energy',
          duration: '1h',
          price: '\$80',
          rating: '4.7',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/japanesefood.jpg',
          icon: Icons.ramen_dining_outlined,
          type: 'restaurant',
          title: 'Local Food Stop',
          subtitle: 'Ramen, sushi, and street snacks',
          duration: '1.5h',
          price: '\$165',
          rating: '4.9',
        ),
      ];
    }

    if (packageTitle == 'Rome First-Time Tour') {
      return const [
        IncludedPackageItem(
          imageAsset: 'assets/images/colosseum.webp',
          icon: Icons.account_balance_outlined,
          type: 'activity',
          title: 'Colosseum Tour',
          subtitle: 'Ancient Rome guided landmark visit',
          duration: '2h',
          price: '\$90',
          rating: '4.8',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/vatican.webp',
          icon: Icons.church_outlined,
          type: 'activity',
          title: 'Vatican Visit',
          subtitle: 'Art, history, museums, and culture',
          duration: '2.5h',
          price: '\$120',
          rating: '4.7',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/pizza.jpg',
          icon: Icons.restaurant_outlined,
          type: 'restaurant',
          title: 'Roman Food Walk',
          subtitle: 'Pasta, pizza, gelato, and local bites',
          duration: '1.5h',
          price: '\$110',
          rating: '4.9',
        ),
      ];
    }

    if (packageTitle == 'Dubai City Highlights') {
      return const [
        IncludedPackageItem(
          imageAsset: 'assets/images/burjkhalifa.jpg',
          icon: Icons.location_city_outlined,
          type: 'activity',
          title: 'Burj Khalifa Visit',
          subtitle: 'City skyline views from the top',
          duration: '1.5h',
          price: '\$120',
          rating: '4.8',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/dubaimall.jpg',
          icon: Icons.shopping_bag_outlined,
          type: 'activity',
          title: 'Dubai Mall Stop',
          subtitle: 'Shopping, cafes, and attractions',
          duration: '2h',
          price: '\$70',
          rating: '4.6',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/dubaimarina.webp',
          icon: Icons.waves_outlined,
          type: 'activity',
          title: 'Marina Walk',
          subtitle: 'Waterfront walk with skyline views',
          duration: '1h',
          price: '\$100',
          rating: '4.7',
        ),
      ];
    }

    if (packageTitle == 'Halong Bay Seaplane Tour') {
      return const [
        IncludedPackageItem(
          imageAsset: 'assets/images/seaplane.jpg',
          icon: Icons.flight_takeoff,
          type: 'activity',
          title: 'Scenic Seaplane Flight',
          subtitle: 'Aerial views over limestone islands',
          duration: '45m',
          price: '\$420',
          rating: '4.9',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/halongcruise.jpg',
          icon: Icons.directions_boat_outlined,
          type: 'activity',
          title: 'Private Bay Cruise',
          subtitle: 'Luxury cruise through emerald waters',
          duration: '3h',
          price: '\$380',
          rating: '4.8',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/halongcave.jpg',
          icon: Icons.landscape_outlined,
          type: 'activity',
          title: 'Cave & Island Stop',
          subtitle: 'Hidden caves and island viewpoints',
          duration: '2h',
          price: '\$180',
          rating: '4.7',
        ),
      ];
    }

    if (packageTitle == 'Dubai Elite Yacht Escape') {
      return const [
        IncludedPackageItem(
          imageAsset: 'assets/images/5starhotel.webp',
          icon: Icons.hotel_outlined,
          type: 'hotel',
          title: 'Five-Star Hotel Stay',
          subtitle: 'Luxury suite with skyline views',
          duration: '1 night',
          price: '\$650',
          rating: '4.9',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/privateyachttour.jpg',
          icon: Icons.directions_boat_outlined,
          type: 'activity',
          title: 'Private Yacht Tour',
          subtitle: 'Premium marina cruise with sea views',
          duration: '2h',
          price: '\$850',
          rating: '4.8',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/finedining.webp',
          icon: Icons.restaurant_menu,
          type: 'restaurant',
          title: 'Fine Dining Experience',
          subtitle: 'Upscale dinner with curated menu',
          duration: '2h',
          price: '\$350',
          rating: '4.9',
        ),
      ];
    }

    if (packageTitle == 'Private Island Stay') {
      return const [
        IncludedPackageItem(
          imageAsset: 'assets/images/privatevilla.jpg',
          icon: Icons.villa_outlined,
          type: 'hotel',
          title: 'Private Island Villa',
          subtitle: 'Exclusive villa with ocean views',
          duration: '1 night',
          price: '\$1800',
          rating: '4.9',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/yachttransfer.jpg',
          icon: Icons.directions_boat_outlined,
          type: 'activity',
          title: 'Yacht Transfer',
          subtitle: 'Private yacht arrival experience',
          duration: '1h',
          price: '\$950',
          rating: '4.8',
        ),
        IncludedPackageItem(
          imageAsset: 'assets/images/sunsetdining.webp',
          icon: Icons.restaurant_menu,
          type: 'restaurant',
          title: 'Sunset Fine Dining',
          subtitle: 'Beachfront dinner with curated menu',
          duration: '2h',
          price: '\$700',
          rating: '4.9',
        ),
      ];
    }

    return const [];
  }
}

class _TripSummaryCard extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;
  final Color color;
  final bool isLuxury;
  final bool isNight;

  const _TripSummaryCard({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLuxury || isNight ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLuxury
                ? const Color(0xFFE8C766).withOpacity(0.25)
                : isNight
                    ? const Color(0xFFA855F7).withOpacity(0.25)
                    : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.13),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLuxury
                          ? const Color(0xFFB8B8B8)
                          : isNight
                              ? const Color(0xFFB8B8D1)
                              : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripLargeCard extends StatelessWidget {
  final TripItem trip;
  final bool isLuxury;
  final bool isNight;
  final VoidCallback onTap;
  final VoidCallback? onAction;

  const _TripLargeCard({
    required this.trip,
    required this.isLuxury,
    required this.isNight,
    required this.onTap,
    this.onAction,
  });

  Color get statusColor {
    if (trip.status == 'ongoing') return const Color(0xFF10B981);
    if (trip.status == 'past') return const Color(0xFFF59E0B);
    if (trip.status == 'favorite') return const Color(0xFFEC4899);
    return const Color(0xFF7C3AED);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 255,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isLuxury
                ? const [
                    Color(0xFF0B1020),
                    Color(0xFF111827),
                  ]
                : isNight
                    ? const [
                        Color(0xFF111827),
                        Color(0xFF2E1065),
                      ]
                    : [
                        statusColor.withOpacity(0.95),
                        const Color(0xFF111827),
                      ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isLuxury
                ? const Color(0xFFE8C766).withOpacity(0.35)
                : isNight
                    ? const Color(0xFFA855F7).withOpacity(0.35)
                    : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: isLuxury
                  ? Colors.black.withOpacity(0.35)
                  : isNight
                      ? Colors.black.withOpacity(0.35)
                      : statusColor.withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (trip.image.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _TripCardImage(
                    image: trip.image,
                    icon: trip.icon,
                    accentColor: statusColor,
                  ),
                ),
              ),
            if (trip.image.isNotEmpty)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.72),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                trip.icon,
                size: 140,
                color: Colors.white.withOpacity(
                  trip.image.isEmpty ? 0.12 : 0.08,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isLuxury
                            ? const Color(0xFFE8C766)
                            : isNight
                                ? const Color(0xFFA855F7)
                                : Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        trip.displayStatus,
                        style: TextStyle(
                          color: isLuxury
                              ? const Color(0xFF111827)
                              : isNight
                                  ? Colors.white
                                  : statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        trip.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (trip.interests.isEmpty
                            ? [trip.displayStatus]
                            : trip.interests)
                        .map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isLuxury || isNight
                              ? const Color(0xFF111827)
                              : Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: isLuxury
                                ? const Color(0xFFE8C766)
                                : isNight
                                    ? const Color(0xFFE879F9)
                                    : statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (onAction == null)
                        Text(
                          trip.action,
                          style: TextStyle(
                            color: isLuxury
                                ? const Color(0xFFE8C766)
                                : isNight
                                    ? const Color(0xFFE879F9)
                                    : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: onAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLuxury
                                ? const Color(0xFFE8C766)
                                : isNight
                                    ? const Color(0xFFA855F7)
                                    : Colors.white,
                            foregroundColor: isLuxury || !isNight
                                ? const Color(0xFF111827)
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            trip.action,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.chevron_right,
                        color: isLuxury
                            ? const Color(0xFFE8C766)
                            : isNight
                                ? const Color(0xFFE879F9)
                                : Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripDetailImage extends StatelessWidget {
  final String image;
  final IconData icon;
  final Color accentColor;

  const _TripDetailImage({
    required this.image,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: accentColor,
          size: 52,
        ),
      );
    }

    if (image.isEmpty) {
      return fallback();
    }

    final imageWidget = image.startsWith('http')
        ? Image.network(
            image,
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback(),
          )
        : Image.asset(
            image,
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: imageWidget,
    );
  }
}

class _IncludedPackageItemCard extends StatelessWidget {
  final IncludedPackageItem item;
  final Color accentColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isLuxury;
  final bool isNight;

  const _IncludedPackageItemCard({
    required this.item,
    required this.accentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLuxury || isNight ? const Color(0xFF0B1020) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Image.asset(
                item.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: accentColor.withOpacity(0.12),
                    child: Icon(item.icon, color: accentColor, size: 34),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.type,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        item.duration,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.price,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        item.rating,
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

class _TripCardImage extends StatelessWidget {
  final String image;
  final IconData icon;
  final Color accentColor;

  const _TripCardImage({
    required this.image,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return Container(
        color: accentColor.withOpacity(0.20),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.35),
          size: 54,
        ),
      );
    }

    if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }
}

class _TripDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TripDetailRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
