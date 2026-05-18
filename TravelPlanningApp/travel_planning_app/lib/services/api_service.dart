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
    int limit = 20,
  }) async {
    final safeLimit = limit.clamp(1, 50);

    final queryParameters = <String, String>{
      'limit': safeLimit.toString(),
    };

    if (mode != null && mode.isNotEmpty) {
      queryParameters['mode'] = mode;
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
