import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../services/api_service.dart';
import '../services/sample_data.dart';
import 'destination_details_screen.dart';

class _TypeFilterOption {
  final String label;
  final String? type;
  final IconData icon;

  const _TypeFilterOption({
    required this.label,
    required this.type,
    required this.icon,
  });
}

const List<_TypeFilterOption> _typeFilterOptions = [
  _TypeFilterOption(label: 'All', type: null, icon: Icons.public),
  _TypeFilterOption(
    label: 'Activities',
    type: 'activity',
    icon: Icons.map_outlined,
  ),
  _TypeFilterOption(label: 'Hotels', type: 'hotel', icon: Icons.hotel_outlined),
  _TypeFilterOption(
    label: 'Food / Restaurants',
    type: 'restaurant',
    icon: Icons.restaurant_outlined,
  ),
  _TypeFilterOption(
    label: 'Nightlife',
    type: 'nightlife',
    icon: Icons.nightlife_outlined,
  ),
];

class ExploreScreen extends StatefulWidget {
  final String selectedMode;

  const ExploreScreen({super.key, this.selectedMode = 'Casual'});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String? selectedTypeFilter;
  bool isLoadingPlaces = false;
  String? placesError;
  List<PlaceModel> normalPlaces = SampleData.places;

  final ApiService _apiService = ApiService();
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  int _placesRequestId = 0;
  Timer? _suggestionsDebounce;
  int _suggestionsRequestId = 0;
  bool isLoadingSuggestions = false;
  List<TravelItemSuggestion> searchSuggestions = [];
  final Set<String> favoriteItemKeys = {};

