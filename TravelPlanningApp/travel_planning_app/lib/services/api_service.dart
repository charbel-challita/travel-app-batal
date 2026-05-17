import 'dart:convert';

import 'package:http/http.dart' as http;
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

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

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
    final queryParameters = <String, String>{
      'limit': limit.toString(),
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

    return items.map((item) {
      if (item is! Map) {
        throw Exception(
          'Invalid travel items response: item is not a JSON object.',
        );
      }

      return PlaceModel.fromApiJson(Map<String, dynamic>.from(item));
    }).toList(growable: false);
  }

  Future<List<TravelItemSuggestion>> getTravelItemSuggestions({
    required String query,
    int limit = 5,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return [];
    }

    final safeLimit = limit < 1 ? 5 : limit.clamp(1, 5);
    final uri = Uri.parse('$baseUrl/travel-items/suggestions').replace(
      queryParameters: <String, String>{
        'q': trimmedQuery,
        'limit': safeLimit.toString(),
      },
    );

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

    return suggestions.map((suggestion) {
      if (suggestion is! Map) {
        throw Exception(
          'Invalid travel item suggestions response: suggestion is not a JSON object.',
        );
      }

      return TravelItemSuggestion.fromJson(
        Map<String, dynamic>.from(suggestion),
      );
    }).toList(growable: false);
  }

  Future<List<PlaceModel>> searchTravelItems({
    required String query,
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

    return items.map((item) {
      if (item is! Map) {
        throw Exception(
          'Invalid travel item search response: item is not a JSON object.',
        );
      }

      return PlaceModel.fromApiJson(Map<String, dynamic>.from(item));
    }).toList(growable: false);
  }
}
