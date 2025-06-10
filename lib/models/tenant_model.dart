// lib/models/request_model.dart

import 'package:intl/intl.dart';

class TenantDto {
  final int id;
  final String? email;
  final String? fullName;
  final String? registrationAddress;
  int numRequests;

  TenantDto(
      {required this.id,
      this.email,
      this.fullName,
      this.registrationAddress,
      required this.numRequests});

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    return TenantDto(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      registrationAddress: json['registrationAddress'],
      numRequests: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'registrationAddress': registrationAddress,
    };
  }
}
