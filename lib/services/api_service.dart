// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../models/request_model.dart';

class ApiService {
  // !!! Замените на ваш фактический базовый URL бэкенда !!!
  static const String _baseUrl = 'http://localhost:9090/api'; // Например

  static String? _token;
  static int? _userId;
  static String? _userRole;

  static String? get token => _token;
  static int? get userId => _userId;
  static String? get userRole => _userRole;

  // Инициализация сервиса (загрузка токена при старте приложения)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getInt('userId');
    _userRole = prefs.getString('userRole');
  }

  static Future<void> _saveAuthData(
      String token, String role, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userRole', role);
    await prefs.setInt('userId', userId);
    _token = token;
    _userRole = role;
    _userId = userId;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userRole');
    await prefs.remove('userId');
    _token = null;
    _userRole = null;
    _userId = null;
  }

  // --- Методы аутентификации ---

  Future<LoginResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(LoginRequest(email: email, password: password).toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final loginResponse = LoginResponse.fromJson(data);
      await ApiService._saveAuthData(
          loginResponse.token, loginResponse.role, loginResponse.userId);
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

  Future<List<RequestDto>> getRequests() async {
    if (_token == null) throw Exception('Not authenticated');

    String url = '$_baseUrl/requests'; // По умолчанию для оператора

    // Логика получения заявок в зависимости от роли:
    if (_userRole == 'TENANT' && _userId != null) {
      url = '$_baseUrl/requests/by-tenant/$_userId';
    } else if (_userRole == 'REPAIR_TEAM' && _userId != null) {
      // Здесь может быть нюанс: если RepairTeamId не совпадает с userId напрямую.
      // Вам может понадобиться дополнительный эндпоинт на бэкенде,
      // который возвращает RepairTeamId по userId, или чтобы логин возвращал RepairTeamId.
      // Пока что, для примера, будем использовать userId как repairTeamId.
      url = '$_baseUrl/requests/by-repair-team/$_userId';
    }
    // Для OPERATOR'а '$_baseUrl/requests' должен возвращать новые/все заявки.

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RequestDto.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load requests: ${response.body}');
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
      Uri.parse(
          '$_baseUrl/requests/$requestId/status'), // Гипотетический эндпоинт
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'status': newStatus}), // Или другой формат запроса
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update request status: ${response.body}');
    }
  }

  Future<void> addRepairComment(int requestId, String comment) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse(
          '$_baseUrl/requests/$requestId/comment'), // Гипотетический эндпоинт
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'comment': comment}), // Или другой формат запроса
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add repair comment: ${response.body}');
    }
  }
}
