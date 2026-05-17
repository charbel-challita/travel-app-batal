import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:travel_planning_app/models/place_model.dart';

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
}
