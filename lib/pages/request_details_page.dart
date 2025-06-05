// lib/pages/request_details_page.dart

import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/api_service.dart';
import 'dart:convert'; // Для base64Decode

class RequestDetailsPage extends StatefulWidget {
  final RequestDto request;

  const RequestDetailsPage({super.key, required this.request});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  late RequestDto _currentRequest;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _apiService.updateRequestStatus(_currentRequest.id!, newStatus);
      setState(() {
        _currentRequest = RequestDto(
          id: _currentRequest.id,
          creatingDate: _currentRequest.creatingDate,
          progressDate: _currentRequest.progressDate,
          closeDate: _currentRequest.closeDate,
          description: _currentRequest.description,
          status: newStatus, // Обновляем статус локально
          operatorId: _currentRequest.operatorId,
          tenantId: _currentRequest.tenantId,
          repairTeamId: _currentRequest.repairTeamId,
          result: _currentRequest.result,
          photoData: _currentRequest.photoData,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Статус обновлен!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Ошибка обновления статуса: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _addComment(String comment) async {
    try {
      await _apiService.addRepairComment(_currentRequest.id!, comment);
      setState(() {
        // Если бэкенд возвращает обновленный запрос с комментарием,
        // можно было бы обновить _currentRequest с него.
        // Для простоты, пока просто показываем сообщение.
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Комментарий добавлен!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Ошибка добавления комментария: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ApiService.userRole;

    return Scaffold(
      appBar: AppBar(title: const Text('Детали заявки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Заявка #${_currentRequest.id}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Описание: ${_currentRequest.description}'),
            Text('Статус: ${_currentRequest.status}'),
            if (_currentRequest.creatingDate != null)
              Text(
                  'Создана: ${_currentRequest.formatDateTime(_currentRequest.creatingDate)}'),
            if (_currentRequest.progressDate != null)
              Text(
                  'В работе: ${_currentRequest.formatDateTime(_currentRequest.progressDate)}'),
            if (_currentRequest.closeDate != null)
              Text(
                  'Закрыта: ${_currentRequest.formatDateTime(_currentRequest.closeDate)}'),
            if (_currentRequest.operatorId != null)
              Text('Оператор ID: ${_currentRequest.operatorId}'),
            Text('Арендатор ID: ${_currentRequest.tenantId}'),
            if (_currentRequest.repairTeamId != null)
              Text('Бригада ID: ${_currentRequest.repairTeamId}'),
            if (_currentRequest.result != null &&
                _currentRequest.result!.isNotEmpty)
              Text('Результат ремонта: ${_currentRequest.result}'),

            const SizedBox(height: 20),

            if (_currentRequest.photoData != null &&
                _currentRequest.photoData!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Фото:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Отображение Base64 изображения
                  Image.memory(
                    base64Decode(_currentRequest.photoData!),
                    fit: BoxFit.cover,
                    width: 200, // или любой другой размер
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Не удалось загрузить фото');
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Логика для кнопок в зависимости от роли
            if (userRole == 'OPERATOR') ...[
              const Divider(),
              const Text('Действия оператора:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () => _showStatusChangeDialog(context),
                child: const Text('Изменить статус'),
              ),
            ],
            if (userRole == 'REPAIR_TEAM') ...[
              const Divider(),
              const Text('Действия бригады:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () => _showCommentDialog(context),
                child: const Text('Добавить комментарий о ремонте'),
              ),
              // Можно добавить кнопку для смены статуса на "Завершено"
              ElevatedButton(
                onPressed: () =>
                    _updateStatus('COMPLETED'), // Или другой статус
                child: const Text('Завершить ремонт'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusChangeDialog(BuildContext context) {
    String? selectedStatus;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Изменить статус заявки'),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            hint: const Text('Выберите новый статус'),
            items:
                <String>['ASSIGNED', 'IN_PROGRESS', 'CLOSED'] // Пример статусов
                    .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              selectedStatus = newValue;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Сохранить'),
              onPressed: () {
                if (selectedStatus != null) {
                  _updateStatus(selectedStatus!);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showCommentDialog(BuildContext context) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Добавить комментарий о ремонте'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(labelText: 'Комментарий'),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Добавить'),
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  _addComment(commentController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
