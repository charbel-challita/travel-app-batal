import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_planning_app/models/ai_package_model.dart';
import 'package:travel_planning_app/models/place_model.dart';

class TravelItemSuggestion {
  final String label;
  final String kind;
  final String value;
  final String? city;
  final String? country;
  final String? type;

  const TravelItemSuggestion({
    required this.label,
    required this.kind,
    required this.value,
    this.city,
    this.country,
    this.type,
  });

  factory TravelItemSuggestion.fromJson(Map<String, dynamic> json) {
    String readRequiredString(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw Exception(
          'Invalid travel item suggestion: "$key" is missing or is not a string.',
        );
      }
      return value;
    }

    String? readOptionalString(String key) {
      final value = json[key];
      if (value == null) {
        return null;
      }
      if (value is! String) {
        throw Exception(
          'Invalid travel item suggestion: "$key" is not a string.',
        );
      }
      return value;
    }

    return TravelItemSuggestion(
      label: readRequiredString('label'),
      kind: readRequiredString('kind'),
      value: readRequiredString('value'),
      city: readOptionalString('city'),
      country: readOptionalString('country'),
      type: readOptionalString('type'),
    );
  }
}

class AiPackageSuggestion {
  final String label;
  final String value;
  final String packageId;
  final String city;
  final String country;
  final String mode;

  const AiPackageSuggestion({
    required this.label,
    required this.value,
    required this.packageId,
    required this.city,
    required this.country,
    required this.mode,
  });

  factory AiPackageSuggestion.fromJson(Map<String, dynamic> json) {
    return AiPackageSuggestion(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      packageId: json['package_id']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'Casual',
    );
  }
}

class DestinationSearchIndex {
  final List<String> countries;
  final List<String> cities;

  DestinationSearchIndex({
    required this.countries,
    required this.cities,
  });

  String? matchCountry(String query) {
    return _matchExact(query, countries);
  }

  String? matchCity(String query) {
    return _matchExact(query, cities);
  }

