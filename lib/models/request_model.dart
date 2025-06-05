// lib/models/request_model.dart

import 'package:intl/intl.dart';

class RequestDto {
  final int? id;
  final String?
      creatingDate; // Изменим на String, если бэкенд возвращает ISO-строку
  final String? progressDate;
  final String? closeDate;
  final String description;
  final String status;
  final int? operatorId;
  final int tenantId;
  final int? repairTeamId;
  final String? result;
  final String? photoData; // Base64 строка

  RequestDto({
    this.id,
    this.creatingDate,
    this.progressDate,
    this.closeDate,
    required this.description,
    this.status = 'CREATED', // Значение по умолчанию для новых заявок
    this.operatorId,
    required this.tenantId,
    this.repairTeamId,
    this.result,
    this.photoData,
  });

  factory RequestDto.fromJson(Map<String, dynamic> json) {
    return RequestDto(
      id: json['id'],
      creatingDate: json['creatingDate'],
      progressDate: json['progressDate'],
      closeDate: json['closeDate'],
      description: json['description'],
      status: json['status'],
      operatorId: json['operatorId'],
      tenantId: json['tenantId'],
      repairTeamId: json['repairTeamId'],
      result: json['result'],
      photoData: json['photoData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatingDate': creatingDate,
      'progressDate': progressDate,
      'closeDate': closeDate,
      'description': description,
      'status': status,
      'operatorId': operatorId,
      'tenantId': tenantId,
      'repairTeamId': repairTeamId,
      'result': result,
      'photoData': photoData,
    };
  }

  // Метод для форматирования дат
  String? formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString; // Вернуть как есть, если не удалось распарсить
    }
  }
}