  @override
  void initState() {
    super.initState();
    if (_usesBackendPlaces(widget.selectedMode)) {
      _loadNormalPlaces();
    }
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usesBackendPlaces(widget.selectedMode) &&
        oldWidget.selectedMode != widget.selectedMode) {
      _loadNormalPlaces();
    } else if (_usesBackendPlaces(oldWidget.selectedMode) &&
        !_usesBackendPlaces(widget.selectedMode)) {
      _clearSuggestions();
    }
  }

  @override
  void dispose() {
    _suggestionsDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNormalPlaces() async {
    final requestId = ++_placesRequestId;

    setState(() {
      isLoadingPlaces = true;
      placesError = null;
    });

    try {
      final places = await _apiService.getTravelItems(
        type: _currentApiType,
        budgetLevel: _currentApiBudgetLevel,
        nightlife: _currentApiNightlife,
        includeImages: true,
        limit: _currentBackendLimit,
      );

      if (!mounted || requestId != _placesRequestId) return;

      setState(() {
        normalPlaces = _visiblePlacesForCurrentMode(places);
        isLoadingPlaces = false;
      });
    } catch (error) {
      if (!mounted || requestId != _placesRequestId) return;

      setState(() {
        normalPlaces = _fallbackPlacesForCurrentMode();
        placesError = error.toString();
        isLoadingPlaces = false;
      });
    }
  }

  Future<void> _searchNormalPlaces(String query) async {
    final requestId = ++_placesRequestId;
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await _loadNormalPlaces();
      return;
    }

    setState(() {
      isLoadingPlaces = true;
      placesError = null;
    });

    try {
      final places = await _apiService.searchTravelItems(
        query: trimmedQuery,
        type: _currentApiType,
        budgetLevel: _currentApiBudgetLevel,
        nightlife: _currentApiNightlife,
        includeImages: true,
        limit: 20,
      );

      if (!mounted || requestId != _placesRequestId) return;

      setState(() {
        normalPlaces = places;
        isLoadingPlaces = false;
      });
    } catch (error) {
      if (!mounted || requestId != _placesRequestId) return;

      setState(() {
        normalPlaces = _fallbackPlacesForCurrentMode();
        placesError = error.toString();
        isLoadingPlaces = false;
      });
    }
  }

  Future<void> _loadPlacesForSuggestion(TravelItemSuggestion suggestion) async {
    final requestId = ++_placesRequestId;
    _suggestionsDebounce?.cancel();
    _suggestionsRequestId++;

    setState(() {
      searchText = suggestion.value;
      searchSuggestions = [];
      isLoadingSuggestions = false;
      placesError = null;
    });
    searchController.text = suggestion.value;
    searchController.selection = TextSelection.collapsed(
      offset: searchController.text.length,
    );

    setState(() {
      isLoadingPlaces = true;
    });

    try {
      final List<PlaceModel> places;
      if (suggestion.kind == 'city') {
        places = await _apiService.getTravelItems(
          city: suggestion.value,
          type: _currentApiType,
          budgetLevel: _currentApiBudgetLevel,
          nightlife: _currentApiNightlife,
          includeImages: true,
          limit: 20,
        );
      } else if (suggestion.kind == 'country') {
        places = await _apiService.getTravelItems(
          country: suggestion.value,
          type: _currentApiType,
          budgetLevel: _currentApiBudgetLevel,
          nightlife: _currentApiNightlife,
          includeImages: true,
          limit: 20,
        );
      } else {
        places = await _apiService.searchTravelItems(
          query: suggestion.value,
          type: _currentApiType,
          budgetLevel: _currentApiBudgetLevel,
          nightlife: _currentApiNightlife,
          includeImages: true,
          limit: 20,
        );
      }

      if (!mounted || requestId != _placesRequestId) return;

      setState(() {
        normalPlaces = places;
        isLoadingPlaces = false;
      });
    } catch (error) {
      if (!mounted || requestId != _placesRequestId) return;

      setState(() {
        normalPlaces = _fallbackPlacesForCurrentMode();
        placesError = error.toString();
        isLoadingPlaces = false;
      });
    }
  }

  void _handleSearchChanged(String value) {
    setState(() {
      searchText = value;
    });

    if (!_usesBackendPlaces(widget.selectedMode)) {
      return;
    }

    final query = value.trim();
    _suggestionsDebounce?.cancel();

    if (query.isEmpty) {
      _suggestionsRequestId++;
      _clearSuggestions();
      return;
    }

    if (query.length < 2) {
      _suggestionsRequestId++;
      _clearSuggestions();
      return;
    }

    _suggestionsDebounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length >= 2) {
        _loadSuggestions(query);
      }
    });
  }

  Future<void> _loadSuggestions(String query) async {
    final requestId = ++_suggestionsRequestId;
    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final suggestions = await _apiService.getTravelItemSuggestions(
        query: query,
        type: _currentApiType,
        budgetLevel: _currentApiBudgetLevel,
        nightlife: _currentApiNightlife,
        limit: 5,
      );

      if (!mounted || requestId != _suggestionsRequestId) return;
      if (searchController.text.trim() != query) return;
      if (!_usesBackendPlaces(widget.selectedMode)) return;

      setState(() {
        searchSuggestions = suggestions.take(5).toList(growable: false);
        isLoadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted || requestId != _suggestionsRequestId) return;

      setState(() {
        searchSuggestions = [];
        isLoadingSuggestions = false;
      });
    }
  }

  void _clearSuggestions() {
    if (!mounted) return;
    setState(() {
      searchSuggestions = [];
      isLoadingSuggestions = false;
    });
  }

  void _clearSearch() {
    _suggestionsDebounce?.cancel();
    _suggestionsRequestId++;
    searchController.clear();
    setState(() {
      searchText = '';
      searchSuggestions = [];
      isLoadingSuggestions = false;
    });

    if (_usesBackendPlaces(widget.selectedMode)) {
      _loadNormalPlaces();
    }
  }

  void _handleSearchSubmitted(String value) {
    if (!_usesBackendPlaces(widget.selectedMode)) {
      return;
    }

    _suggestionsDebounce?.cancel();
    _suggestionsRequestId++;
    _clearSuggestions();
    _searchNormalPlaces(value);
  }

  void _showTypeFilterSheet() {
    if (!_isNormalMode(widget.selectedMode)) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter places',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._typeFilterOptions.map((option) {
                  final isSelected = selectedTypeFilter == option.type;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(option.icon, color: const Color(0xFF2563EB)),
                    title: Text(
                      option.label,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2563EB),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _applyTypeFilter(option.type);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLuxuryFilterSheet() {
    if (widget.selectedMode != 'Luxury') {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter premium places',
                        style: TextStyle(
                          color: Color(0xFFFFF8E1),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFFE8C766),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._typeFilterOptions.map((option) {
                  final isSelected = selectedTypeFilter == option.type;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      option.icon,
                      color: const Color(0xFFE8C766),
                    ),
                    title: Text(
                      option.label,
                      style: const TextStyle(
                        color: Color(0xFFFFF8E1),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFFE8C766),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _applyTypeFilter(option.type);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNightFilterSheet() {
    if (widget.selectedMode != 'Night') {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        const options = [
          {'label': 'Nightclubs', 'icon': Icons.nightlife_outlined},
          {'label': 'Bars', 'icon': Icons.local_bar_outlined},
          {'label': 'Rooftops', 'icon': Icons.roofing_outlined},
          {'label': 'Live music', 'icon': Icons.music_note_outlined},
        ];

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Night suggestions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFFA855F7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...options.map((option) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      option['icon'] as IconData,
                      color: const Color(0xFFA855F7),
                    ),
                    title: Text(
                      option['label'] as String,
                      style: const TextStyle(
                        color: Color(0xFFB8B8D1),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () => Navigator.pop(context),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyTypeFilter(String? type) {
    _suggestionsDebounce?.cancel();
    _suggestionsRequestId++;

    setState(() {
      selectedTypeFilter = type;
      searchSuggestions = [];
      isLoadingSuggestions = false;
    });

    final query = searchController.text.trim();
    if (query.isEmpty) {
      _loadNormalPlaces();
    } else {
      _searchNormalPlaces(query);
    }
  }

  void _clearTypeFilter() {
    _applyTypeFilter(null);
  }

  String _itemKeyFromTitle(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _toggleExploreFavorite(PlaceModel place) async {
    final itemKey = _itemKeyFromTitle(place.name);

    try {
      final isCurrentlyFavorite = favoriteItemKeys.contains(itemKey)
          ? true
          : await _apiService.checkFavorite(itemKey);

      if (isCurrentlyFavorite) {
        await _apiService.removeFavorite(itemKey);
        if (!mounted) return;
        setState(() {
          favoriteItemKeys.remove(itemKey);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites.')),
        );
        return;
      }

      await _apiService.addFavorite({
        'target_id': itemKey,
        'target_type': place.type,
        'item_key': itemKey,
        'item_type': place.type,
        'title': place.name,
        'location': '${place.city}, ${place.country}',
        'image': place.primaryThumbnailUrl ?? place.primaryImageUrl ?? '',
        'selected_mode': widget.selectedMode,
        'tags': place.interestTags.take(3).toList(growable: false),
        'price': '\$${place.cost.toStringAsFixed(0)}',
        'rating': place.rating.toStringAsFixed(1),
        'duration': place.type == 'hotel'
            ? 'per night'
            : '${place.durationHours.toStringAsFixed(1)}h',
        'source_collection': 'travel_items',
      });

      if (!mounted) return;
      setState(() {
        favoriteItemKeys.add(itemKey);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = ApiService.cleanErrorMessage(error).toLowerCase().contains('log in')
          ? 'Please log in to add favorites.'
          : 'Could not update favorite.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showAddToPackageSheet(PlaceModel place) async {
    if (!await ApiService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add items to packages.')),
      );
      return;
    }

    try {
      final packages = await _apiService.getMyPackages();
      final compatiblePackages = packages
          .where(
            (package) =>
                package.country.toLowerCase() == place.country.toLowerCase() &&
                package.city.toLowerCase() == place.city.toLowerCase(),
          )
          .toList(growable: false);

      if (!mounted) return;

      if (compatiblePackages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matching package for this city. Create a package first.'),
          ),
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (context) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Choose package',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...compatiblePackages.map((package) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF2563EB),
                      ),
                      title: Text(
                        package.title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text('${package.city}, ${package.country}'),
                      onTap: () => _addPlaceToPackage(package.id, place),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      final message = ApiService.cleanErrorMessage(error).toLowerCase().contains('log in')
          ? 'Please log in to add items to packages.'
          : ApiService.cleanErrorMessage(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _addPlaceToPackage(String packageId, PlaceModel place) async {
    try {
      await _apiService.addItemToManualPackage(packageId, _placeToPackagePayload(place));
      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(place.type == 'hotel' ? 'Hotel replaced.' : 'Added to package.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  Map<String, dynamic> _placeToPackagePayload(PlaceModel place) {
    return {
      'id': place.id,
      '_id': place.id,
      'name': place.name,
      'type': place.type,
      'country': place.country,
      'city': place.city,
      'category': place.category,
      'cost': place.cost,
      'price': place.cost,
      'currency': place.currency,
      'rating': place.rating,
      'duration_hours': place.durationHours,
      'interest_tags': place.interestTags,
      'images': place.images
          .map(
            (image) => {
              'url': image.url,
              'thumbnail_url': image.thumbnailUrl,
              'source': image.source,
              'alt': image.alt,
              'photographer': image.photographer,
              'source_url': image.sourceUrl,
            },
          )
          .toList(growable: false),
    };
  }

  bool _isNormalMode(String mode) {
    return mode != 'Luxury' && mode != 'Night';
  }

  bool _usesBackendPlaces(String mode) {
    return true;
  }

  String? get _currentApiType {
    if (widget.selectedMode == 'Night') {
      return 'nightlife';
    }
    return selectedTypeFilter;
  }

  String? get _currentApiBudgetLevel {
    return widget.selectedMode == 'Luxury' ? 'luxury' : null;
  }

  bool? get _currentApiNightlife {
    return widget.selectedMode == 'Night' ? true : null;
  }

  int get _currentBackendLimit {
    return 20;
  }

  List<PlaceModel> _visiblePlacesForCurrentMode(List<PlaceModel> places) {
    return places;
  }

  List<PlaceModel> _samplePlacesForSelectedFilter() {
    final type = selectedTypeFilter;
    if (type == null) {
      return SampleData.places;
    }
    return SampleData.places.where((place) => place.type == type).toList();
  }

  List<PlaceModel> _fallbackPlacesForCurrentMode() {
    if (widget.selectedMode == 'Luxury' || widget.selectedMode == 'Night') {
      return [];
    }
    return _samplePlacesForSelectedFilter();
  }

  void _handleSuggestionTap(TravelItemSuggestion suggestion) {
    _loadPlacesForSuggestion(suggestion);
  }

  String get _luxurySectionTitle {
    if (selectedTypeFilter == 'activity') return 'Exclusive activities';
    if (selectedTypeFilter == 'hotel') return 'Luxury hotels';
    if (selectedTypeFilter == 'restaurant') return 'Fine dining restaurants';
    if (selectedTypeFilter == 'nightlife') return 'Premium nightlife';
    return 'Premium places';
  }

  String get _activeFilterLabel {
    return _typeFilterOptions
        .firstWhere(
          (option) => option.type == selectedTypeFilter,
          orElse: () => _typeFilterOptions.first,
        )
        .label;
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
        : const Color(0xFF6B7280);

    final accentColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
        ? const Color(0xFFA855F7)
        : const Color(0xFF2563EB);

    final borderColor = isLuxury
        ? const Color(0xFFE8C766).withValues(alpha: 0.35)
        : isNight
        ? const Color(0xFFA855F7).withValues(alpha: 0.35)
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
                isLuxury
                    ? 'Explore premium places'
                    : isNight
                    ? 'Explore night places'
                    : 'Explore places',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLuxury
                    ? 'Find luxury hotels, fine dining, and exclusive experiences.'
                    : isNight
                    ? 'Find clubs, bars, rooftops, and late-night spots.'
                    : 'Find activities, hotels, and restaurants for your next trip.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isLuxury || isNight
                      ? const Color(0xFF0B1020)
                      : const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLuxury || isNight
                        ? borderColor
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _handleSearchChanged,
                  onSubmitted: _handleSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: isLuxury
                        ? 'Search villas, premium stays, or fine dining...'
                        : isNight
                        ? 'Search clubs, bars, rooftops, or cities...'
                        : 'Search city, hotel, food, activity...',
                    hintStyle: TextStyle(
                      color: isLuxury || isNight
                          ? const Color(0xFFB8B8B8)
                          : const Color(0xFFB0B7C3),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search, color: accentColor),
                    suffixIcon: !_isNormalMode(widget.selectedMode)
                        ? widget.selectedMode == 'Luxury'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Filters',
                                    onPressed: _showLuxuryFilterSheet,
                                    icon: Icon(
                                      Icons.tune,
                                      color: selectedTypeFilter != null
                                          ? const Color(0xFFFFF8E1)
                                          : accentColor,
                                    ),
                                  ),
                                  if (searchText.isNotEmpty ||
                                      selectedTypeFilter != null)
                                    IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: _clearSearch,
                                      icon: Icon(
                                        Icons.close,
                                        color: accentColor,
                                      ),
                                    ),
                                ],
                              )
                            : widget.selectedMode == 'Night'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Filters',
                                        onPressed: _showNightFilterSheet,
                                        icon: Icon(
                                          Icons.tune,
                                          color: accentColor,
                                        ),
                                      ),
                                      if (searchText.isNotEmpty)
                                        IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: _clearSearch,
                                          icon: Icon(
                                            Icons.close,
                                            color: accentColor,
                                          ),
                                        ),
                                    ],
                                  )
                            : searchText.isEmpty
                                ? Icon(Icons.tune, color: accentColor)
                                : IconButton(
                                    onPressed: _clearSearch,
                                    icon: Icon(Icons.close, color: accentColor),
                                  )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Filters',
                                onPressed: _showTypeFilterSheet,
                                icon: Icon(
                                  Icons.tune,
                                  color: selectedTypeFilter == null
                                      ? accentColor
                                      : const Color(0xFF1D4ED8),
                                ),
                              ),
                              if (searchText.isNotEmpty)
                                IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: _clearSearch,
                                  icon: Icon(Icons.close, color: accentColor),
                                ),
                            ],
                          ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  style: TextStyle(
                    color: isLuxury || isNight
                        ? Colors.white
                        : const Color(0xFF111827),
                  ),
                ),
              ),

              if (!isLuxury && !isNight)
                _ActiveFilterChip(
                  label: _activeFilterLabel,
                  isVisible: selectedTypeFilter != null,
                  onClear: _clearTypeFilter,
                ),

              _SearchSuggestionsDropdown(
                suggestions: searchSuggestions,
                isLoading: isLoadingSuggestions,
                accentColor: accentColor,
                borderColor: borderColor,
                isLuxury: isLuxury,
                onSuggestionTap: _handleSuggestionTap,
              ),

              const SizedBox(height: 24),

              if (!isLuxury && !isNight) ...[
                _SectionHeader(
                  title: 'Popular destinations',
                  actionText: 'See all',
                  isLuxury: isLuxury,
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 270,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _PopularDestinationCard(
                        country: 'Italy',
                        cityOne: 'Rome',
                        cityTwo: 'Venice',
                        cityThree: 'Milan',
                        subtitle:
                            'Historic cities, coastal escapes, and world-class food.',
                        icon: '🇮🇹',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DestinationDetailsScreen(
                                destination: 'Italy',
                                country: 'Europe',
                              ),
                            ),
                          );
                        },
                      ),
                      _PopularDestinationCard(
                        country: 'Japan',
                        cityOne: 'Tokyo',
                        cityTwo: 'Kyoto',
                        cityThree: 'Osaka',
                        subtitle:
                            'Temples, city lights, culture, and unforgettable food.',
                        icon: '🇯🇵',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DestinationDetailsScreen(
                                destination: 'Japan',
                                country: 'Asia',
                              ),
                            ),
                          );
                        },
                      ),
                      _PopularDestinationCard(
                        country: 'Brazil',
                        cityOne: 'Rio',
                        cityTwo: 'Salvador',
                        cityThree: 'Brasilia',
                        subtitle:
                            'Beaches, music, nature, and vibrant city life.',
                        icon: '🇧🇷',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DestinationDetailsScreen(
                                destination: 'Brazil',
                                country: 'South America',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],

              if (isNight) ...[
                Text(
                  'Nightlife spots',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                  ),
                ),

                const SizedBox(height: 14),

                ..._getTypeCards(isLuxury: false, isNight: true),
              ] else if (isLuxury) ...[
                Text(
                  'Browse premium services',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                  ),
                ),

                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _typeFilterOptions.map((option) {
                      final isSelected = selectedTypeFilter == option.type;

                      return GestureDetector(
                        onTap: () => _applyTypeFilter(option.type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : cardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? accentColor : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                option.icon,
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF111827)
                                    : secondaryTextColor,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                option.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF111827)
                                      : secondaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _luxurySectionTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                  ),
                ),

                const SizedBox(height: 14),

                ..._getTypeCards(isLuxury: true, isNight: false),
              ] else ...[
                Text(
                  selectedTypeFilter == null ? 'Places' : _activeFilterLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                  ),
                ),

                const SizedBox(height: 14),

                ..._getTypeCards(isLuxury: isLuxury, isNight: false),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getTypeCards({required bool isLuxury, required bool isNight}) {
    if (isLoadingPlaces) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final cards = <Widget>[
      if (placesError != null)
        _ExploreErrorBanner(
          message: isLuxury
              ? 'Could not load luxury places.'
              : isNight
              ? 'Could not load nightlife places.'
              : 'Could not load live places. Showing saved places instead.',
        ),
    ];

    if (normalPlaces.isEmpty) {
      cards.add(
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: Text(
              isLuxury
                  ? 'No luxury places found.'
                  : isNight
                  ? 'No nightlife places found.'
                  : 'No results found.',
              style: TextStyle(
                color: isLuxury
                    ? Color(0xFFB8B8B8)
                    : isNight
                    ? Color(0xFFB8B8D1)
                    : Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );

      return cards;
    }

    cards.addAll(
      normalPlaces.map((place) {
        return _ExploreCard(
          title: place.name,
          location: '${place.city}, ${place.country}',
          category: place.category,
          price: '\$${place.cost.toStringAsFixed(0)}',
          rating: place.rating.toStringAsFixed(1),
          duration: place.type == 'hotel'
              ? 'per night'
              : '${place.durationHours.toStringAsFixed(1)}h',
          icon: _getPlaceIcon(place),
          imageUrl: place.primaryThumbnailUrl ?? place.primaryImageUrl,
          isLuxury: isLuxury,
          isNight: isNight,
          isFavorite: favoriteItemKeys.contains(_itemKeyFromTitle(place.name)),
          onFavorite: () => _toggleExploreFavorite(place),
          onAddToPackage: () => _showAddToPackageSheet(place),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DestinationDetailsScreen(
                  destination: place.name,
                  country: place.country,
                  selectedMode: widget.selectedMode,
                  place: place,
                ),
              ),
            );
          },
        );
      }),
    );

    return cards;
  }

  IconData _getPlaceIcon(PlaceModel place) {
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

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final bool isVisible;
  final VoidCallback onClear;

  const _ActiveFilterChip({
    required this.label,
    required this.isVisible,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filter: $label',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF1D4ED8),
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

class _ExploreErrorBanner extends StatelessWidget {
  final String message;

  const _ExploreErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_outlined,
            color: Color(0xFFEA580C),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final Color accentColor;

  const _ExploreImagePlaceholder({
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -18,
          bottom: -18,
          child: Icon(
            icon,
            size: 95,
            color: accentColor.withValues(alpha: 0.12),
          ),
        ),
        Center(child: Icon(icon, size: 50, color: accentColor)),
      ],
    );
  }
}

class _SearchSuggestionsDropdown extends StatelessWidget {
  final List<TravelItemSuggestion> suggestions;
  final bool isLoading;
  final Color accentColor;
  final Color borderColor;
  final bool isLuxury;
  final ValueChanged<TravelItemSuggestion> onSuggestionTap;

  const _SearchSuggestionsDropdown({
    required this.suggestions,
    required this.isLoading,
    required this.accentColor,
    required this.borderColor,
    required this.isLuxury,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isLuxury ? const Color(0xFF0B1020) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Searching...',
                    style: TextStyle(
                      color: isLuxury
                          ? const Color(0xFFB8B8B8)
                          : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ...suggestions.take(5).map((suggestion) {
            return InkWell(
              onTap: () => onSuggestionTap(suggestion),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconForSuggestion(suggestion),
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLuxury
                                  ? const Color(0xFFFFF8E1)
                                  : const Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitleForSuggestion(suggestion),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLuxury
                                  ? const Color(0xFFB8B8B8)
                                  : const Color(0xFF6B7280),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconForSuggestion(TravelItemSuggestion suggestion) {
    if (suggestion.kind == 'country') return Icons.public;
    if (suggestion.kind == 'city') return Icons.location_city_outlined;
    if (suggestion.type == 'hotel') return Icons.hotel_outlined;
    if (suggestion.type == 'restaurant') return Icons.restaurant_outlined;
    if (suggestion.type == 'nightlife') return Icons.nightlife_outlined;
    return Icons.map_outlined;
  }

  String _subtitleForSuggestion(TravelItemSuggestion suggestion) {
    if (suggestion.kind == 'country') {
      return 'Country';
    }
    if (suggestion.kind == 'city') {
      return suggestion.country == null
          ? 'City'
          : 'City • ${suggestion.country}';
    }

    final parts = <String>[
      _formatKind(suggestion.type ?? suggestion.kind),
      if (suggestion.city != null && suggestion.country != null)
        '${suggestion.city}, ${suggestion.country}'
      else if (suggestion.city != null)
        suggestion.city!
      else if (suggestion.country != null)
        suggestion.country!,
    ];
    return parts.join(' • ');
  }

  String _formatKind(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _ExploreCard extends StatelessWidget {
  final String title;
  final String location;
  final String category;
  final String price;
  final String rating;
  final String duration;
  final IconData icon;
  final String? imageUrl;
  final bool isLuxury;
  final bool isNight;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToPackage;
  final VoidCallback? onTap;

  const _ExploreCard({
    required this.title,
    required this.location,
    required this.category,
    required this.price,
    required this.rating,
    required this.duration,
    required this.icon,
    this.imageUrl,
    required this.isLuxury,
    required this.isNight,
    required this.isFavorite,
    this.onFavorite,
    this.onAddToPackage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isLuxury
        ? const Color(0xFF0B1020)
        : isNight
            ? const Color(0xFF111827)
            : Colors.white;

    final imageBoxColor = isLuxury
        ? const Color(0xFF111827)
        : isNight
            ? const Color(0xFF1E1B4B)
            : const Color(0xFFE0F2FE);

    final accentColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : const Color(0xFF2563EB);

    final chipBackgroundColor = isLuxury
        ? const Color(0xFFE8C766).withValues(alpha: 0.14)
        : isNight
            ? const Color(0xFFA855F7).withValues(alpha: 0.16)
            : const Color(0xFFEFF6FF);

    final chipBorderColor = isLuxury
        ? const Color(0xFFE8C766).withValues(alpha: 0.45)
        : isNight
            ? const Color(0xFFA855F7).withValues(alpha: 0.45)
            : const Color(0xFFBFDBFE);

    final primaryTextColor =
        isLuxury || isNight ? Colors.white : const Color(0xFF111827);

    final secondaryTextColor = isLuxury
        ? const Color(0xFFB8B8B8)
        : isNight
            ? const Color(0xFFB8B8D1)
            : const Color(0xFF9CA3AF);

    final priceColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFEC4899)
            : const Color(0xFF16A34A);

    return SizedBox(
      height: 134,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isLuxury
                      ? const Color(0xFFE8C766).withValues(alpha: 0.35)
                      : isNight
                          ? const Color(0xFFA855F7).withValues(alpha: 0.35)
                          : const Color(0xFFE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isLuxury || isNight ? 0.35 : 0.05,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onTap,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 128,
                        height: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(22),
                          ),
                          child: Container(
                            color: imageBoxColor,
                            child: imageUrl == null || imageUrl!.isEmpty
                                ? _ExploreImagePlaceholder(
                                    icon: icon,
                                    accentColor: accentColor,
                                  )
                                : Image.network(
                                    imageUrl!,
                                    width: 128,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return _ExploreImagePlaceholder(
                                        icon: icon,
                                        accentColor: accentColor,
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chipBackgroundColor,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: chipBorderColor),
                                  ),
                                  child: Text(
                                    category.isEmpty ? 'place' : category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: secondaryTextColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 13,
                                    color: secondaryTextColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    duration,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    price,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: priceColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.star,
                                    size: 15,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w800,
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
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ExploreCardActionButton(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xFFEF4444) : accentColor,
                  tooltip: 'Favorite',
                  onTap: onFavorite,
                ),
                const SizedBox(height: 10),
                _ExploreCardActionButton(
                  icon: Icons.add_box_outlined,
                  color: accentColor,
                  tooltip: 'Add to My Package',
                  onTap: onAddToPackage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreCardActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ExploreCardActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final bool isLuxury;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.isLuxury,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: isLuxury ? const Color(0xFFFFF8E1) : const Color(0xFF111827),
          ),
        ),
        const Spacer(),
        Text(
          actionText,
          style: TextStyle(
            color: isLuxury ? const Color(0xFFE8C766) : const Color(0xFF2563EB),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PopularDestinationCard extends StatelessWidget {
  final String country;
  final String cityOne;
  final String cityTwo;
  final String cityThree;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;

  const _PopularDestinationCard({
    required this.country,
    required this.cityOne,
    required this.cityTwo,
    required this.cityThree,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 185,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.public,
                size: 120,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '$icon  $country',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    country,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _CityPill(text: cityOne),
                      _CityPill(text: cityTwo),
                      _CityPill(text: cityThree),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 13,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Culture',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.restaurant_outlined,
                        size: 13,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Food',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityPill extends StatelessWidget {
  final String text;

  const _CityPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
