// lib/models/auth_models.dart

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponse {
  final String token;
  final String role; // Предполагаем, что бэкенд возвращает роль пользователя
  final int id; // ID пользователя (tenantId, operatorId и т.д.)

  LoginResponse({required this.token, required this.role, required this.id});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      role: json['role'],
      id: json['id'],
    );
  }
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String registrationAddress; // Для Tenant
  final String passportNumber;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.registrationAddress,
    required this.passportNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'registrationAddress': registrationAddress,
      'passportNumber': passportNumber,
    };
  }
}
