import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_package_model.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _daysController = TextEditingController(text: '2');
  final _interestsController = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _suggestionDebounce;

  String _mode = 'Casual';
  String _travelers = 'Solo';
  String _typeFilter = 'activity';
  String? _selectedCountry;
  String? _selectedCity;
  bool _isLoadingCountries = false;
  bool _isLoadingCities = false;
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<String> _countries = [];
  List<String> _cities = [];
  List<PlaceModel> _suggestions = [];
  List<PlaceModel> _results = [];
  PlaceModel? _hotel;
  final List<PlaceModel> _activities = [];
  final List<PlaceModel> _restaurants = [];
  final List<PlaceModel> _nightlife = [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _titleController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _daysController.dispose();
    _interestsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _selectedCount {
    return (_hotel == null ? 0 : 1) +
        _activities.length +
        _restaurants.length +
        _nightlife.length;
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _errorMessage = null;
    });

    try {
      final countries = await _apiService.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiService.cleanErrorMessage(error);
        _isLoadingCountries = false;
      });
    }
  }

  Future<void> _loadCities(String country) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCity = null;
      _cityController.clear();
      _errorMessage = null;
    });

    try {
      final cities = await _apiService.getCities(country);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiService.cleanErrorMessage(error);
        _isLoadingCities = false;
      });
    }
  }

  void _clearSelectedItems({bool showMessage = true}) {
    if (_selectedCount == 0) return;

    setState(() {
      _hotel = null;
      _activities.clear();
      _restaurants.clear();
      _nightlife.clear();
      _suggestions = [];
      _results = [];
    });

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected items were cleared because city changed.'),
        ),
      );
    }
  }

  void _selectCountry(String? country) {
    if (country == null || country == _selectedCountry) return;

    _clearSelectedItems();
    setState(() {
      _selectedCountry = country;
      _countryController.text = country;
      _selectedCity = null;
      _cityController.clear();
      _results = [];
      _suggestions = [];
    });
    _loadCities(country);
  }

  void _selectCity(String? city) {
    if (city == null || city == _selectedCity) return;

    _clearSelectedItems();
    setState(() {
      _selectedCity = city;
      _cityController.text = city;
      _results = [];
      _suggestions = [];
    });
  }

  bool _hasSelectedDestination() {
    return (_selectedCountry ?? '').trim().isNotEmpty &&
        (_selectedCity ?? '').trim().isNotEmpty;
  }

  Future<void> _searchItems() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    if (!_hasSelectedDestination()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a country and city first.'),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.searchTravelItems(
        query: query,
        country: _selectedCountry,
        city: _selectedCity,
        type: _typeFilter,
        includeImages: true,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _suggestions = [];
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiService.cleanErrorMessage(error);
        _isSearching = false;
      });
    }
  }

  void _onSearchTextChanged(String value) {
    _suggestionDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    if (!_hasSelectedDestination()) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
        _errorMessage = 'Please select a country and city first.';
      });
      return;
    }

    _suggestionDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadSearchSuggestions(query),
    );
  }

  Future<void> _loadSearchSuggestions(String query) async {
    setState(() {
      _isLoadingSuggestions = true;
      _errorMessage = null;
    });

    try {
      final suggestions = await _apiService.searchTravelItems(
        query: query,
        country: _selectedCountry,
        city: _selectedCity,
        type: _typeFilter,
        includeImages: true,
        limit: 5,
      );

      if (!mounted || _searchController.text.trim() != query) return;

      setState(() {
        _suggestions = suggestions
            .where((item) => !_isSelectedItem(item))
            .toList(growable: false);
        _isLoadingSuggestions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
        _errorMessage = ApiService.cleanErrorMessage(error);
      });
    }
  }

  void _addItem(PlaceModel item) {
    final itemCountry = item.country.trim();
    final itemCity = item.city.trim();
    final enteredCountry = (_selectedCountry ?? '').trim();
    final enteredCity = (_selectedCity ?? '').trim();

    if (enteredCountry.toLowerCase() != itemCountry.toLowerCase() ||
        enteredCity.toLowerCase() != itemCity.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All package items must be from the same city.'),
        ),
      );
      return;
    }

    bool alreadySelected(List<PlaceModel> items) {
      return items.any((selected) => selected.id == item.id);
    }

    setState(() {
      switch (item.type.toLowerCase()) {
        case 'hotel':
          _hotel = item;
          break;
        case 'restaurant':
          if (!alreadySelected(_restaurants)) _restaurants.add(item);
          break;
        case 'nightlife':
          if (_mode == 'Night' && !alreadySelected(_nightlife)) {
            _nightlife.add(item);
          }
          break;
        default:
          if (!alreadySelected(_activities)) _activities.add(item);
      }
      _suggestions = [];
    });
  }

  bool _isSelectedItem(PlaceModel item) {
    bool matches(PlaceModel selected) {
      if (selected.id != null && item.id != null) {
        return selected.id == item.id;
      }
      return selected.name.toLowerCase() == item.name.toLowerCase() &&
          selected.type.toLowerCase() == item.type.toLowerCase();
    }

    return (_hotel != null && matches(_hotel!)) ||
        _activities.any(matches) ||
        _restaurants.any(matches) ||
        _nightlife.any(matches);
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final interests = _interestsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    try {
      final package = await _apiService.createManualPackage({
        'title': _titleController.text.trim(),
        'country': _selectedCountry,
        'city': _selectedCity,
        'mode': _mode,
        'days': int.tryParse(_daysController.text.trim()) ?? 1,
        'travelers': _travelers,
        'interests': interests,
        'hotel_id': _hotel?.id,
        'activity_ids': _activities.map((item) => item.id).whereType<String>().toList(),
        'restaurant_ids':
            _restaurants.map((item) => item.id).whereType<String>().toList(),
        'nightlife_ids': _mode == 'Night'
            ? _nightlife.map((item) => item.id).whereType<String>().toList()
            : <String>[],
      });

      if (!mounted) return;
      Navigator.pop<AiPackageModel>(context, package);
    } catch (error) {
      if (!mounted) return;
      final message = _createPackageErrorMessage(error);
      setState(() {
        _errorMessage = message;
        _isSaving = false;
      });
    }
  }

  String _createPackageErrorMessage(Object error) {
    final message = ApiService.cleanErrorMessage(error);
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('log in')) {
      return 'Please log in to create a package.';
    }
    if (lowerMessage.contains('connect') || lowerMessage.contains('failed to fetch')) {
      return 'Cannot connect to server. Please make sure backend is running.';
    }
    if (lowerMessage.contains('select at least one item')) {
      return 'Please select at least one item.';
    }
    if (lowerMessage.contains('same city')) {
      return 'All package items must be from the same city.';
    }
    return 'Could not create package. Please try again.';
  }

  Future<void> _showFavoriteItems() async {
    if (!_hasSelectedDestination()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a country and city first.'),
        ),
      );
      return;
    }

    try {
      final favorites = await _apiService.getFavorites();
      final favoriteItems = favorites
          .map(_favoriteToPlace)
          .whereType<PlaceModel>()
          .toList(growable: false);

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorites in $_selectedCity, $_selectedCountry',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (favoriteItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'No favorites found for this city.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: favoriteItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = favoriteItems[index];
                          return _FavoriteItemTile(
                            item: item,
                            onAdd: () async {
                              final added = await _addFavoritePlace(item);
                              if (added && mounted) {
                                Navigator.pop(context);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      final message = ApiService.cleanErrorMessage(error) == 'Please log in first.'
          ? 'Please log in to use favorites.'
          : ApiService.cleanErrorMessage(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<bool> _addFavoritePlace(PlaceModel favoriteItem) async {
    try {
      final matches = await _apiService.searchTravelItems(
        query: favoriteItem.name,
        country: _selectedCountry,
        city: _selectedCity,
        type: favoriteItem.type,
        includeImages: true,
        limit: 5,
      );
      final resolvedItem = matches.cast<PlaceModel?>().firstWhere(
            (item) =>
                item?.name.toLowerCase() == favoriteItem.name.toLowerCase(),
            orElse: () => matches.isEmpty ? null : matches.first,
          );

      if (resolvedItem == null) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorite item could not be matched in this city.'),
          ),
        );
        return false;
      }

      _addItem(resolvedItem);
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
      return false;
    }
  }

  PlaceModel? _favoriteToPlace(Map<String, dynamic> favorite) {
    final type = _inferFavoriteType(favorite);
    if (type == null || type != _typeFilter) return null;

    final country = _readFavoriteString(favorite, 'country');
    final city = _readFavoriteString(favorite, 'city');
    final location = _readFavoriteString(favorite, 'location');
    final selectedCountry = (_selectedCountry ?? '').toLowerCase();
    final selectedCity = (_selectedCity ?? '').toLowerCase();
    final favoriteCountry = country.toLowerCase();
    final favoriteCity = city.toLowerCase();
    final favoriteLocation = location.toLowerCase();
    final matchesExplicitLocation =
        favoriteCountry == selectedCountry && favoriteCity == selectedCity;
    final matchesLocationText =
        favoriteLocation.contains(selectedCountry) &&
            favoriteLocation.contains(selectedCity);

    if (!matchesExplicitLocation && !matchesLocationText) return null;

    final id = _readFavoriteString(favorite, 'target_id').isNotEmpty
        ? _readFavoriteString(favorite, 'target_id')
        : _readFavoriteString(favorite, 'item_key');
    if (id.isEmpty) return null;

    final image = _readFavoriteString(favorite, 'image');
    final tags = _readFavoriteStringList(favorite['tags']);
    final name = _readFavoriteString(favorite, 'title').isNotEmpty
        ? _readFavoriteString(favorite, 'title')
        : _readFavoriteString(favorite, 'name');
    if (name.isEmpty) return null;

    return PlaceModel(
      id: id,
      country: _selectedCountry ?? country,
      city: _selectedCity ?? city,
      type: type,
      name: name,
      category: tags.isEmpty ? type : tags.first,
      cost: _readFavoriteNumber(favorite['price']),
      currency: 'USD',
      durationHours: _readDurationHours(favorite['duration']),
      rating: _readFavoriteNumber(favorite['rating']),
      interestTags: tags,
      images: image.isEmpty ? const [] : [PlaceImage(url: image)],
    );
  }

  String? _inferFavoriteType(Map<String, dynamic> favorite) {
    final rawItemType = _readFavoriteString(favorite, 'item_type').toLowerCase();
    final targetType = _readFavoriteString(favorite, 'target_type').toLowerCase();
    final sourceCollection =
        _readFavoriteString(favorite, 'source_collection').toLowerCase();

    if (targetType == 'ai_package' ||
        sourceCollection == 'ai_packages' ||
        rawItemType == 'package') {
      return null;
    }

    if (rawItemType == 'hotel' ||
        rawItemType == 'activity' ||
        rawItemType == 'restaurant' ||
        rawItemType == 'nightlife') {
      return rawItemType;
    }

    final searchableText = [
      rawItemType,
      targetType,
      sourceCollection,
      _readFavoriteString(favorite, 'title'),
      _readFavoriteString(favorite, 'name'),
      _readFavoriteStringList(favorite['tags']).join(' '),
    ].join(' ').toLowerCase();

    return _normalizeType(searchableText);
  }

  String? _normalizeType(String value) {
    final text = value.toLowerCase();
    if (text.contains('hotel')) return 'hotel';
    if (text.contains('restaurant') || text.contains('food')) return 'restaurant';
    if (text.contains('nightlife') ||
        text.contains('club') ||
        text.contains('bar')) {
      return 'nightlife';
    }
    if (text.contains('activity')) {
      return 'activity';
    }
    return null;
  }

  String _readFavoriteString(Map<String, dynamic> favorite, String key) {
    final value = favorite[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  List<String> _readFavoriteStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  double _readFavoriteNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0;
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(value.toString());
    return double.tryParse(match?.group(0) ?? '') ?? 0;
  }

  double _readDurationHours(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('night')) return 24;
    return _readFavoriteNumber(value);
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF2563EB);
    const textColor = Color(0xFF111827);
    const mutedColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create Package'),
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section(
                  title: 'Package info',
                  child: Column(
                    children: [
                      _TextInput(
                        controller: _titleController,
                        label: 'Title',
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NullableDropdownInput(
                              label: 'Country',
                              value: _selectedCountry,
                              items: _countries,
                              isLoading: _isLoadingCountries,
                              onChanged: _selectCountry,
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _NullableDropdownInput(
                              label: 'City',
                              value: _selectedCity,
                              items: _cities,
                              isLoading: _isLoadingCities,
                              onChanged: _selectCity,
                              validator: _required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DropdownInput(
                              label: 'Mode',
                              value: _mode,
                              items: const ['Casual', 'Luxury', 'Night'],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _mode = value;
                                  if (_mode != 'Night') {
                                    _nightlife.clear();
                                    if (_typeFilter == 'nightlife') {
                                      _typeFilter = 'activity';
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TextInput(
                              controller: _daysController,
                              label: 'Days',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final days = int.tryParse(value?.trim() ?? '');
                                if (days == null || days < 1) return 'Enter days';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DropdownInput(
                        label: 'Travelers',
                        value: _travelers,
                        items: const ['Solo', 'Couple', 'Friends', 'Family'],
                        onChanged: (value) {
                          if (value != null) setState(() => _travelers = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _TextInput(
                        controller: _interestsController,
                        label: 'Interests',
                        hintText: 'food, culture, museums',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Search items',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TextInput(
                              controller: _searchController,
                              label: 'Search',
                              onChanged: _onSearchTextChanged,
                              onSubmitted: (_) => _searchItems(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _showFavoriteItems,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDB2777),
                                side: const BorderSide(
                                  color: Color(0xFFFBCFE8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Icon(Icons.favorite_border, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSearching ? null : _searchItems,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSearching
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.search, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TypeChip(
                            label: 'Hotel',
                            value: 'hotel',
                            selectedValue: _typeFilter,
                            onSelected: _setTypeFilter,
                          ),
                          _TypeChip(
                            label: 'Activity',
                            value: 'activity',
                            selectedValue: _typeFilter,
                            onSelected: _setTypeFilter,
                          ),
                          _TypeChip(
                            label: 'Restaurant',
                            value: 'restaurant',
                            selectedValue: _typeFilter,
                            onSelected: _setTypeFilter,
                          ),
                          if (_mode == 'Night')
                            _TypeChip(
                              label: 'Nightlife',
                              value: 'nightlife',
                              selectedValue: _typeFilter,
                              onSelected: _setTypeFilter,
                            ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_isLoadingSuggestions)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      else if (_suggestions.isNotEmpty)
                        Column(
                          children: _suggestions.map((item) {
                            return _SuggestionItemTile(
                              item: item,
                              onAdd: () => _addItem(item),
                            );
                          }).toList(growable: false),
                        ),
                      if (_suggestions.isNotEmpty) const SizedBox(height: 8),
                      ..._results.map(
                        (item) => _PlaceResultTile(
                          item: item,
                          onAdd: () => _addItem(item),
                        ),
                      ),
                      if (_results.isEmpty && !_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Search by place name to add package items.',
                            style: TextStyle(color: mutedColor),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Selected items',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectedGroup(
                        title: 'Hotel',
                        items: _hotel == null ? const [] : [_hotel!],
                        onRemove: (_) => setState(() => _hotel = null),
                      ),
                      _SelectedGroup(
                        title: 'Activities',
                        items: _activities,
                        onRemove: (item) => setState(() => _activities.remove(item)),
                      ),
                      _SelectedGroup(
                        title: 'Restaurants',
                        items: _restaurants,
                        onRemove: (item) => setState(() => _restaurants.remove(item)),
                      ),
                      if (_mode == 'Night')
                        _SelectedGroup(
                          title: 'Nightlife',
                          items: _nightlife,
                          onRemove: (item) => setState(() => _nightlife.remove(item)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePackage,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Save Package'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setTypeFilter(String value) {
    setState(() {
      _typeFilter = value;
      _suggestions = [];
      _results = [];
    });

    final query = _searchController.text.trim();
    if (query.length >= 2 && _hasSelectedDestination()) {
      _loadSearchSuggestions(query);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _TextInput({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}

class _NullableDropdownInput extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final bool isLoading;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _NullableDropdownInput({
    required this.label,
    required this.value,
    required this.items,
    required this.isLoading,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && items.contains(value);

    return DropdownButtonFormField<String>(
      value: hasValue ? value : null,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: isLoading || items.isEmpty ? null : onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: isLoading ? 'Loading $label...' : label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}

class _DropdownInput extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownInput({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _TypeChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: const Color(0xFFDBEAFE),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PlaceResultTile extends StatelessWidget {
  final PlaceModel item;
  final VoidCallback onAdd;

  const _PlaceResultTile({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text('${item.type} - ${item.city}, ${item.country}'),
      trailing: IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
        tooltip: 'Add',
      ),
    );
  }
}

class _SuggestionItemTile extends StatelessWidget {
  final PlaceModel item;
  final VoidCallback onAdd;

  const _SuggestionItemTile({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final details = [
      item.category.isEmpty ? item.type : item.category,
      item.priceLabel,
      if (item.rating > 0) 'Rating ${item.rating.toStringAsFixed(1)}',
    ].join(' - ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(details),
        trailing: TextButton(
          onPressed: onAdd,
          child: const Text('Add'),
        ),
      ),
    );
  }
}

class _FavoriteItemTile extends StatelessWidget {
  final PlaceModel item;
  final VoidCallback onAdd;

  const _FavoriteItemTile({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.primaryThumbnailUrl;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: const Color(0xFFEFF6FF),
          child: imageUrl == null
              ? const Icon(Icons.place_outlined, color: Color(0xFF2563EB))
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text('${item.locationLabel} - ${item.type}'),
      trailing: TextButton(
        onPressed: onAdd,
        child: const Text('Add'),
      ),
    );
  }
}

class _SelectedGroup extends StatelessWidget {
  final String title;
  final List<PlaceModel> items;
  final ValueChanged<PlaceModel> onRemove;

  const _SelectedGroup({
    required this.title,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Text(
              'None selected',
              style: TextStyle(color: Color(0xFF94A3B8)),
            )
          else
            ...items.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text(item.priceLabel),
                trailing: IconButton(
                  onPressed: () => onRemove(item),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