  String? _matchExact(String query, List<String> values) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return null;
    }

    for (final value in values) {
      if (_normalize(value) == normalizedQuery) {
        return value;
      }
    }

    return null;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class _FriendlyApiException implements Exception {
  final String message;

  const _FriendlyApiException(this.message);
}

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String networkErrorMessage =
      'Cannot connect to server. Please try again.';
  static const String unknownErrorMessage =
      'Something went wrong. Please try again.';
  static Future<DestinationSearchIndex>? _destinationSearchIndexFuture;

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders({
    bool includeJson = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Please log in first.');
    }

    return {
      if (includeJson) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<String>> getCountries() async {
    final response = await _client.get(Uri.parse('$baseUrl/destinations/countries'));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load countries. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final decoded = _decodeJsonObject(response.body);
    final countries = decoded['countries'];

    if (countries is! List) {
      throw Exception('Invalid countries response: "countries" is missing.');
    }

    return countries
        .map((country) => country.toString().trim())
        .where((country) => country.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> getCities(String country) async {
    final trimmedCountry = country.trim();
    if (trimmedCountry.isEmpty) {
      return [];
    }

    final uri = Uri.parse('$baseUrl/destinations/cities').replace(
      queryParameters: {'country': trimmedCountry},
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load cities. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final decoded = _decodeJsonObject(response.body);
    final cities = decoded['cities'];

    if (cities is! List) {
      throw Exception('Invalid cities response: "cities" is missing.');
    }

    return cities
        .map((city) => city.toString().trim())
        .where((city) => city.isNotEmpty)
        .toList(growable: false);
  }

  Future<DestinationSearchIndex> getDestinationSearchIndex() {
    final cachedFuture = _destinationSearchIndexFuture;
    if (cachedFuture != null) {
      return cachedFuture;
    }

    final future = _loadDestinationSearchIndex();
    _destinationSearchIndexFuture = future;
    future.catchError((_) {
      if (identical(_destinationSearchIndexFuture, future)) {
        _destinationSearchIndexFuture = null;
      }
      return DestinationSearchIndex(countries: const [], cities: const []);
    });
    return future;
  }

  Future<DestinationSearchIndex> _loadDestinationSearchIndex() async {
    final countries = await getCountries();
    final cityGroups = await Future.wait(
      countries.map((country) async {
        try {
          return await getCities(country);
        } catch (_) {
          return <String>[];
        }
      }),
    );

    final citiesByKey = <String, String>{};
    for (final cityGroup in cityGroups) {
      for (final city in cityGroup) {
        final key = city.trim().toLowerCase();
        if (key.isNotEmpty) {
          citiesByKey.putIfAbsent(key, () => city);
        }
      }
    }

    return DestinationSearchIndex(
      countries: countries,
      cities: citiesByKey.values.toList(growable: false),
    );
  }

  Future<List<PlaceModel>> getTravelItems({
    String? country,
    String? city,
    String? type,
    String? budgetLevel,
    List<String>? interests,
    double? minRating,
    bool? familyFriendly,
    bool? culture,
    bool? romantic,
    bool? adventure,
    bool? nightlife,
    bool includeImages = false,
    int limit = 20,
  }) async {
    final queryParameters = <String, String>{'limit': limit.toString()};

    void addString(String key, String? value) {
      if (value != null) {
        queryParameters[key] = value;
      }
    }

    void addBool(String key, bool? value) {
      if (value != null) {
        queryParameters[key] = value.toString();
      }
    }

    addString('country', country);
    addString('city', city);
    addString('type', type);
    addString('budget_level', budgetLevel);
    addString('interests', interests?.join(','));
    addString('min_rating', minRating?.toString());
    addBool('family_friendly', familyFriendly);
    addBool('culture', culture);
    addBool('romantic', romantic);
    addBool('adventure', adventure);
    addBool('nightlife', nightlife);

    if (includeImages) {
      queryParameters['include_images'] = 'true';
    }

    final uri = Uri.parse(
      '$baseUrl/travel-items',
    ).replace(queryParameters: queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load travel items. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON response from travel items API: $error');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid travel items response: expected a JSON object.');
    }

    final items = decoded['items'];
    if (items is! List) {
      throw Exception(
        'Invalid travel items response: "items" is missing or is not a list.',
      );
    }

    return items
        .map((item) {
          if (item is! Map) {
            throw Exception(
              'Invalid travel items response: item is not a JSON object.',
            );
          }

          return PlaceModel.fromApiJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }

  Future<List<TravelItemSuggestion>> getTravelItemSuggestions({
    required String query,
    String? country,
    String? city,
    String? type,
    String? category,
    String? budgetLevel,
    List<String>? interests,
    bool? familyFriendly,
    bool? culture,
    bool? romantic,
    bool? adventure,
    bool? nightlife,
    int limit = 5,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return [];
    }

    final safeLimit = limit < 1 ? 5 : limit.clamp(1, 5);
    final queryParameters = <String, String>{
      'q': trimmedQuery,
      'limit': safeLimit.toString(),
    };

    void addString(String key, String? value) {
      if (value != null) {
        queryParameters[key] = value;
      }
    }

    void addBool(String key, bool? value) {
      if (value != null) {
        queryParameters[key] = value.toString();
      }
    }

    addString('country', country);
    addString('city', city);
    addString('type', type);
    addString('category', category);
    addString('budget_level', budgetLevel);
    addString('interests', interests?.join(','));
    addBool('family_friendly', familyFriendly);
    addBool('culture', culture);
    addBool('romantic', romantic);
    addBool('adventure', adventure);
    addBool('nightlife', nightlife);

    final uri = Uri.parse(
      '$baseUrl/travel-items/suggestions',
    ).replace(queryParameters: queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load travel item suggestions. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw Exception(
        'Invalid JSON response from travel item suggestions API: $error',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid travel item suggestions response: expected a JSON object.',
      );
    }

    final suggestions = decoded['suggestions'];
    if (suggestions is! List) {
      throw Exception(
        'Invalid travel item suggestions response: "suggestions" is missing or is not a list.',
      );
    }

    return suggestions
        .map((suggestion) {
          if (suggestion is! Map) {
            throw Exception(
              'Invalid travel item suggestions response: suggestion is not a JSON object.',
            );
          }

          return TravelItemSuggestion.fromJson(
            Map<String, dynamic>.from(suggestion),
          );
        })
        .toList(growable: false);
  }

  Future<List<PlaceModel>> searchTravelItems({
    required String query,
    String? country,
    String? city,
    String? type,
    String? category,
    String? budgetLevel,
    List<String>? interests,
    bool? familyFriendly,
    bool? culture,
    bool? romantic,
    bool? adventure,
    bool? nightlife,
    bool includeImages = false,
    int limit = 20,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    final safeLimit = limit.clamp(1, 100);
    final queryParameters = <String, String>{
      'q': trimmedQuery,
      'limit': safeLimit.toString(),
    };

    void addString(String key, String? value) {
      if (value != null) {
        queryParameters[key] = value;
      }
    }

    void addBool(String key, bool? value) {
      if (value != null) {
        queryParameters[key] = value.toString();
      }
    }

    addString('country', country);
    addString('city', city);
    addString('type', type);
    addString('category', category);
    addString('budget_level', budgetLevel);
    addString('interests', interests?.join(','));
    addBool('family_friendly', familyFriendly);
    addBool('culture', culture);
    addBool('romantic', romantic);
    addBool('adventure', adventure);
    addBool('nightlife', nightlife);

    if (includeImages) {
      queryParameters['include_images'] = 'true';
    }

    final uri = Uri.parse(
      '$baseUrl/travel-items/search',
    ).replace(queryParameters: queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search travel items. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw Exception(
        'Invalid JSON response from travel item search API: $error',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid travel item search response: expected a JSON object.',
      );
    }

    final items = decoded['items'];
    if (items is! List) {
      throw Exception(
        'Invalid travel item search response: "items" is missing or is not a list.',
      );
    }

    return items
        .map((item) {
          if (item is! Map) {
            throw Exception(
              'Invalid travel item search response: item is not a JSON object.',
            );
          }

          return PlaceModel.fromApiJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }

  Future<List<AiPackageModel>> getAiPackages({
    String? mode,
    String? query,
    List<String>? interests,
    String? city,
    String? country,
    int limit = 20,
  }) async {
    final safeLimit = limit.clamp(1, 50);

    final queryParameters = <String, String>{
      'limit': safeLimit.toString(),
    };

    if (mode != null && mode.isNotEmpty) {
      queryParameters['mode'] = mode;
    }
    if (query != null && query.trim().isNotEmpty) {
      queryParameters['q'] = query.trim();
    }
    if (interests != null && interests.isNotEmpty) {
      queryParameters['interests'] = interests.join(',');
    }
    if (city != null && city.trim().isNotEmpty) {
      queryParameters['city'] = city.trim();
    }
    if (country != null && country.trim().isNotEmpty) {
      queryParameters['country'] = country.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/ai-packages',
    ).replace(queryParameters: queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load AI packages. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON response from AI packages API: $error');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid AI packages response: expected a JSON object.');
    }

    final items = decoded['items'];
    if (items is! List) {
      throw Exception(
        'Invalid AI packages response: "items" is missing or is not a list.',
      );
    }

    return items
        .map((item) {
          if (item is! Map) {
            throw Exception(
              'Invalid AI packages response: item is not a JSON object.',
            );
          }

          return AiPackageModel.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }

  Future<List<AiPackageSuggestion>> getAiPackageSuggestions({
    String? mode,
    required String query,
    List<String>? interests,
    int limit = 5,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return [];
    }

    final safeLimit = limit < 1 ? 5 : limit.clamp(1, 5);
    final queryParameters = <String, String>{
      'q': trimmedQuery,
      'limit': safeLimit.toString(),
    };

    if (mode != null && mode.isNotEmpty) {
      queryParameters['mode'] = mode;
    }
    if (interests != null && interests.isNotEmpty) {
      queryParameters['interests'] = interests.join(',');
    }

    final uri = Uri.parse(
      '$baseUrl/ai-packages/suggestions',
    ).replace(queryParameters: queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load AI package suggestions. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw Exception(
        'Invalid JSON response from AI package suggestions API: $error',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid AI package suggestions response: expected a JSON object.',
      );
    }

    final suggestions = decoded['suggestions'];
    if (suggestions is! List) {
      throw Exception(
        'Invalid AI package suggestions response: "suggestions" is missing or is not a list.',
      );
    }

    return suggestions
        .map((suggestion) {
          if (suggestion is! Map) {
            throw Exception(
              'Invalid AI package suggestions response: suggestion is not a JSON object.',
            );
          }

          return AiPackageSuggestion.fromJson(
            Map<String, dynamic>.from(suggestion),
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> generateAiPackage({
    required String country,
    required int days,
    required String budgetLevel,
    double? customBudget,
    required String tripStyle,
    required String travelers,
    required List<String> interests,
    required String mode,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/ai-packages/generate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'country': country,
        'days': days,
        'budget_level': budgetLevel,
        'custom_budget': customBudget,
        'trip_style': tripStyle,
        'travelers': travelers,
        'interests': interests,
        'mode': mode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate AI package. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON response from AI package generator: $error');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid AI package generator response: expected a JSON object.',
      );
    }

    return decoded;
  }

  Future<AiPackageModel> createManualPackage(
    Map<String, dynamic> packageData,
  ) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$baseUrl/ai-packages/manual'),
        headers: await _authHeaders(includeJson: true),
        body: jsonEncode(packageData),
      );
    } on http.ClientException {
      throw Exception('Cannot connect to server. Please make sure backend is running.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in to create a package.');
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      final message = _manualPackageErrorMessage(response);
      throw Exception(message);
    }

    return AiPackageModel.fromJson(_decodeJsonObject(response.body));
  }

  static String _manualPackageErrorMessage(http.Response response) {
    try {
      final decoded = _decodeJsonObject(response.body);
      final detail = decoded['detail']?.toString().toLowerCase() ?? '';

      if (detail.contains('select at least one item')) {
        return 'Please select at least one item.';
      }
      if (detail.contains('same city')) {
        return 'All package items must be from the same city.';
      }
    } catch (_) {
      return 'Could not create package. Please try again.';
    }

    return 'Could not create package. Please try again.';
  }

  Future<List<AiPackageModel>> getMyPackages() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/ai-packages/my'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load my packages. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final decoded = _decodeJsonObject(response.body);
    final items = decoded['items'];

    if (items is! List) {
      throw Exception('Invalid my packages response: "items" is missing.');
    }

    return items
        .map((item) => AiPackageModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<void> deleteMyPackage(String packageId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/ai-packages/$packageId'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to delete package. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<AiPackageModel> addItemToManualPackage(
    String packageId,
    Map<String, dynamic> item,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/ai-packages/$packageId/items'),
      headers: await _authHeaders(includeJson: true),
      body: jsonEncode({
        'item_id': item['id'] ?? item['_id'],
        'item_type': item['type'],
        'item': item,
      }),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200) {
      final message = _manualPackageErrorMessage(response);
      throw Exception(message);
    }

    return AiPackageModel.fromJson(_decodeJsonObject(response.body));
  }

  Future<List<Map<String, dynamic>>> getTrips({String? status}) async {
    final queryParameters = <String, String>{};

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final uri = Uri.parse(
      '$baseUrl/trips',
    ).replace(queryParameters: queryParameters);

    final response = await _client.get(
      uri,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load trips. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final decoded = _decodeJsonObject(response.body);
    final items = decoded['items'];

    if (items is! List) {
      throw Exception('Invalid trips response: "items" is missing.');
    }

    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<Map<String, int>> getTripCounts() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/trips/counts'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load trip counts. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final decoded = _decodeJsonObject(response.body);

    int readCount(String key) {
      final value = decoded[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return {
      'ongoing': readCount('ongoing'),
      'saved': readCount('saved'),
      'past': readCount('past'),
    };
  }

  Future<Map<String, int>> getProfileStats() async {
    Map<String, int> zeroStats() {
      return {
        'saved_trips': 0,
        'favorites': 0,
        'past_trips': 0,
        'casual_trips': 0,
        'nightlife_trips': 0,
        'luxury_trips': 0,
      };
    }

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/trips/profile-stats'),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return zeroStats();
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load profile stats. Status code: '
          '${response.statusCode}. Body: ${response.body}',
        );
      }

      final decoded = _decodeJsonObject(response.body);

      int readCount(String key) {
        final value = decoded[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        return 0;
      }

      return {
        'saved_trips': readCount('saved_trips'),
        'favorites': readCount('favorites'),
        'past_trips': readCount('past_trips'),
        'casual_trips': readCount('casual_trips'),
        'nightlife_trips': readCount('nightlife_trips'),
        'luxury_trips': readCount('luxury_trips'),
      };
    } catch (error) {
      if (cleanErrorMessage(error) == 'Please log in first.') {
        return zeroStats();
      }

      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveTrip(Map<String, dynamic> tripData) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/trips'),
      headers: await _authHeaders(includeJson: true),
      body: jsonEncode(tripData),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to save trip. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    return _decodeJsonObject(response.body);
  }

  Future<Map<String, dynamic>> updateTripStatus(
    String tripId,
    String status,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/trips/$tripId/status'),
      headers: await _authHeaders(includeJson: true),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update trip status. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    return _decodeJsonObject(response.body);
  }

  Future<void> deleteTrip(String tripId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to delete trip. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/favorites'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load favorites. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final decoded = _decodeJsonObject(response.body);
    final items = decoded['items'];

    if (items is! List) {
      throw Exception('Invalid favorites response: "items" is missing.');
    }

    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> addFavorite(
    Map<String, dynamic> favoriteData,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/favorites'),
      headers: await _authHeaders(includeJson: true),
      body: jsonEncode(favoriteData),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to add favorite. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    return _decodeJsonObject(response.body);
  }

  Future<void> removeFavorite(String itemKey) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/favorites/$itemKey'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 204 && response.statusCode != 404) {
      throw Exception(
        'Failed to remove favorite. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<bool> checkFavorite(String itemKey) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/favorites/check/$itemKey'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Please log in first.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to check favorite. Status code: '
        '${response.statusCode}. Body: ${response.body}',
      );
    }

    final decoded = _decodeJsonObject(response.body);
    return decoded['is_favorite'] == true;
  }

  // ========================= AUTH =========================

  static bool isValidEmail(String email) {
    final trimmedEmail = email.trim();
    final atIndex = trimmedEmail.indexOf('@');
    if (atIndex <= 0) {
      return false;
    }

    final dotAfterAt = trimmedEmail.indexOf('.', atIndex + 1);
    return dotAfterAt > atIndex + 1 && dotAfterAt < trimmedEmail.length - 1;
  }

  static String cleanErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? unknownErrorMessage : message;
  }

  static Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw _FriendlyApiException(unknownErrorMessage);
  }

  static String _friendlyAuthError(
    http.Response response, {
    required String fallback,
    bool isLogin = false,
  }) {
    if (isLogin && response.statusCode == 401) {
      return 'Invalid email or password.';
    }

    try {
      final decoded = _decodeJsonObject(response.body);
      return _friendlyDetailMessage(
        decoded['detail'],
        statusCode: response.statusCode,
        fallback: fallback,
        isLogin: isLogin,
      );
    } catch (_) {
      return fallback;
    }
  }

  static String _friendlyDetailMessage(
    dynamic detail, {
    required int statusCode,
    required String fallback,
    required bool isLogin,
  }) {
    if (detail is List) {
      for (final item in detail) {
        if (item is Map) {
          final message = _friendlyValidationItemMessage(item);
          if (message != null) {
            return message;
          }
        }
      }
      return fallback;
    }

    if (detail is String) {
      return _friendlyStringMessage(
        detail,
        statusCode: statusCode,
        fallback: fallback,
        isLogin: isLogin,
      );
    }

    return fallback;
  }

  static String? _friendlyValidationItemMessage(Map item) {
    final loc = item['loc'];
    final locText = loc is List ? loc.join(' ').toLowerCase() : '';
    final rawMessage = (item['msg'] ?? '').toString();
    final messageText = rawMessage.toLowerCase();

    if (locText.contains('email') ||
        messageText.contains('email') ||
        messageText.contains('valid email')) {
      return 'Please enter a valid email address.';
    }

    if (locText.contains('password') ||
        messageText.contains('password') ||
        messageText.contains('at least 6') ||
        messageText.contains('min_length')) {
      return 'Password must be at least 6 characters.';
    }

    return rawMessage.trim().isEmpty ? null : rawMessage.trim();
  }

  static String _friendlyStringMessage(
    String detail, {
    required int statusCode,
    required String fallback,
    required bool isLogin,
  }) {
    final trimmedDetail = detail.trim();
    final lowerDetail = trimmedDetail.toLowerCase();

    if (isLogin &&
        (statusCode == 401 ||
            lowerDetail.contains('invalid') ||
            lowerDetail.contains('incorrect'))) {
      return 'Invalid email or password.';
    }

    if (statusCode == 409 ||
        lowerDetail.contains('already registered') ||
        lowerDetail.contains('already exists') ||
        lowerDetail.contains('duplicate')) {
      return 'This email is already registered.';
    }

    if (lowerDetail.contains('email')) {
      return 'Please enter a valid email address.';
    }

    if (lowerDetail.contains('password') ||
        lowerDetail.contains('at least 6') ||
        lowerDetail.contains('min_length')) {
      return 'Password must be at least 6 characters.';
    }

    return trimmedDetail.isEmpty ? fallback : trimmedDetail;
  }

  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeJsonObject(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('user', jsonEncode(data['user']));

        return data;
      }

      throw _FriendlyApiException(
        _friendlyAuthError(
          response,
          fallback: unknownErrorMessage,
        ),
      );
    } on _FriendlyApiException catch (error) {
      throw Exception(error.message);
    } catch (_) {
      throw Exception(networkErrorMessage);
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = _decodeJsonObject(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('user', jsonEncode(data['user']));

        return data;
      }

      throw _FriendlyApiException(
        _friendlyAuthError(
          response,
          fallback: 'Invalid email or password.',
          isLogin: true,
        ),
      );
    } on _FriendlyApiException catch (error) {
      throw Exception(error.message);
    } catch (_) {
      throw Exception(networkErrorMessage);
    }
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString('user');

    if (userString == null) {
      return null;
    }

    return jsonDecode(userString);
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      await logout();
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          await logout();
          return null;
        }

        await prefs.setString('user', jsonEncode(decoded));
        return decoded;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('access_token') != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('access_token');
    await prefs.remove('user');
  }

  static Future<Map<String, dynamic>> updateCurrentUser({
    required String firstName,
    required String lastName,
    required String email,
    String? password,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('You are not logged in');
    }

    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'avatar_url': avatarUrl,
    };

    if (password != null && password.trim().isNotEmpty) {
      body['password'] = password.trim();
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = _decodeJsonObject(response.body);
        await prefs.setString('user', jsonEncode(data));
        return data;
      }

      throw _FriendlyApiException(
        _friendlyAuthError(
          response,
          fallback: unknownErrorMessage,
        ),
      );
    } on _FriendlyApiException catch (error) {
      throw Exception(error.message);
    } catch (_) {
      throw Exception(networkErrorMessage);
    }
  }
}
