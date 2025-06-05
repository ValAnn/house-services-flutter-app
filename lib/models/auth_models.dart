// lib/models/auth_models.dart

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String token;
  final String role; // Предполагаем, что бэкенд возвращает роль пользователя
  final int userId; // ID пользователя (tenantId, operatorId и т.д.)

  LoginResponse(
      {required this.token, required this.role, required this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      role: json['role'],
      userId: json['userId'],
    );
  }
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String registrationAddress; // Для Tenant

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.registrationAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'registrationAddress': registrationAddress,
    };
  }
}
