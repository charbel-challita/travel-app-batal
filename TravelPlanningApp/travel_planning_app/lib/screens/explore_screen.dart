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
  String selectedType = 'Activities';
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

  final List<String> types = ['Activities', 'Hotels', 'Restaurants'];

  @override
  void initState() {
    super.initState();
    if (_isNormalMode(widget.selectedMode)) {
      _loadNormalPlaces();
    }
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isNormalMode(oldWidget.selectedMode) &&
        _isNormalMode(widget.selectedMode)) {
      _loadNormalPlaces();
    } else if (_isNormalMode(oldWidget.selectedMode) &&
        !_isNormalMode(widget.selectedMode)) {
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
        type: selectedTypeFilter,
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
        normalPlaces = _samplePlacesForSelectedFilter();
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
        type: selectedTypeFilter,
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
        normalPlaces = _samplePlacesForSelectedFilter();
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
          type: selectedTypeFilter,
          includeImages: true,
          limit: 20,
        );
      } else if (suggestion.kind == 'country') {
        places = await _apiService.getTravelItems(
          country: suggestion.value,
          type: selectedTypeFilter,
          includeImages: true,
          limit: 20,
        );
      } else {
        places = await _apiService.searchTravelItems(
          query: suggestion.value,
          type: selectedTypeFilter,
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
        normalPlaces = _samplePlacesForSelectedFilter();
        placesError = error.toString();
        isLoadingPlaces = false;
      });
    }
  }

  void _handleTypeSelected(String type) {
    setState(() {
      selectedType = type;
    });

    if (!_isNormalMode(widget.selectedMode)) {
      return;
    }

    _suggestionsDebounce?.cancel();
    _suggestionsRequestId++;
    searchController.clear();
    setState(() {
      searchText = '';
      searchSuggestions = [];
      isLoadingSuggestions = false;
    });
    _loadNormalPlaces();
  }

  void _handleSearchChanged(String value) {
    setState(() {
      searchText = value;
    });

    if (!_isNormalMode(widget.selectedMode)) {
      return;
    }

    final query = value.trim();
    _suggestionsDebounce?.cancel();

    if (query.length < 2) {
      _suggestionsRequestId++;
      _clearSuggestions();
      return;
    }

    _suggestionsDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadSuggestions(query);
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
        type: selectedTypeFilter,
        limit: 5,
      );

      if (!mounted || requestId != _suggestionsRequestId) return;
      if (searchController.text.trim() != query) return;
      if (!_isNormalMode(widget.selectedMode)) return;

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

    if (_isNormalMode(widget.selectedMode)) {
      _loadNormalPlaces();
    }
  }

  void _handleSearchSubmitted(String value) {
    if (!_isNormalMode(widget.selectedMode)) {
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

  bool _isNormalMode(String mode) {
    return mode != 'Luxury' && mode != 'Night';
  }

  List<PlaceModel> _samplePlacesForSelectedFilter() {
    final type = selectedTypeFilter;
    if (type == null) {
      return SampleData.places;
    }
    return SampleData.places.where((place) => place.type == type).toList();
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
                        ? searchText.isEmpty
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

              if (!isLuxury && !isNight)
                _SearchSuggestionsDropdown(
                  suggestions: searchSuggestions,
                  isLoading: isLoadingSuggestions,
                  accentColor: accentColor,
                  borderColor: borderColor,
                  onSuggestionTap: _loadPlacesForSuggestion,
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

                ..._getNightCards(),
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
                    children: types.map((type) {
                      final isSelected = selectedType == type;

                      return GestureDetector(
                        onTap: () => _handleTypeSelected(type),
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
                                _getTypeIcon(type),
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF111827)
                                    : secondaryTextColor,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                type,
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
                  selectedType == 'Activities'
                      ? 'Exclusive activities'
                      : selectedType == 'Hotels'
                      ? 'Luxury hotels'
                      : 'Fine dining',
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

  IconData _getTypeIcon(String type) {
    if (type == 'Hotels') return Icons.hotel_outlined;
    if (type == 'Restaurants') return Icons.restaurant_outlined;
    return Icons.map_outlined;
  }

  List<Widget> _getTypeCards({required bool isLuxury, required bool isNight}) {
    final query = searchText.trim().toLowerCase();

    if (isNight) {
      final nightPlaces = _getNightPlaces();

      final filteredNightPlaces = nightPlaces.where((place) {
        final matchesType = selectedType == 'Activities'
            ? place['type'] == 'activity'
            : selectedType == 'Hotels'
            ? place['type'] == 'hotel'
            : place['type'] == 'restaurant';

        final searchableText = [
          place['title'],
          place['location'],
          place['category'],
          place['type'],
        ].join(' ').toLowerCase();

        final matchesSearch = query.isEmpty || searchableText.contains(query);

        return matchesType && matchesSearch;
      }).toList();

      if (filteredNightPlaces.isEmpty) {
        return const [
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'No nightlife results found.',
                style: TextStyle(
                  color: Color(0xFFB8B8D1),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ];
      }

      return filteredNightPlaces.map((place) {
        return _ExploreCard(
          title: place['title'] as String,
          location: place['location'] as String,
          category: place['category'] as String,
          price: place['price'] as String,
          rating: place['rating'] as String,
          duration: place['duration'] as String,
          icon: place['icon'] as IconData,
          isLuxury: false,
          isNight: true,
        );
      }).toList();
    }

    if (isLuxury) {
      final luxuryPlaces = _getLuxuryPlaces();

      final filteredLuxuryPlaces = luxuryPlaces.where((place) {
        final matchesType = selectedType == 'Activities'
            ? place['type'] == 'activity'
            : selectedType == 'Hotels'
            ? place['type'] == 'hotel'
            : place['type'] == 'restaurant';

        final searchableText = [
          place['title'],
          place['location'],
          place['category'],
          place['type'],
        ].join(' ').toLowerCase();

        final matchesSearch = query.isEmpty || searchableText.contains(query);

        return matchesType && matchesSearch;
      }).toList();

      if (filteredLuxuryPlaces.isEmpty) {
        return const [
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'No premium results found.',
                style: TextStyle(
                  color: Color(0xFFB8B8B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ];
      }

      return filteredLuxuryPlaces.map((place) {
        return _ExploreCard(
          title: place['title'] as String,
          location: place['location'] as String,
          category: place['category'] as String,
          price: place['price'] as String,
          rating: place['rating'] as String,
          duration: place['duration'] as String,
          icon: place['icon'] as IconData,
          isLuxury: true,
          isNight: false,
        );
      }).toList();
    }

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
          message: 'Could not load live places. Showing saved places instead.',
        ),
    ];

    if (normalPlaces.isEmpty) {
      cards.add(
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(
            child: Text(
              'No results found.',
              style: TextStyle(
                color: Color(0xFF6B7280),
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
          isLuxury: false,
          isNight: false,
        );
      }),
    );

    return cards;
  }

  List<Widget> _getNightCards() {
    final query = searchText.trim().toLowerCase();

    final nightPlaces = _getNightPlaces();

    final filteredNightPlaces = nightPlaces.where((place) {
      final searchableText = [
        place['title'],
        place['location'],
        place['category'],
      ].join(' ').toLowerCase();

      return query.isEmpty || searchableText.contains(query);
    }).toList();

    if (filteredNightPlaces.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(
            child: Text(
              'No nightlife results found.',
              style: TextStyle(
                color: Color(0xFFB8B8D1),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ];
    }

    return filteredNightPlaces.map((place) {
      return _ExploreCard(
        title: place['title'] as String,
        location: place['location'] as String,
        category: place['category'] as String,
        price: place['price'] as String,
        rating: place['rating'] as String,
        duration: place['duration'] as String,
        icon: place['icon'] as IconData,
        isLuxury: false,
        isNight: true,
      );
    }).toList();
  }

  List<Map<String, Object>> _getLuxuryPlaces() {
    return [
      {
        'type': 'activity',
        'title': 'Private Scenic Flight',
        'location': 'Swiss Alps, Switzerland',
        'category': 'Private tour',
        'price': '\$1450',
        'rating': '4.9',
        'duration': '6h',
        'icon': Icons.flight_takeoff,
      },
      {
        'type': 'activity',
        'title': 'Luxury Yacht Escape',
        'location': 'Santorini, Greece',
        'category': 'Yacht experience',
        'price': '\$1800',
        'rating': '4.9',
        'duration': '1 day',
        'icon': Icons.sailing_outlined,
      },
      {
        'type': 'activity',
        'title': 'Helicopter City Tour',
        'location': 'Dubai, UAE',
        'category': 'VIP adventure',
        'price': '\$980',
        'rating': '4.8',
        'duration': '3h',
        'icon': Icons.airplanemode_active,
      },
      {
        'type': 'hotel',
        'title': 'Royal Marina Suite',
        'location': 'Dubai, UAE',
        'category': '5-star luxury hotel',
        'price': '\$620',
        'rating': '4.9',
        'duration': 'per night',
        'icon': Icons.hotel_outlined,
      },
      {
        'type': 'hotel',
        'title': 'Private Island Villa',
        'location': 'Maldives',
        'category': 'Private villa',
        'price': '\$1250',
        'rating': '5.0',
        'duration': 'per night',
        'icon': Icons.villa_outlined,
      },
      {
        'type': 'hotel',
        'title': 'Alpine Palace Resort',
        'location': 'Bavaria, Germany',
        'category': 'Mountain resort',
        'price': '\$780',
        'rating': '4.9',
        'duration': 'per night',
        'icon': Icons.apartment_outlined,
      },
      {
        'type': 'restaurant',
        'title': 'Skyline Fine Dining',
        'location': 'Dubai, UAE',
        'category': 'Fine dining',
        'price': '\$240',
        'rating': '4.8',
        'duration': '2h',
        'icon': Icons.dinner_dining_outlined,
      },
      {
        'type': 'restaurant',
        'title': 'Private Chef Table',
        'location': 'Paris, France',
        'category': 'Chef experience',
        'price': '\$360',
        'rating': '4.9',
        'duration': '3h',
        'icon': Icons.restaurant_menu,
      },
      {
        'type': 'restaurant',
        'title': 'Michelin Tasting Night',
        'location': 'Tokyo, Japan',
        'category': 'Luxury dining',
        'price': '\$420',
        'rating': '5.0',
        'duration': '2.5h',
        'icon': Icons.local_dining_outlined,
      },
    ];
  }

  List<Map<String, Object>> _getNightPlaces() {
    return [
      {
        'title': 'Just Cavalli Club',
        'location': 'Dubai, UAE',
        'category': 'Nightclub',
        'price': '\$\$\$',
        'rating': '4.8',
        'duration': '4.5h',
        'icon': Icons.nightlife,
      },
      {
        'title': 'Marseille Red Club',
        'location': 'Marseille, France',
        'category': 'Club',
        'price': '\$\$',
        'rating': '4.6',
        'duration': '5h',
        'icon': Icons.music_note,
      },
      {
        'title': 'Club Ibiza Nightclub',
        'location': 'Ibiza, Spain',
        'category': 'Nightclub',
        'price': '\$\$\$',
        'rating': '4.7',
        'duration': '4h',
        'icon': Icons.nightlife_outlined,
      },
      {
        'title': 'Skyline Rooftop Lounge',
        'location': 'Dubai, UAE',
        'category': 'Rooftop',
        'price': '\$\$\$',
        'rating': '4.8',
        'duration': '3h',
        'icon': Icons.roofing_outlined,
      },
      {
        'title': 'Moonlight Bar',
        'location': 'Bangkok, Thailand',
        'category': 'Bar',
        'price': '\$\$',
        'rating': '4.7',
        'duration': '2h',
        'icon': Icons.local_bar,
      },
      {
        'title': 'Neon Live Music Lounge',
        'location': 'Tokyo, Japan',
        'category': 'Live music',
        'price': '\$\$',
        'rating': '4.8',
        'duration': '3h',
        'icon': Icons.graphic_eq,
      },
      {
        'title': 'Salento Dance Club',
        'location': 'Salento, Italy',
        'category': 'Dance club',
        'price': '\$\$',
        'rating': '4.5',
        'duration': '4.5h',
        'icon': Icons.album_outlined,
      },
    ];
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
  final ValueChanged<TravelItemSuggestion> onSuggestionTap;

  const _SearchSuggestionsDropdown({
    required this.suggestions,
    required this.isLoading,
    required this.accentColor,
    required this.borderColor,
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
        color: Colors.white,
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
                  const Text(
                    'Searching...',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
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
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitleForSuggestion(suggestion),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
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
    final primaryTextColor = isLuxury || isNight
        ? Colors.white
        : const Color(0xFF111827);
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

    return Container(
      height: 148,
      margin: const EdgeInsets.only(bottom: 14),
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
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 118,
            decoration: BoxDecoration(
              color: imageBoxColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(22),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl == null
                ? _ExploreImagePlaceholder(icon: icon, accentColor: accentColor)
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _ExploreImagePlaceholder(
                        icon: icon,
                        accentColor: accentColor,
                      );
                    },
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
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
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
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
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 12,
                          color: priceColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
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
