// lib/services/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:house_services_flutter/models/repair_team_model.dart';
import 'package:house_services_flutter/models/tenant_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../models/request_model.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:9090/api';

  static String? _token;
  static int? _id;
  static String? _userRole;

  static String? get token => _token;
  static int? get id => _id;
  static String? get userRole => _userRole;

  // Инициализация сервиса (загрузка токена при старте приложения)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _id = prefs.getInt('id');
    _userRole = prefs.getString('userRole');
  }

  static Future<void> _saveAuthData(String token, String role, int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userRole', role);
    await prefs.setInt('id', id);
    _token = token;
    _userRole = role;
    _id = id;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userRole');
    await prefs.remove('id');
    _token = null;
    _userRole = null;
    _id = null;
  }

  // --- Методы аутентификации ---

  Future<LoginResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          LoginRequest(username: username, password: password).toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final loginResponse = LoginResponse.fromJson(data);
      await ApiService._saveAuthData(
          loginResponse.token, loginResponse.role, loginResponse.id);
      return loginResponse;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<void> registerTenant(RegisterRequest request) async {
    final response = await http.post(
      Uri.parse(
          '$_baseUrl/auth/register/tenant'), // Или другой путь для регистрации
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // --- Методы для работы с заявками ---

  Future<List<RequestDto>> getRequests(
      {String? status, String? description}) async {
    if (_token == null || _id == null || _userRole == null) {
      throw Exception('User not authenticated.');
    }

    Uri url;
    Map<String, String> queryParams = {};

    // Логика получения заявок в зависимости от роли:
    if (_userRole == 'ROLE_TENANT') {
      url = Uri.parse('$_baseUrl/requests/my-requests');
    } else if (_userRole == 'ROLE_OPERATOR') {
      url = Uri.parse('$_baseUrl/requests');
    } else if (_userRole == 'ROLE_REPAIR_TEAM') {
      url = Uri.parse('$_baseUrl/requests/repair-team-requests');
    } else {
      throw Exception('Unknown user role: $_userRole');
    }

    if (status != null && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (description != null && description.isNotEmpty) {
      queryParams['search'] = description;
    }

    final finalUrl = url.replace(queryParameters: queryParams);

    if (kDebugMode) {
      print('Запрос на URL: $finalUrl');
    }

    final response = await http.get(
      finalUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => RequestDto.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'Failed to load requests: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}');
    }
  }

  Future<List<TenantDto>> getTenants(
      {String? status, String? description}) async {
    if (_token == null || _id == null || _userRole == null) {
      throw Exception('User not authenticated.');
    }

    Uri url;
    Map<String, String> queryParams = {};

    // Логика получения заявок в зависимости от роли:

    url = Uri.parse('$_baseUrl/tenants/with-search');

    if (description != null && description.isNotEmpty) {
      queryParams['search'] = description;
    }

    final finalUrl = url.replace(queryParameters: queryParams);

    if (kDebugMode) {
      print('Запрос на URL: $finalUrl');
    }

    final response = await http.get(
      finalUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(utf8.decode(response.bodyBytes));
      List<TenantDto> tenants =
          jsonList.map((json) => TenantDto.fromJson(json)).toList();

      for (TenantDto tenant in tenants) {
        try {
          final List<RequestDto> userRequests =
              await getUserRequests(tenant.id);
          tenant.numRequests = userRequests.length;
        } catch (e) {
          if (kDebugMode) {
            print('Ошибка при получении заявок для жителя ${tenant.id}: $e');
          }
          tenant.numRequests = 0; // В случае ошибки устанавливаем 0 заявок
        }
      }

      return tenants;
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'Failed to load requests: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}');
    }
  }

  Future<List<RequestDto>> getUserRequests(int userId) async {
    if (_token == null) {
      throw Exception('User not authenticated.');
    }

    final Uri finalUrl = Uri.parse(
        '$_baseUrl/requests/my-requests/$userId'); // Предполагаемый эндпоинт

    if (kDebugMode) {
      print('Запрос на URL для заявок пользователя: $finalUrl');
    }

    final response = await http.get(
      finalUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(utf8.decode(response.bodyBytes));
      return List<RequestDto>.from(
          jsonList.map((json) => RequestDto.fromJson(json)));
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'Failed to load user requests: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}');
    }
  }

  Future<void> createRequest(RequestDto request) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create request: ${response.body}');
    }
  }

  Future<void> updateRequestStatus(int requestId, String newStatus) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('$_baseUrl/requests/$requestId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update request status: ${response.body}');
    }
  }

  Future<void> addRepairComment(int requestId, RequestDto request) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$_baseUrl/requests/$requestId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(request),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add repair comment: ${response.body}');
    }
  }

  Future<List<RepairTeamDto>> getRepairTeams() async {
    if (_token == null || _userRole == null) {
      throw Exception('User not authenticated.');
    }

    final url =
        Uri.parse('$_baseUrl/repair-teams'); // Adjust this URL if different
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => RepairTeamDto.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'Failed to load repair teams: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}');
    }
  }

  Future<void> assignRequestToTeam(int requestId, int repairTeamId) async {
    if (_token == null) {
      throw Exception('User not authenticated.');
    }

    // Adjust endpoint based on your backend. Example: PATCH /requests/{id}/assign-team
    final url =
        Uri.parse('$_baseUrl/requests/$requestId/assign-team/$repairTeamId');
    final response = await http.patch(
      // or PUT, POST depending on your API
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'teamId': repairTeamId}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'Failed to assign request to team: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}');
    }
  }

  Future<void> assignRequestToOperator(int requestId, int operatorId) async {
    if (_token == null) {
      throw Exception('User not authenticated.');
    }

    // Adjust endpoint based on your backend. Example: PATCH /requests/{id}/assign-team
    final url =
        Uri.parse('$_baseUrl/requests/$requestId/assign-operator/$operatorId');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'Failed to assign request to operator: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}');
    }
  }

  Future<Map<String, int>> getRequestStatistics(
      DateTime startDate, DateTime endDate) async {
    if (_token == null) {
      throw Exception('Пользователь не авторизован');
    }

    final String formattedStartDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(startDate.toUtc());
    final String formattedEndDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(endDate.toUtc());

    final url = Uri.parse(
        '$_baseUrl/requests/statistics?startDate=$formattedStartDate&endDate=$formattedEndDate');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return data.map((key, value) => MapEntry(key, value as int));
      } else if (response.statusCode == 403) {
        throw Exception(
            'Доступ запрещен. У вас нет прав для просмотра статистики.');
      } else {
        throw Exception(
            'Ошибка при получении статистики: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Ошибка получения статистики: $e');
      rethrow; // Перебросить исключение для обработки на UI
    }
  }
}
