// lib/models/request_model.dart

import 'package:intl/intl.dart';

class TenantDto {
  final int? id;
  final String? email;
  final String? fullName;
  final String? registrationAddress;
  final int? numRequests;

  TenantDto({
    this.id,
    this.email,
    this.fullName,
    this.registrationAddress,
    this.numRequests
  });

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    return TenantDto(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      registrationAddress: json['registrationAddress'],
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
